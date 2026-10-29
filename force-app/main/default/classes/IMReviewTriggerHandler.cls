/**
* Author      : Paddy
* Date        : 11/14/2024
* Jira        : IM-57
* Description : This class is Trigger handler class for IM_Review__c.
* Modified By : 
* Test        : IMReviewTriggerHandlerTest
*/
public with sharing class IMReviewTriggerHandler extends TriggerHandler {

    public List<IM_Review__c> newReviews;
    public List<IM_Review__c> oldReviews;
    public Map<Id, IM_Review__c> oldMap;
    public Map<Id, IM_Review__c> newMap;
    public Map<Id, User> reviewers;
    public static Set<Id> initiativeIds = new Set<Id>();
    public static Map<Id, IM_Initiative__c> initiatives = new Map<Id, IM_Initiative__c>();
    public static Map<Id, IM_Initiative__c> initiativesToUpdate = new Map<Id, IM_Initiative__c>();
    public static Map<Id, IM_Review__c> recentStrategyReviewForInitiative = new Map<Id, IM_Review__c>();
    public static Map<Id, IM_Review__c> recentBudgetReviewForInitiative = new Map<Id, IM_Review__c>();

    private static final String STRATEGY = 'Strategy';
    private static final String BUDGET = 'Budget';

    public IMReviewTriggerHandler() {
        this(Trigger.old, Trigger.new, (Map<Id, IM_Review__c>) Trigger.oldMap, (Map<Id, IM_Review__c>) Trigger.newMap);
    }

    public IMReviewTriggerHandler(List<IM_Review__c> oldReviewList, List<IM_Review__c> newReviewList) {
        newReviews = newReviewList;
        oldReviews = oldReviewList;
    }
    
    public IMReviewTriggerHandler(List<IM_Review__c> oldReviewList, List<IM_Review__c> newReviewList , Map<Id, IM_Review__c> oldMap , Map<Id, IM_Review__c> newMap){
        newReviews = newReviewList;
        oldReviews = oldReviewList;
        this.oldMap = oldMap;
        this.newMap = newMap;
    }

    public override void beforeInsert(SObject so) {
        IM_Review__c review = (IM_Review__c) so;
        setName(review);
    }

    public override void afterInsert(SObject so) {
        IM_Review__c review = (IM_Review__c) so;
        if(review.Review_Completed__c == null) {
            setInitiativeReview(review, null);
        }
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        IM_Review__c oldReview = (IM_Review__c) oldSo;
        IM_Review__c curReview = (IM_Review__c) so;
        if(isFieldChanged(curReview, 'Reviewer__c')) {
            setName(curReview);
        }
    }

    public override void afterUpdate(SObject oldSo, SObject so) {
        IM_Review__c curReview = (IM_Review__c) so;
        if(isFieldChanged(curReview, 'Review_Completed__c')) {
            if(STRATEGY.equalsIgnoreCase(curReview.Type__c)) {
                setInitiativeReview(recentStrategyReviewForInitiative.get(curReview.Initiative__c), curReview);
            } else if (BUDGET.equalsIgnoreCase(curReview.Type__c)) {
                setInitiativeReview(recentBudgetReviewForInitiative.get(curReview.Initiative__c), curReview);
            }
        }
    }

    //Set Name based on reviewer
    private void setName(IM_Review__c review) {
        if(reviewers.containsKey(review.Reviewer__c)) {
            User reviewer = reviewers.get(review.Reviewer__c);
            review.Name = reviewer.FirstName + ' ' + reviewer.LastName;
        }
    }

    //Set Current reviewer on initiative based on review type and completion date
    private void setInitiativeReview(IM_Review__c review, IM_Review__c currentReview) {
        //If there is no open Review, make current reviewer to null
        if(review == null) {
            IM_Initiative__c initiative = initiatives.get(currentReview.Initiative__c);
            initiative.put(currentReview.Type__c + '_Current_Reviewer__c', null);
            initiativesToUpdate.put(initiative.Id, initiative);
        } else if(initiatives.containsKey(review.Initiative__c)) {
            IM_Initiative__c initiative = initiatives.get(review.Initiative__c);
            initiative.put(review.Type__c + '_Current_Reviewer__c', review.Reviewer__c);
            initiativesToUpdate.put(initiative.Id, initiative);
        }
    }

    public override void bulkBefore() {
        Set<Id> reviewerIds = new Set<Id>();
        for(IM_Review__c review : newReviews) {
            reviewerIds.add(review.Reviewer__c);
            initiativeIds.add(review.Initiative__c);
        }
        reviewers = new Map<Id, User>([SELECT Id, Name, FirstName, LastName FROM User WHERE Id IN :reviewerIds WITH SYSTEM_MODE]);
    }

    public override void bulkAfter() {
        initiatives = new Map<Id, IM_Initiative__c>([SELECT Id, Name, Budget_Current_Reviewer__c, 
            Strategy_Current_Reviewer__c FROM IM_Initiative__c WHERE Id IN :initiativeIds WITH SYSTEM_MODE ORDER BY CreatedDate desc]);
        List<IM_Review__c> allReviews = [SELECT Id, Type__c, Reviewer__c , Review_Completed__c, Initiative__c FROM IM_Review__c 
            WHERE Initiative__c IN :initiativeIds WITH SYSTEM_MODE ORDER BY CreatedDate desc];
        for(IM_Review__c review : allReviews) {
            if(STRATEGY.equalsIgnoreCase(review.Type__c) && !recentStrategyReviewForInitiative.containsKey(review.Initiative__c) && review.Review_Completed__c == null) {
                recentStrategyReviewForInitiative.put(review.Initiative__c, review);
                break;
            } else if (BUDGET.equalsIgnoreCase(review.Type__c) && !recentBudgetReviewForInitiative.containsKey(review.Initiative__c) && review.Review_Completed__c == null) {
                recentBudgetReviewForInitiative.put(review.Initiative__c, review);
                break;
            }
        }
    }

    public override void andFinally() {
        BBApps_Crud.doUpdate(
            initiativesToUpdate.values()
        );
    }
}