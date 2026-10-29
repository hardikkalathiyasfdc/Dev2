/**
* Author      : Ravi
* Date        : 09/10/2026
* Jira        : BRME-6952
* Description : This class is the controller for highlightMetrics lightning web component.
* Test        : HighlightMetricsControllerTest 
*/
public with sharing class HighlightMetricsController { 

    private static final String ERR_GET_ROWS = 'HighlightMetricsController_GET_ROWS_FAILED';
    private static final String ERR_SAVE = 'HighlightMetricsController_SAVE_FAILED';
    private static final String ERR_UPSERT = 'HighlightMetricsController_UPSERT_FAILED';
    private static final String ERR_DELETE = 'HighlightMetricsController_DELETE_FAILED';

    public class MetricsWrapper {
        @AuraEnabled public Id teamId;
        @AuraEnabled public String teamName;
        @AuraEnabled public List<MetricRow> rows = new List<MetricRow>();
    }

    public class MetricRow {
        @AuraEnabled public Id metricId;
        @AuraEnabled public String metricName;
        @AuraEnabled public String previousValue;
        @AuraEnabled public Id metricValueId;
        @AuraEnabled public Decimal value;
        @AuraEnabled public Date valueDate;
        @AuraEnabled public String notes;
        @AuraEnabled public Boolean submitted;

        public MetricRow(Metric__c m, Metric_Value__c mv) {
            this.metricId   = m.Id;
            this.metricName = m.Name;

            if (m.Latest_Metric_Value__c != null
                && m.Latest_Metric_Value__r.Value__c != null) {
                String summary = m.Latest_Metric_Value__r.Value__c
                    .stripTrailingZeros()
                    .toPlainString();

                if (String.isNotBlank(m.Unit__c)) {
                    summary += ' ' + m.Unit__c;
                }
                if (m.Latest_Metric_Value__r.Date__c != null) {
                    summary += ' as of ' + m.Latest_Metric_Value__r.Date__c.format();
                }

                this.previousValue = summary;
            }

            if (mv != null) {
                this.metricValueId = mv.Id;
                this.value         = mv.Value__c;
                this.valueDate     = mv.Date__c;
                this.notes         = mv.Notes__c;
            }
            this.submitted = (mv != null && mv.Value__c != null);
        }
    }

    @AuraEnabled(cacheable=true)
    public static MetricsWrapper getMetricRows(Id highlightId) {
        try {
            MetricsWrapper wrap = new MetricsWrapper();

            List<Highlight_Interaction__c> highlights = [
                SELECT Id, Team__c, Team__r.Name
                FROM Highlight_Interaction__c
                WHERE Id = :highlightId
                WITH USER_MODE
                LIMIT 1
            ];
            if (highlights.isEmpty()) {
                return wrap;
            }

            Highlight_Interaction__c hi = highlights[0];
            wrap.teamId   = hi.Team__c;
            wrap.teamName = (hi.Team__c == null) ? null : hi.Team__r.Name;

            Map<Id, Metric_Value__c> valuesByMetric = new Map<Id, Metric_Value__c>();
            for (Metric_Value__c mv : [
                SELECT Id, Metric__c, Value__c, Date__c, Notes__c
                FROM Metric_Value__c
                WHERE Highlight_Interaction__c = :highlightId
                WITH USER_MODE
            ]) {
                if (mv.Metric__c != null) {
                    valuesByMetric.put(mv.Metric__c, mv);
                }
            }

            if (hi.Team__c == null && valuesByMetric.isEmpty()) {
                return wrap;
            }

            Set<Id> valuedMetricIds = valuesByMetric.keySet();
            Id teamId = hi.Team__c;

            List<MetricRow> submitted = new List<MetricRow>();
            List<MetricRow> remaining = new List<MetricRow>();

            for (Metric__c m : [
                SELECT Id, Name, Unit__c, Order__c, Team__c,
                       Latest_Metric_Value__c,
                       Latest_Metric_Value__r.Value__c,
                       Latest_Metric_Value__r.Date__c
                FROM Metric__c
                WHERE Team__c = :teamId OR Id IN :valuedMetricIds
                WITH USER_MODE
                ORDER BY Order__c NULLS LAST, Name
            ]) {
                MetricRow row = new MetricRow(m, valuesByMetric.get(m.Id));
                if (row.submitted) {
                    submitted.add(row);
                } else {
                    remaining.add(row);
                }
            }

            wrap.rows.addAll(submitted);
            wrap.rows.addAll(remaining);
            return wrap;
        } catch (Exception e) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_GET_ROWS);
            BBApps_ErrorHandler.logErrors(e, f);
            throw new AuraHandledException('Error fetching metrics: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void saveMetricValues(List<Metric_Value__c> values, List<Id> removedIds) {
        try {
            if (values != null && !values.isEmpty()) {
                BBApps_Crud.doUpsertWithHandling(values, true, ERR_UPSERT);
            }
            if (removedIds != null && !removedIds.isEmpty()) {
                List<Metric_Value__c> recordsToDelete = [
                    SELECT Id FROM Metric_Value__c WHERE Id IN :removedIds WITH USER_MODE
                ];
                if (!recordsToDelete.isEmpty()) {
                    BBApps_Crud.doDeleteWithHandling(recordsToDelete, true, ERR_DELETE);
                }
            }
        } catch (Exception e) {
            BBApps_ErrorCustomFields f = new BBApps_ErrorCustomFields(ERR_SAVE);
            BBApps_ErrorHandler.logErrors(e, f);
            throw new AuraHandledException('Error saving metric values: ' + e.getMessage());
        }
    }
}