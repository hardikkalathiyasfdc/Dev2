/****
 * Author: Nishant Bakhrey
 * Description: This class is used in a Transaction Security Policy to determine if a critical permission set is
 *              assigned to a user.
 *****/
global without sharing class PermissionSetAssignmentSecurityPolicy implements TxnSecurity.EventCondition {

    public Boolean evaluate(SObject event) {
        PermissionSetEventStore permissionEvent = (PermissionSetEventStore) event;
        return true;/*
        if(permissionEvent == null) return false;
        if(permissionEvent.Operation == null) return false;
        if(permissionEvent.Operation == 'AssignedToUsers') {
            System.debug('Permission Set Assignment Event: ' + permissionEvent.ParentIdList);
            return true;
        }
        return false;*/
    }
}