/**
* Author      : Ravi Bheemreddy  
* Description : Searches for contacts and ranks results by relevance, taking into account first name, last name, preferred name, and converted name fields. 
				Also handles contacts marked as restricted by searching their private name fields instead.
* Test        : ContactLookupSearchTest
* JIRA 		  : BRME-6660 
*/
public with sharing class ContactLookupSearch implements IGenericLookupSearch {

    private static final Integer WEIGHT_LAST_NAME = 100;
    private static final Integer WEIGHT_FIRST_NAME = 100;
    private static final Integer WEIGHT_PREFERRED_FIRST_NAME = 95;
    private static final Integer WEIGHT_CONVERTED_NAME = 50;

    private static final Integer MATCH_EXACT = 50;
    private static final Integer MATCH_STARTS_WITH = 40;
    private static final Integer MATCH_MULTI_TOKEN = 30;
    private static final Integer MATCH_CONTAINS = 20;

    private static final Integer RECENCY_TODAY = 15;
    private static final Integer RECENCY_WEEK = 10;
    private static final Integer RECENCY_MONTH = 5;

    public List<GenericLookupController.LookupRecord> search(GenericLookupController.SearchRequest req) {
        if (String.isBlank(req.searchTerm)) {
            return new List<GenericLookupController.LookupRecord>();
        }

        List<String> tokens = req.searchTerm.trim().split('\\s+');
        Application_Properties__mdt config = Application_Properties__mdt.getInstance('Contact_Lookup_Search_Query_Limit');
        Integer maxResults = (config != null && config.Value__c != null) ? Integer.valueOf(config.Value__c) : 1000;

        Set<String> fieldsToQuery = new Set<String>{
            'Id', 'Name', 'FirstName', 'LastName',
            'Preferred_First_Name__c', 'Converted_FirstName__c', 'Converted_LastName__c',
            'Restricted__c', 'RestrictedFirstName__c', 'RestrictedLastName__c',
            'LastViewedDate',
            'Touchpoint_sum__c',
            'Preferred_FirstName_LastName__c'
        };
        if (req.displayFields != null) {
            fieldsToQuery.addAll(req.displayFields);
        }

        String pass1WhereClause = buildPass1WhereClause(tokens, req.filterClause);
        String pass1Query = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ') +
                           ' FROM Contact WHERE ' + pass1WhereClause +
                           ' ORDER BY LastName ASC NULLS LAST, Preferred_First_Name__c ASC NULLS LAST, Converted_LastName__c ASC NULLS LAST, FirstName ASC NULLS LAST, Converted_FirstName__c ASC NULLS LAST' +
                           ' LIMIT ' + maxResults;
        List<Contact> candidates = (List<Contact>) Database.query(pass1Query);

        if (candidates.isEmpty()) {
            Set<Id> pass1Ids = new Map<Id, Contact>(candidates).keySet();
            String pass2WhereClause = buildPass2WhereClause(tokens, req.filterClause, pass1Ids);
            String pass2Query = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ') +
                               ' FROM Contact WHERE ' + pass2WhereClause +
                               ' ORDER BY LastName ASC NULLS LAST, Preferred_First_Name__c ASC NULLS LAST, Converted_LastName__c ASC NULLS LAST, FirstName ASC NULLS LAST, Converted_FirstName__c ASC NULLS LAST' +
                               ' LIMIT ' + (maxResults - candidates.size());
            List<Contact> pass2Results = (List<Contact>) Database.query(pass2Query);
            candidates.addAll(pass2Results);
        }
        
        List<ScoredContact> scored = new List<ScoredContact>();
        Date today = Date.today();

        for (Contact c : candidates) {
            Integer score = scoreContact(c, tokens, today);
            if (score > 0) {
                scored.add(new ScoredContact(c, score));
            }
        }

        scored.sort();

        List<GenericLookupController.LookupRecord> results = new List<GenericLookupController.LookupRecord>();
        for (Integer i = 0; i < Math.min(scored.size(), maxResults); i++) {
            results.add(GenericLookupService.mapToLookupRecord(scored[i].contact, req.displayFields));
        }
        return results;
    }

    private String buildPass1WhereClause(List<String> tokens, String filterClause) {
        List<String> tokenConditions = new List<String>();
        for (String token : tokens) {
            String t = String.escapeSingleQuotes(token);
            List<String> fieldConditions = new List<String>();
            fieldConditions.add('(Restricted__c = false AND (FirstName = \'' + t + '\' OR LastName = \'' + t + '\'))');
            fieldConditions.add('(Restricted__c = true AND (RestrictedFirstName__c = \'' + t + '\' OR RestrictedLastName__c = \'' + t + '\'))');
            fieldConditions.add('Preferred_First_Name__c = \'' + t + '\'');
            fieldConditions.add('Converted_FirstName__c = \'' + t + '\'');
            fieldConditions.add('Converted_LastName__c = \'' + t + '\'');
            tokenConditions.add('(' + String.join(fieldConditions, ' OR ') + ')');
        }
        String fullName = String.escapeSingleQuotes(String.join(tokens, ' '));
        String fullNameNoSpaces = String.escapeSingleQuotes(String.join(tokens, ''));
        tokenConditions.add('Preferred_FirstName_LastName__c = \'' + fullName + '\'');
        tokenConditions.add('Converted_FirstName__c = \'' + fullNameNoSpaces + '\'');
        tokenConditions.add('Converted_LastName__c = \'' + fullNameNoSpaces + '\'');
        String clause = '(' + String.join(tokenConditions, ' OR ') + ')';
        if (String.isNotBlank(filterClause)) {
            clause += ' AND (' + filterClause + ')';
        }
        return clause;
    }

    private String buildPass2WhereClause(List<String> tokens, String filterClause, Set<Id> excludeIds) {
        List<String> tokenConditions = new List<String>();
        for (String token : tokens) {
            String t = String.escapeSingleQuotes(token);
            List<String> fieldConditions = new List<String>();
            fieldConditions.add('(Restricted__c = false AND (FirstName LIKE \'%' + t + '%\' OR LastName LIKE \'%' + t + '%\'))');
            fieldConditions.add('(Restricted__c = true AND (RestrictedFirstName__c LIKE \'%' + t + '%\' OR RestrictedLastName__c LIKE \'%' + t + '%\'))');
            fieldConditions.add('Preferred_First_Name__c LIKE \'%' + t + '%\'');
            fieldConditions.add('Converted_FirstName__c LIKE \'%' + t + '%\'');
            fieldConditions.add('Converted_LastName__c LIKE \'%' + t + '%\'');
            fieldConditions.add('Preferred_FirstName_LastName__c LIKE \'%' + t + '%\'');
            tokenConditions.add('(' + String.join(fieldConditions, ' OR ') + ')');
        }
        String clause = '(' + String.join(tokenConditions, ' OR ') + ')';
        if (!excludeIds.isEmpty()) {
            List<String> idStrings = new List<String>();
            for (Id i : excludeIds) { idStrings.add('\'' + i + '\''); }
            clause += ' AND Id NOT IN (' + String.join(idStrings, ',') + ')';
        }
        if (String.isNotBlank(filterClause)) {
            clause += ' AND (' + filterClause + ')';
        }
        return clause;
    }

    private Integer scoreContact(Contact c, List<String> tokens, Date today) {
        String fn = c.Restricted__c ? c.RestrictedFirstName__c : c.FirstName;
        String ln = c.Restricted__c ? c.RestrictedLastName__c : c.LastName;
        String pn = c.Preferred_First_Name__c;
        String cfn = c.Converted_FirstName__c;
        String cln = c.Converted_LastName__c;

        Integer totalScore = 0;
        Boolean allTokensMatched = tokens.size() > 1;

        for (String token : tokens) {
            String t = token.toLowerCase();
            Integer tokenScore = 0;
            Boolean tokenMatched = false;

            Integer fnScore = matchScore(fn, t, WEIGHT_FIRST_NAME);
            Integer lnScore = matchScore(ln, t, WEIGHT_LAST_NAME);
            Integer pnScore = matchScore(pn, t, WEIGHT_PREFERRED_FIRST_NAME);
            Integer cfnScore = matchScore(cfn, t, WEIGHT_CONVERTED_NAME);
            Integer clnScore = matchScore(cln, t, WEIGHT_CONVERTED_NAME);

            tokenScore = Math.max(Math.max(Math.max(Math.max(fnScore, lnScore), pnScore), cfnScore), clnScore);

            if (tokenScore > 0) {
                tokenMatched = true;
            } else {
                allTokensMatched = false;
            }

            totalScore += tokenScore;
        }

        if (totalScore == 0) {
            return 0;
        }

        if (allTokensMatched && tokens.size() > 1) {
            totalScore += MATCH_MULTI_TOKEN;
        }

        totalScore += recencyScore(c.LastViewedDate, today);
        if (c.Touchpoint_sum__c != null) {
            totalScore += c.Touchpoint_sum__c.intValue();
        }

        return totalScore;
    }

    private Integer matchScore(String fieldValue, String token, Integer fieldWeight) {
        if (String.isBlank(fieldValue)) {
            return 0;
        }
        String fv = fieldValue.toLowerCase();
        if (fv == token) {
            return (fieldWeight + MATCH_EXACT) * 1000000;
        } else if (fv.startsWith(token)) {
            return (fieldWeight + MATCH_STARTS_WITH) * 100000;
        } else if (fv.contains(token)) {
            return (fieldWeight + MATCH_CONTAINS) * 100000;
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

    private class ScoredContact implements Comparable {
        public Contact contact;
        public Integer score;

        public ScoredContact(Contact c, Integer s) {
            this.contact = c;
            this.score = s;
        }

        public Integer compareTo(Object other) {
            ScoredContact o = (ScoredContact) other;
            return o.score - this.score;
        }
    }
}