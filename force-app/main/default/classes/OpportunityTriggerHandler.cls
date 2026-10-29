public without sharing class OpportunityTriggerHandler extends TriggerHandler {
    public List<Opportunity> newOpportunities;
    public List<Opportunity> oldOpportunities;
    public Map<Id, Opportunity> oldOpportunitiesMap;
    public Map<Id, Opportunity> newOpportunitiesmap;
    private static List<Task> tasksToInsert = new List<Task> ();
    private static Map<Id, Opportunity> oppMap = new Map<Id, Opportunity> ();
    private static List<Org_Association__c> orgAssociationsToInsert = new List<Org_Association__c> ();
    private static Set<String> prospectingTasksToCreate = new Set<String> {
        'Application',
            'Pitch Meeting',
            'In Discussion with Partner'
            };
                private static Set<String> onboardingTasksToCreate = new Set<String> {
                    'Project Kick-Off Meeting',
                        'CMS Training',
                        'Content Review'
                        };
                            private static Id bloombergConnectsAssociationId;
    public Boolean isBeforeTrigger = false;
    public Boolean isAfterTrigger = false;
    public Boolean isUpdateTrigger = false;
    public Boolean isDeleteTrigger = false;
    public Boolean isInsertTrigger = false;
    
    private static final String ERR_BEFORE_INSERT      = 'OPPORTUNITY_TRIGGER_BEFORE_INSERT_FAILED';
    private static final String ERR_BEFORE_UPDATE      = 'OPPORTUNITY_TRIGGER_BEFORE_UPDATE_FAILED';
    private static final String ERR_AFTER_INSERT       = 'OPPORTUNITY_TRIGGER_AFTER_INSERT_FAILED';
    private static final String ERR_AFTER_UPDATE    = 'OPPORTUNITY_TRIGGER_AFTER_UPDATE_FAILED';
    private static final String ERR_BULK_AFTER  = 'OPPORTUNITY_TRIGGER_BULK_AFTER_FAILED';
    private static final String ERR_AND_FINALLY  =  'OPPORTUNITY_TRIGGER_FINAL_FAILED';
    private static final String ERR_PROCESS_TASKS  = 'OPPORTUNITY_TRIGGER_PROCESS_TASKS_FAILED'; 
    private static final String ERR_PROCESS_ORGANIZATION_ASSOCIATIONS  = 'OPPORTUNITY_PROCESS_ORGANIZATION_ASSOCIATIONS_FAILED'; 
    private static final String ERR_PROCESS_BULK_AFTER_INSERT_OPERATIONS  = 'OPPORTUNITY_PROCESS_BULK_AFTER_INSERT_OPERATIONS_FAILED'; 
    private static final String ERR_PROCESS_BULK_AFTER_UPDATE_OPERATIONS  = 'OPPORTUNITY_PROCESS_BULK_AFTER_UPDATE_OPERATIONS_FAILED'; 
    private static final String ERR_QUERY_OPPORTUNITIES  = 'OPPORTUNITY_QUERY_OPPORTUNITIES_FAILED'; 
    private static final String ERR_DO_OPPORTUNITY_QUERY  = 'OPPORTUNITY_DO_OPPORTUNITY_QUERY_FAILED'; 
    private static final String ERR_CHECK_PROCESSING_TASKS_CRITERIA  = 'OPPORTUNITY_CHECK_PROCESSING_TASKS_CRITERIA_FAILED';  
    private static final String ERR_GET_OPPORTUNITY_TASKS_BY_OPP  = 'OPPORTUNITY_GET_OPPORTUNITY_TASKS_BY_OPP_FAILED'; 
    
    @testVisible static String OPPORTUNITY_STAGE_PROSPECTING = 'Prospecting';
    @testVisible static String OPPORTUNITY_STAGE_APPLICATION = 'Application';
    @testVisible static String OPPORTUNITY_STAGE_ONBOARDING = 'Onboarding';
    @testVisible static String OPPORTUNITY_STAGE_GO_LIVE = 'Go-Live';
    
    public OpportunityTriggerHandler() {
        this(Trigger.old, Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap, (Map<Id, Opportunity>) Trigger.newMap);
        if (Trigger.isBefore) isBeforeTrigger = true;
        if (Trigger.isAfter) isAfterTrigger = true;
        if (Trigger.isUpdate) isUpdateTrigger = true;
        if (Trigger.isDelete) isDeleteTrigger = true; 
        if (Trigger.isInsert) isInsertTrigger = true;       
    }
    
    public OpportunityTriggerHandler (List<Opportunity> oldOppList, List<Opportunity> newOppList, Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {
        oldOpportunities = oldOppList;
        newOpportunities = newOppList;
        oldOpportunitiesMap = oldMap;
        newOpportunitiesMap = newMap;
    }
    
    public override void beforeInsert (SObject so) {
        try{ 
            Opportunity o = (Opportunity)so;
            o.CloseDate = System.today().addDays(1000);
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_BEFORE_INSERT)); }
    }
    
    public override void beforeUpdate (SObject oldSo, SObject so) {
        try{
            Opportunity o = (Opportunity)so;
            Opportunity oldO = (Opportunity)oldSo;
            if(o.StageName != oldO.StageName) {
                o.Previous_Stage__c = oldO.StageName;
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_BEFORE_UPDATE)); }
    }
    
    public override void afterInsert(SObject so) {
        try{ 
            Opportunity o = (Opportunity)so;
            /*if(o.StageName != null && o.StageName == OPPORTUNITY_STAGE_GO_LIVE) {
                processOrganizationAssociations(o);
            }*/
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex,  NEW BBApps_ErrorCustomFields(ERR_AFTER_INSERT)); }
    }
    
    public override void afterUpdate(SObject oldSo, SObject so) {
        try{ 
            Opportunity o = (Opportunity)so;
            Opportunity oldO = (Opportunity)oldSo;
            /*if(o.StageName != oldO.StageName && o.StageName == OPPORTUNITY_STAGE_GO_LIVE) {
                    processOrganizationAssociations(o);
            }*/
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex,  NEW BBApps_ErrorCustomFields(ERR_AFTER_UPDATE)); }
    }
    
    public override void bulkAfter () {
        try{ 
            if(isAfterTrigger) {
                if(isUpdateTrigger) {
                    processBulkAfterUpdateOperations();
                }
                
                if(isInsertTrigger) {
                    processBulkAfterInsertOperations();
                }
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_BULK_AFTER)); }
    }
    
    public override void andFinally() {
        try{ 
            if(isAfterTrigger) {
                System.debug('finally ::::: ');
                if(isInsertTrigger || isUpdateTrigger) {
                    if(!tasksToInsert.isEmpty()) insert tasksToInsert;
                    //if(!orgAssociationsToInsert.isEmpty()) insert orgAssociationsToInsert;
                }
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_AND_FINALLY)); }
    }
    
    private static void processTasks (Opportunity o, Map<Id, Set<String>> opportunityTasksMap, Set<String> tasksToCreate) {
        try{ 
            
            for(String taskSubject: tasksToCreate) {
                if(
                    (
                        opportunityTasksMap.containsKey(o.Id) && !opportunityTasksMap.get(o.Id).contains(taskSubject)
                    ) ||
                    !opportunityTasksMap.containsKey(o.Id)
                ) {
                    tasksToInsert.add(
                        new Task (
                            Subject = taskSubject,
                            Type = taskSubject,
                            WhatId = o.Id
                        )
                    );
                }
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_PROCESS_TASKS)); }
    }    
    
    /*
    private static void processOrganizationAssociations (Opportunity o) {
        try{ 
            orgAssociationsToInsert.add(
                new Org_Association__c(
                    Association__c = Label.Bloomberg_Connects_Association_ID,
                    Organization__c = o.AccountId,
                    Opportunity__c = o.Id,
                    RecordTypeId = Schema.SObjectType.Org_Association__c.getRecordTypeInfosByDeveloperName().get('Bloomberg_Connects').getRecordTypeId(),
                    From__c = System.today()
                )
            );
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_PROCESS_ORGANIZATION_ASSOCIATIONS)); }
    }*/
    
    private void processBulkAfterInsertOperations () {
        try{ 
            for(Opportunity opp: newOpportunities) {
                if(checkProspectingTasksCriteria(opp)) {
                    processTasks (opp, new Map<Id, set<String>> (), prospectingTasksToCreate);
                }
                
                if(checkOnboardingTasksCriteria(opp)) {
                    processTasks (opp, new Map<Id, set<String>> (), prospectingTasksToCreate);
                    processTasks (opp, new Map<Id, set<String>> (), onboardingTasksToCreate);
                }
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_PROCESS_BULK_AFTER_INSERT_OPERATIONS)); }
    }
    
    private void processBulkAfterUpdateOperations () {
        try{ 
            Set<Id> opportunitiesToQuery = new Set<Id> ();
            for(Opportunity newOpp: newOpportunities) {
                Opportunity oldOpp;
                oldOpp = oldOpportunitiesMap.get(newOpp.Id);
                if(doOpportunityQuery (newOpp, oldOpp)) {
                    opportunitiesToQuery.add(newOpp.Id);
                }
            }
            
            Map<Id, Opportunity> queriedOpportunities = new Map<Id, Opportunity> ();
            
            if(!opportunitiesToQuery.isEmpty()) {
                queriedOpportunities = queryOpportunities(opportunitiesToQuery);
                
                for(Opportunity opp: queriedOpportunities.values()) {
                    Map<Id, set<String>> opportunityTasksMap = getOpportunityTasksByOpp (opp);
                    if(checkProspectingTasksCriteria(opp)) {
                        processTasks (opp, opportunityTasksMap, prospectingTasksToCreate);
                    }
                    
                    if(checkOnboardingTasksCriteria(opp)) {
                        processTasks (opp, opportunityTasksMap, prospectingTasksToCreate);
                        processTasks (opp, opportunityTasksMap, onboardingTasksToCreate);
                    }
                }
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_PROCESS_BULK_AFTER_UPDATE_OPERATIONS)); }
    }
    
    private Map<Id, Opportunity> queryOpportunities (Set<Id> opportunityIds) {
        try{ 
            return new Map<Id, Opportunity> (
                [
                    Select Id, StageName, 
                    (Select Id, Subject from Tasks) 
                    from Opportunity where Id IN: opportunityIds
                ]
            );
        } catch (Exception ex) {
            BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_QUERY_OPPORTUNITIES));
            return new Map<Id, Opportunity>();
        }
        
    }
    
    private Boolean doOpportunityQuery (Opportunity newOpp, Opportunity oldOpp) {
        try{ 
            if(newOpp.StageName != null && 
               (
                   newOpp.StageName == OPPORTUNITY_STAGE_PROSPECTING || 
                   newOpp.StageName == OPPORTUNITY_STAGE_ONBOARDING
               )
              ) {
                  if(
                      (oldOpp != null && oldOpp.StageName != newOpp.StageName) ||
                      oldOpp == null
                  ) {
                      return true;
                  }
              }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_DO_OPPORTUNITY_QUERY)); }
        return false;
    }
    
    private Boolean checkProspectingTasksCriteria (Opportunity newOpp) {
        try{ 
            if(
                newOpp.StageName != null && 
                (
                    newOpp.StageName == OPPORTUNITY_STAGE_PROSPECTING ||
                    newOpp.StageName == OPPORTUNITY_STAGE_APPLICATION
                )
            ) {
                return true;
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_CHECK_PROCESSING_TASKS_CRITERIA)); }
        
        return false;
    }
    
    private Boolean checkOnboardingTasksCriteria (Opportunity newOpp) {
        if(newOpp.StageName != null && newOpp.StageName == OPPORTUNITY_STAGE_ONBOARDING) {
            return true;
        }
        
        return false;
    }
    
    private Map<Id, set<String>> getOpportunityTasksByOpp (Opportunity opp) {
        Map<Id, Set<String>> opportunitiesTasksMap = new Map<Id, Set<String>> ();
        try{ 
            
            for(Task t: opp.Tasks) {
                Set<String> tasks;
                if(opportunitiesTasksMap.containskey(opp.Id)) {
                    tasks = opportunitiesTasksMap.get(opp.Id);
                    tasks.add(t.Subject);
                    opportunitiesTasksMap.put(opp.Id, tasks);
                } else {
                    tasks = new Set<String> ();
                    tasks.add(t.Subject);
                    opportunitiesTasksMap.put(opp.Id, tasks);
                }
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex, NEW BBApps_ErrorCustomFields(ERR_GET_OPPORTUNITY_TASKS_BY_OPP)); }
        
        return opportunitiesTasksMap;
    }
}