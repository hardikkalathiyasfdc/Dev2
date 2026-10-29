/**
* Author      : Ravi Bheemreddy  
* Description : Searches for organizations and ranks results by relevance, taking into account the org name, converted name, and AKA fields. 
				Also handles organizations marked as restricted by searching their private name field instead
* Test        : OrganizationLookupSearchTest
* JIRA 		  : BRME-6660 
*/
public with sharing class OrganizationLookupSearch implements IGenericLookupSearch {

    private static final Integer WEIGHT_ORG_NAME = 100;
    private static final Integer WEIGHT_CONVERTED_NAME = 80;
    private static final Integer AKA_BONUS = 25;

    private static final Integer MATCH_EXACT = 50;
    private static final Integer MATCH_STARTS_WITH = 40;
    private static final Integer MATCH_CONTAINS = 20;

    private static final Integer RECENCY_TODAY = 15;
    private static final Integer RECENCY_WEEK = 10;
    private static final Integer RECENCY_MONTH = 5;

    public List<GenericLookupController.LookupRecord> search(GenericLookupController.SearchRequest req) {
        if (String.isBlank(req.searchTerm)) {
            return new List<GenericLookupController.LookupRecord>();
        }

        List<String> tokens = req.searchTerm.trim().split('\\s+');
        Integer maxResults = req.maxResults != null ? req.maxResults : 10;

        Set<String> fieldsToQuery = new Set<String>{
            'Id', 'Name', 'Restricted__c', 'Restricted_Org_Name__c',
            'Converted_Org_Name__c', 'AKA__c', 'Converted_AKA__c',
            'LastViewedDate', 'Touchpoint_Summary__c'
        };
        if (req.displayFields != null) {
            fieldsToQuery.addAll(req.displayFields);
        }

        String pass1WhereClause = buildPass1WhereClause(tokens, req.filterClause);
        String pass1Query = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ') +
                           ' FROM Account WHERE ' + pass1WhereClause +
                           ' LIMIT ' + maxResults;
        List<Account> organizations = (List<Account>) Database.query(pass1Query);

        if (organizations.isEmpty()) {
            String pass2WhereClause = buildPass2WhereClause(tokens, req.filterClause);
            String pass2Query = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ') +
                               ' FROM Account WHERE ' + pass2WhereClause +
                               ' LIMIT ' + maxResults;
            organizations = (List<Account>) Database.query(pass2Query);
        }

        List<ScoredOrganization> scored = new List<ScoredOrganization>();
        Date today = Date.today();

        for (Account a : organizations) {
            Integer score = scoreOrganization(a, tokens, today);
            if (score > 0) {
                scored.add(new ScoredOrganization(a, score));
            }
        }

        scored.sort();

        List<GenericLookupController.LookupRecord> results = new List<GenericLookupController.LookupRecord>();
        for (Integer i = 0; i < Math.min(scored.size(), maxResults); i++) {
            results.add(GenericLookupService.mapToLookupRecord(scored[i].organization, req.displayFields));
        }
        return results;
    }

    private String buildPass1WhereClause(List<String> tokens, String filterClause) {
        List<String> tokenConditions = new List<String>();
        for (String token : tokens) {
            String t = String.escapeSingleQuotes(token);
            List<String> fieldConditions = new List<String>();
            fieldConditions.add('(Restricted__c = false AND Name = \'' + t + '\')');
            fieldConditions.add('(Restricted__c = true AND Restricted_Org_Name__c = \'' + t + '\')');
            fieldConditions.add('Converted_Org_Name__c = \'' + t + '\'');
            tokenConditions.add('(' + String.join(fieldConditions, ' OR ') + ')');
        }
        String fullTerm = String.escapeSingleQuotes(String.join(tokens, ' '));
        String fullTermNoSpaces = String.escapeSingleQuotes(String.join(tokens, ''));
        List<String> fullTermConditions = new List<String>();
        fullTermConditions.add('(Restricted__c = false AND Name = \'' + fullTerm + '\')');
        fullTermConditions.add('(Restricted__c = true AND Restricted_Org_Name__c = \'' + fullTerm + '\')');
        fullTermConditions.add('Converted_Org_Name__c = \'' + fullTerm + '\'');
        fullTermConditions.add('Converted_Org_Name__c = \'' + fullTermNoSpaces + '\'');
        tokenConditions.add('(' + String.join(fullTermConditions, ' OR ') + ')');
        String clause = '(' + String.join(tokenConditions, ' OR ') + ')';
        if (String.isNotBlank(filterClause)) {
            clause += ' AND (' + filterClause + ')';
        }
        return clause;
    }

    private String buildPass2WhereClause(List<String> tokens, String filterClause) {
        List<String> tokenConditions = new List<String>();
        for (String token : tokens) {
            String t = String.escapeSingleQuotes(token);
            List<String> fieldConditions = new List<String>();
            fieldConditions.add('(Restricted__c = false AND Name LIKE \'%' + t + '%\')');
            fieldConditions.add('(Restricted__c = true AND Restricted_Org_Name__c LIKE \'%' + t + '%\')');
            fieldConditions.add('Converted_Org_Name__c LIKE \'%' + t + '%\'');
            fieldConditions.add('AKA__c LIKE \'%' + t + '%\'');
            fieldConditions.add('Converted_AKA__c LIKE \'%' + t + '%\'');
            tokenConditions.add('(' + String.join(fieldConditions, ' OR ') + ')');
        }
        String clause = '(' + String.join(tokenConditions, ' AND ') + ')';
        if (String.isNotBlank(filterClause)) {
            clause += ' AND (' + filterClause + ')';
        }
        return clause;
    }

    private Integer scoreOrganization(Account a, List<String> tokens, Date today) {
        String orgName = a.Restricted__c ? a.Restricted_Org_Name__c : a.Name;
        String convertedName = a.Converted_Org_Name__c;
        String aka = a.AKA__c;
        String convertedAka = a.Converted_AKA__c;

        Integer totalScore = 0;

        for (String token : tokens) {
            String t = token.toLowerCase();

            Integer orgScore = matchScore(orgName, t, WEIGHT_ORG_NAME);
            Integer convertedScore = matchScore(convertedName, t, WEIGHT_CONVERTED_NAME);
            Integer tokenScore = Math.max(orgScore, convertedScore);

            if (tokenScore == 0) {
                return 0;
            }

            totalScore += tokenScore;
        }

        if (akaMatches(aka, convertedAka, tokens)) {
            totalScore += AKA_BONUS;
        }

        totalScore += recencyScore(a.LastViewedDate, today);
        totalScore *= 100000;
        if (a.Touchpoint_Summary__c != null) {
            totalScore += a.Touchpoint_Summary__c.intValue();
        }

        return totalScore;
    }

    private Boolean akaMatches(String aka, String convertedAka, List<String> tokens) {
        for (String token : tokens) {
            String t = token.toLowerCase();
            Boolean matched = (String.isNotBlank(aka) && aka.toLowerCase().contains(t)) ||
                              (String.isNotBlank(convertedAka) && convertedAka.toLowerCase().contains(t));
            if (!matched) {
                return false;
            }
        }
        return true;
    }

    private Integer matchScore(String fieldValue, String token, Integer fieldWeight) {
        if (String.isBlank(fieldValue)) {
            return 0;
        }
        String fv = fieldValue.toLowerCase();
        if (fv == token) {
            return fieldWeight + MATCH_EXACT;
        } else if (fv.startsWith(token)) {
            return fieldWeight + MATCH_STARTS_WITH;
        } else if (fv.contains(' ' + token) || fv.startsWith(token)) {
            return fieldWeight + MATCH_STARTS_WITH;
        } else if (fv.contains(token)) {
            return fieldWeight + MATCH_CONTAINS;
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

    private class ScoredOrganization implements Comparable {
        public Account organization;
        public Integer score;

        public ScoredOrganization(Account a, Integer s) {
            this.organization = a;
            this.score = s;
        }

        public Integer compareTo(Object other) {
            ScoredOrganization o = (ScoredOrganization) other;
            return o.score - this.score;
        }
    }
}