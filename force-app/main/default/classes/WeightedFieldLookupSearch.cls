/**
* Author      : Ravi Bheemreddy  
* Description : A general-purpose ranked search that works for any object. 
				Can configure it by telling it which two fields to search against and how much weight to give each one.
* Test        : WeightedFieldLookupSearchTest
* JIRA 		  : BRME-6660 
*/
public with sharing class WeightedFieldLookupSearch implements IGenericLookupSearch {

    private static final Integer DEFAULT_MATCH_EXACT = 50;
    private static final Integer DEFAULT_MATCH_STARTS_WITH = 40;
    private static final Integer DEFAULT_MATCH_CONTAINS = 20;

    private static final Integer RECENCY_TODAY = 15;
    private static final Integer RECENCY_WEEK = 10;
    private static final Integer RECENCY_MONTH = 5;

    public List<GenericLookupController.LookupRecord> search(GenericLookupController.SearchRequest req) {
        if (String.isBlank(req.searchTerm) || String.isBlank(req.searchConfig)) {
            return new List<GenericLookupController.LookupRecord>();
        }

        SearchConfig config = (SearchConfig) JSON.deserialize(req.searchConfig, SearchConfig.class);

        if (String.isBlank(config.primaryField)) {
            return new List<GenericLookupController.LookupRecord>();
        }

        Integer matchExact = config.matchWeights != null && config.matchWeights.exact != null ? config.matchWeights.exact : DEFAULT_MATCH_EXACT;
        Integer matchStartsWith = config.matchWeights != null && config.matchWeights.startsWith != null ? config.matchWeights.startsWith : DEFAULT_MATCH_STARTS_WITH;
        Integer matchContains = config.matchWeights != null && config.matchWeights.contains != null ? config.matchWeights.contains : DEFAULT_MATCH_CONTAINS;

        List<String> tokens = req.searchTerm.trim().split('\\s+');
        Integer maxResults = req.maxResults != null ? req.maxResults : 10;

        Set<String> fieldsToQuery = new Set<String>{ 'Id', 'Name', config.primaryField, 'LastViewedDate' };
        if (String.isNotBlank(config.convertedField)) {
            fieldsToQuery.add(config.convertedField);
        }
        if (req.displayFields != null) {
            fieldsToQuery.addAll(req.displayFields);
        }

        String pass1WhereClause = buildPass1WhereClause(tokens, config, req.filterClause);
        String pass1Query = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ') +
                       ' FROM ' + req.objectApiName +
                           ' WHERE ' + pass1WhereClause +
                           ' LIMIT ' + maxResults;
        List<SObject> candidates = Database.query(pass1Query);

        if (candidates.isEmpty()) {
            String pass2WhereClause = buildPass2WhereClause(tokens, config, req.filterClause);
            String pass2Query = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ') +
                               ' FROM ' + req.objectApiName +
                               ' WHERE ' + pass2WhereClause +
                               ' LIMIT ' + maxResults;
            candidates = Database.query(pass2Query);
        }

        List<ScoredRecord> scored = new List<ScoredRecord>();
        Date today = Date.today();

        for (SObject record : candidates) {
            Integer score = scoreRecord(record, tokens, config, matchExact, matchStartsWith, matchContains, today);
            if (score > 0) {
                scored.add(new ScoredRecord(record, score));
            }
        }

        scored.sort();

        List<GenericLookupController.LookupRecord> results = new List<GenericLookupController.LookupRecord>();
        for (Integer i = 0; i < Math.min(scored.size(), maxResults); i++) {
            results.add(GenericLookupService.mapToLookupRecord(scored[i].record, req.displayFields));
        }
        return results;
    }

    private String buildPass1WhereClause(List<String> tokens, SearchConfig config, String filterClause) {
        List<String> tokenConditions = new List<String>();
        for (String token : tokens) {
            String t = String.escapeSingleQuotes(token);
            List<String> fieldConditions = new List<String>();
            fieldConditions.add(config.primaryField + ' = \'' + t + '\'');
            if (String.isNotBlank(config.convertedField)) {
                fieldConditions.add(config.convertedField + ' = \'' + t + '\'');
            }
            tokenConditions.add('(' + String.join(fieldConditions, ' OR ') + ')');
        }
        String fullTerm = String.escapeSingleQuotes(String.join(tokens, ' '));
        String fullTermNoSpaces = String.escapeSingleQuotes(String.join(tokens, ''));
        List<String> fullTermConditions = new List<String>();
        fullTermConditions.add(config.primaryField + ' = \'' + fullTerm + '\'');
        if (String.isNotBlank(config.convertedField)) {
            fullTermConditions.add(config.convertedField + ' = \'' + fullTerm + '\'');
            fullTermConditions.add(config.convertedField + ' = \'' + fullTermNoSpaces + '\'');
        }
        tokenConditions.add('(' + String.join(fullTermConditions, ' OR ') + ')');
        String clause = '(' + String.join(tokenConditions, ' OR ') + ')';
        if (String.isNotBlank(filterClause)) {
            clause += ' AND (' + filterClause + ')';
        }
        return clause;
    }

    private String buildPass2WhereClause(List<String> tokens, SearchConfig config, String filterClause) {
        List<String> tokenConditions = new List<String>();
        for (String token : tokens) {
            String t = String.escapeSingleQuotes(token);
            List<String> fieldConditions = new List<String>();
            fieldConditions.add(config.primaryField + ' LIKE \'%' + t + '%\'');
            if (String.isNotBlank(config.convertedField)) {
                fieldConditions.add(config.convertedField + ' LIKE \'%' + t + '%\'');
            }
            tokenConditions.add('(' + String.join(fieldConditions, ' OR ') + ')');
        }
        String clause = '(' + String.join(tokenConditions, ' AND ') + ')';
        if (String.isNotBlank(filterClause)) {
            clause += ' AND (' + filterClause + ')';
        }
        return clause;
    }

    private Integer scoreRecord(SObject record, List<String> tokens, SearchConfig config,
                                Integer matchExact, Integer matchStartsWith, Integer matchContains, Date today) {
        Integer totalScore = 0;

        for (String token : tokens) {
            String t = token.toLowerCase();

            Integer primaryScore = matchScore((String) record.get(config.primaryField), t, config.primaryWeight, matchExact, matchStartsWith, matchContains);
            Integer convertedScore = String.isNotBlank(config.convertedField)
                ? matchScore((String) record.get(config.convertedField), t, config.convertedWeight, matchExact, matchStartsWith, matchContains)
                : 0;

            Integer tokenScore = Math.max(primaryScore, convertedScore);

            if (tokenScore == 0) {
                return 0;
            }

            totalScore += tokenScore;
        }

        totalScore += recencyScore((DateTime) record.get('LastViewedDate'), today);

        return totalScore;
    }

    private Integer matchScore(String fieldValue, String token, Integer fieldWeight,
                               Integer matchExact, Integer matchStartsWith, Integer matchContains) {
        if (String.isBlank(fieldValue)) {
            return 0;
        }
        String fv = fieldValue.toLowerCase();
        if (fv == token) {
            return fieldWeight + matchExact;
        } else if (fv.startsWith(token)) {
            return fieldWeight + matchStartsWith;
        } else if (fv.contains(token)) {
            return fieldWeight + matchContains;
        }
        return 0;
    }

    private Integer recencyScore(DateTime lastViewed, Date today) {
        if (lastViewed == null) {
            return 0;
        }
        Date viewedDate = lastViewed.date();
        if (viewedDate == today) {
            return RECENCY_TODAY;
        } else if (viewedDate >= today.addDays(-7)) {
            return RECENCY_WEEK;
        } else if (viewedDate >= today.addDays(-30)) {
            return RECENCY_MONTH;
        }
        return 0;
    }

    private class ScoredRecord implements Comparable {
        public SObject record;
        public Integer score;

        public ScoredRecord(SObject r, Integer s) {
            this.record = r;
            this.score = s;
        }

        public Integer compareTo(Object other) {
            ScoredRecord o = (ScoredRecord) other;
            return o.score - this.score;
        }
    }

    public class SearchConfig {
        public String primaryField;
        public Integer primaryWeight;
        public String convertedField;
        public Integer convertedWeight;
        public MatchWeights matchWeights;
    }

    public class MatchWeights {
        public Integer exact;
        public Integer startsWith;
        public Integer contains;
    }
}