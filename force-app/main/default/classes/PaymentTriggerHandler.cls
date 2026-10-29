public class PaymentTriggerHandler extends TriggerHandler {
    public List<Payment__c> newPayments;
    public List<Payment__c> oldPayments;
    public Map<Id, Payment__c> newPaymentsMap;
    public Map<Id, Payment__c> oldPaymentsMap;
    
    private static final String ERR_BULK_BEFORE = 'PAYMENT_TRIGGER_BULK_BEFORE_FAILED';
    
    public PaymentTriggerHandler () {
        this(Trigger.old, Trigger.new, (Map<Id, Payment__c>) Trigger.oldMap, (Map<Id, Payment__c>) Trigger.newMap);
    }
    
    public PaymentTriggerHandler (List<Payment__c> oldCList, List<Payment__c> newCList, Map<Id, Payment__c> oldMap, Map<Id, Payment__c> newMap) {
        oldPayments = oldCList;
        newPayments = newCList;
        oldPaymentsMap = oldMap;
        newPaymentsMap = newMap;
    }
    
    public override void bulkBefore () {
        try{ 
            Map<Id,Id> paymentsPledgeMap = new Map<Id,Id> ();
            for (Payment__c p: newPayments) {
                if (
                    trigger.isInsert || 
                    (
                        trigger.isUpdate &&
                        p.Amount__c != oldPaymentsMap.get(p.Id).Amount__c
                    )
                ) {
                    paymentsPledgeMap.put (p.Id,p.Pledge__c);
                }
            }
            
            if (!paymentsPledgeMap.isEmpty ()) {
                Map<Id, Pledge__c> pledgesMap = new Map<Id, Pledge__c> ([Select Id, Pledge_Currency__c from Pledge__c where Id IN: paymentsPledgeMap.values ()]);
                
                for (Payment__c p: newPayments) {
                    if (
                        paymentsPledgeMap.keyset().contains (p.Id) &&
                        pledgesMap.get(p.Pledge__c).Pledge_Currency__c != null &&
                        pledgesMap.get(p.Pledge__c).Pledge_Currency__c == 'USD'
                    ) {
                        p.Payment_Amount_USD__c = p.Amount__c;
                    }
                }
            }
        } catch (Exception ex) { BBApps_ErrorHandler.logErrors(ex,new BBApps_ErrorCustomFields(ERR_BULK_BEFORE ) ); }
    }    
}