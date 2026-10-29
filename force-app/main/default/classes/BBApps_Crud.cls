/**
 * `BBApps_Crud` is a Database Class used for CRUD actions on records
 *
 * @author Marcus Little
 * @since 2024-12-05 created class
 *
 * @group CRUD
 * @group-content ./customAssets/html/crud.html
 */
public inherited sharing class BBApps_Crud {
    /**
     * Insert record to Database
     * @param record
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doInsert(SObject record) {
        return doInsert(record, true);
    }
    /**
     * Insert record to Database
     * @param record
     * @param allOrNone
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doInsert(SObject record, Boolean allOrNone) {
        return doInsert(record, allOrNone, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Insert record to Database with explicit AccessLevel
     * @param record
     * @param allOrNone
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doInsert(SObject record, Boolean allOrNone, AccessLevel accessLevel) {
        Database.SaveResult sr = Database.insert(record, allOrNone, accessLevel);
        return new BBApps_DMLResult(sr);
    }

    /**
     * Insert record to Database
     * @param record
     * @param dmlOptions
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doInsert(SObject record, Database.DMLOptions dmlOptions) {
        return doInsert(record, dmlOptions, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Insert record to Database with dmlOptions and explicit AccessLevel
     * @param record
     * @param dmlOptions
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doInsert(SObject record, Database.DMLOptions dmlOptions, AccessLevel accessLevel) {
        Database.SaveResult sr = Database.insert(record, dmlOptions, accessLevel);
        return new BBApps_DMLResult(sr);
    }
    /**
     * Insert records to Database
     * @param records
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doInsert(List<SObject> records) {
        return doInsert(records, true);
    }
    /**
     * Insert records to database all or none
     * @param records
     * @param allOrNone
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doInsert(List<SObject> records, Boolean allOrNone) {
        return doInsert(records, allOrNone, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Insert records to database all or none with explicit AccessLevel
     * @param records
     * @param allOrNone
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doInsert(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel) {
        List<Database.SaveResult> srs = Database.insert(records, allOrNone, accessLevel);
        return new BBApps_DMLResultList(srs).genResults;
    }

    /**
     * Insert records to database all or none
     * @param records
     * @param dmlOptions
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doInsert(List<SObject> records, Database.DMLOptions dmlOptions) {
        return doInsert(records, dmlOptions, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Insert records to database with dmlOptions and explicit AccessLevel
     * @param records
     * @param dmlOptions
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doInsert(List<SObject> records, Database.DMLOptions dmlOptions, AccessLevel accessLevel) {
        List<Database.SaveResult> srs = Database.insert(records, dmlOptions, accessLevel);
        return new BBApps_DMLResultList(srs).genResults;
    }
    /**
     * Update records in database
     * @param record
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpdate(SObject record) {
        return doUpdate(record, true);
    }
    /**
     * Update records in database
     * @param record
     * @param allOrNone
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpdate(SObject record, Boolean allOrNone) {
        return doUpdate(record, allOrNone, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Update record in database with explicit AccessLevel
     * @param record
     * @param allOrNone
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpdate(SObject record, Boolean allOrNone, AccessLevel accessLevel) {
        Database.SaveResult sr = Database.update(record, allOrNone, accessLevel);
        return new BBApps_DMLResult(sr);
    }
    /**
     * Update record to Database
     * @param record
     * @param dmlOptions
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpdate(SObject record, Database.DMLOptions dmlOptions) {
        return doUpdate(record, dmlOptions, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Update record to Database with dmlOptions and explicit AccessLevel
     * @param record
     * @param dmlOptions
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpdate(SObject record, Database.DMLOptions dmlOptions, AccessLevel accessLevel) {
        Database.SaveResult sr = Database.update(record, dmlOptions, accessLevel);
        return new BBApps_DMLResult(sr);
    }
    /**
     * Update records in database
     * @param records
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpdate(List<SObject> records) {
        return doUpdate(records, true);
    }
    /**
     * Update records in database all or none
     * @param records
     * @param allOrNone
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpdate(List<SObject> records, Boolean allOrNone) {
        return doUpdate(records, allOrNone, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Update records in database all or none with explicit AccessLevel
     * @param records
     * @param allOrNone
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpdate(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel) {
        List<Database.SaveResult> srs = Database.update(records, allOrNone, accessLevel);
        return new BBApps_DMLResultList(srs).genResults;
    }
    /**
     * Update records in database all or none
     * @param records
     * @param dmlOptions
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpdate(List<SObject> records, Database.DMLOptions dmlOptions) {
        return doUpdate(records, dmlOptions, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Update records in database with dmlOptions and explicit AccessLevel
     * @param records
     * @param dmlOptions
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpdate(List<SObject> records, Database.DMLOptions dmlOptions, AccessLevel accessLevel) {
        List<Database.SaveResult> srs = Database.update(records, dmlOptions, accessLevel);
        return new BBApps_DMLResultList(srs).genResults;
    }
    /**
     * Delete records in database
     * @param record
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDelete(SObject record) {
        return doDelete(record, true);
    }
    /**
     * Delete records in database
     * @param record
     * @param allOrNone
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDelete(SObject record, Boolean allOrNone) {
        return doDelete(record, allOrNone, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Delete record in database with explicit AccessLevel
     * @param record
     * @param allOrNone
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDelete(SObject record, Boolean allOrNone, AccessLevel accessLevel) {
        Database.DeleteResult sr = Database.delete(record, allOrNone, accessLevel);
        return new BBApps_DMLResult(sr);
    }
    /**
     * Delete records in database
     * @param records
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDelete(List<SObject> records) {
        return doDelete(records, true);
    }
    /**
     * Delete records in database all or none
     * @param records
     * @param allOrNone
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDelete(List<SObject> records, Boolean allOrNone) {
        return doDelete(records, allOrNone, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Delete records in database all or none with explicit AccessLevel
     * @param records
     * @param allOrNone
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDelete(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel) {
        List<Database.DeleteResult> srs = Database.delete(records, allOrNone, accessLevel);
        return new BBApps_DMLResultList(srs).genResults;
    }
    /**
     * Delete records in database
     * @param record
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDelete(Id record) {
        return doDelete(record, true);
    }
    /**
     * Delete records in database
     * @param record
     * @param allOrNone
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDelete(Id record, Boolean allOrNone) {
        return doDelete(record, allOrNone, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Delete record by Id in database with explicit AccessLevel
     * @param record
     * @param allOrNone
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDelete(Id record, Boolean allOrNone, AccessLevel accessLevel) {
        Database.DeleteResult sr = Database.delete(record, allOrNone, accessLevel);
        return new BBApps_DMLResult(sr);
    }
    /**
     * Delete records in database
     * @param records
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDelete(List<Id> records) {
        return doDelete(records, true);
    }
    /**
     * Delete records in database all or none
     * @param records
     * @param allOrNone
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDelete(List<Id> records, Boolean allOrNone) {
        return doDelete(records, allOrNone, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Delete records by Id in database all or none with explicit AccessLevel
     * @param records
     * @param allOrNone
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDelete(List<Id> records, Boolean allOrNone, AccessLevel accessLevel) {
        List<Database.DeleteResult> srs = Database.delete(records, allOrNone, accessLevel);
        return new BBApps_DMLResultList(srs).genResults;
    }
    /**
     * Upsert records in database
     * @param record
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsert(SObject record) {
        return doUpsert(record, true);
    }
    /**
     * Upsert records in database
     * @param record
     * @param allOrNone
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsert(SObject record, Boolean allOrNone) {
        return doUpsert(record, allOrNone, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Upsert record in database with explicit AccessLevel
     * @param record
     * @param allOrNone
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsert(SObject record, Boolean allOrNone, AccessLevel accessLevel) {
        Database.UpsertResult sr = Database.upsert(record, allOrNone, accessLevel);
        return new BBApps_DMLResult(sr);
    }
    /**
     * Upsert records in database
     * @param records
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsert(List<SObject> records) {
        return doUpsert(records, true);
    }
    /**
     * Upsert records in database all or none
     * @param records
     * @param allOrNone
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsert(List<SObject> records, Boolean allOrNone) {
        return doUpsert(records, allOrNone, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Upsert records in database all or none with explicit AccessLevel
     * @param records
     * @param allOrNone
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsert(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel) {
        List<Database.UpsertResult> srs = Database.upsert(records, allOrNone, accessLevel);
        return new BBApps_DMLResultList(srs).genResults;
    }
    /**
     * Upsert records in database using external field
     * @param record
     * @param field
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsert(SObject record, Schema.SObjectField field) {
        return doUpsert(record, field, true);
    }
    /**
     * Upsert records in database using external field
     * @param record
     * @param field
     * @param allOrNone
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsert(SObject record, Schema.SObjectField field, Boolean allOrNone) {
        return doUpsert(record, field, allOrNone, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Upsert record in database using external field with explicit AccessLevel
     * @param record
     * @param field
     * @param allOrNone
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsert(SObject record, Schema.SObjectField field, Boolean allOrNone, AccessLevel accessLevel) {
        Database.UpsertResult sr = Database.upsert(record, field, allOrNone, accessLevel);
        return new BBApps_DMLResult(sr);
    }
    /**
     * Upsert records in database using external field
     * @param records
     * @param field
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsert(List<SObject> records, Schema.SObjectField field) {
        return doUpsert(records, field, true);
    }
    /**
     * Upsert records in database using external field all or none
     * @param records
     * @param field
     * @param allOrNone
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsert(List<SObject> records, Schema.SObjectField field, Boolean allOrNone) {
        return doUpsert(records, field, allOrNone, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Upsert records in database using external field all or none with explicit AccessLevel
     * @param records
     * @param field
     * @param allOrNone
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsert(List<SObject> records, Schema.SObjectField field, Boolean allOrNone, AccessLevel accessLevel) {
        List<Database.UpsertResult> srs = Database.upsert(records, field, allOrNone, accessLevel);
        return new BBApps_DMLResultList(srs).genResults;
    }
    /**
     * Undelete records in database
     * @param record
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndelete(SObject record) {
        return doUndelete(record, true);
    }
    /**
     * Undelete records in database
     * @param record
     * @param allOrNone
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndelete(SObject record, Boolean allOrNone) {
        return doUndelete(record, allOrNone, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Undelete record in database with explicit AccessLevel
     * @param record
     * @param allOrNone
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndelete(SObject record, Boolean allOrNone, AccessLevel accessLevel) {
        Database.UndeleteResult sr = Database.undelete(record, allOrNone, accessLevel);
        return new BBApps_DMLResult(sr);
    }
    /**
     * Undelete records in database
     * @param records
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndelete(List<SObject> records) {
        return doUndelete(records, true);
    }
    /**
     * Undelete records in database all or none
     * @param records
     * @param allOrNone
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndelete(List<SObject> records, Boolean allOrNone) {
        return doUndelete(records, allOrNone, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Undelete records in database all or none with explicit AccessLevel
     * @param records
     * @param allOrNone
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndelete(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel) {
        List<Database.UndeleteResult> srs = Database.undelete(records, allOrNone, accessLevel);
        return new BBApps_DMLResultList(srs).genResults;
    }
    /**
     * Undelete records in database
     * @param record
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndelete(Id record) {
        return doUndelete(record, true);
    }
    /**
     * Undelete records in database
     * @param record
     * @param allOrNone
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndelete(Id record, Boolean allOrNone) {
        return doUndelete(record, allOrNone, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Undelete record by Id in database with explicit AccessLevel
     * @param record
     * @param allOrNone
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndelete(Id record, Boolean allOrNone, AccessLevel accessLevel) {
        Database.UndeleteResult sr = Database.undelete(record, allOrNone, accessLevel);
        return new BBApps_DMLResult(sr);
    }
    /**
     * Undelete records in database
     * @param records
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndelete(List<Id> records) {
        return doUndelete(records, true);
    }
    /**
     * Undelete records in database all or none
     * @param records
     * @param allOrNone
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndelete(List<Id> records, Boolean allOrNone) {
        return doUndelete(records, allOrNone, AccessLevel.SYSTEM_MODE);
    }
    /**
     * Undelete records by Id in database all or none with explicit AccessLevel
     * @param records
     * @param allOrNone
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndelete(List<Id> records, Boolean allOrNone, AccessLevel accessLevel) {
        List<Database.UndeleteResult> srs = Database.undelete(records, allOrNone, accessLevel);
        return new BBApps_DMLResultList(srs).genResults;
    }

    // dml with error handling

    /**
     * Insert record to Database with Error Handling
     * @param record
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doInsertWithHandling(SObject record) {
        return doInsertWithHandling(record, true);
    }
    /**
     * Insert record to Database with Error Handling
     * @param record
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doInsertWithHandling(SObject record, String functionality) {
        return doInsertWithHandling(record, true, functionality);
    }
    /**
     * Insert record to Database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doInsertWithHandling(SObject record, AccessLevel accessLevel, String functionality) {
        return doInsertWithHandling(record, true, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Insert record to Database with Error Handling
     * @param record
     * @param customFields custom fields to be passed in error log event
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doInsertWithHandling(SObject record, BBApps_ErrorCustomFields customFields) {
        return doInsertWithHandling(record, true, customFields);
    }
    /**
     * Insert record to Database with Error Handling
     * @param record
     * @param allOrNone
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doInsertWithHandling(SObject record, Boolean allOrNone) {
        return doInsertWithHandling(record, allOrNone, new BBApps_ErrorCustomFields());
    }
    /**
     * Insert record to Database with Error Handling
     * @param record
     * @param dmlOptions
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doInsertWithHandling(SObject record, Database.DMLOptions dmlOptions) {
        return doInsertWithHandling(record, dmlOptions, new BBApps_ErrorCustomFields());
    }
    /**
     * Insert record to Database with Error Handling
     * @param record
     * @param allOrNone
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doInsertWithHandling(SObject record, Boolean allOrNone, String functionality) {
        return doInsertWithHandling(record, allOrNone, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Insert record to Database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doInsertWithHandling(SObject record, Boolean allOrNone, AccessLevel accessLevel, String functionality) {
        return doInsertWithHandling(record, allOrNone, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Insert record to Database with Error Handling
     * @param record
     * @param dmlOptions
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doInsertWithHandling(SObject record, Database.DMLOptions dmlOptions, String functionality) {
        return doInsertWithHandling(record, dmlOptions, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Insert record to Database with Error Handling, dmlOptions, and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doInsertWithHandling(SObject record, Database.DMLOptions dmlOptions, AccessLevel accessLevel, String functionality) {
        return doInsertWithHandling(record, dmlOptions, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Insert record to Database with Error Handling
     * @param record
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doInsertWithHandling(SObject record, Boolean allOrNone, BBApps_ErrorCustomFields customFields) {
        return doInsertWithHandling(record, allOrNone, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Insert record to Database with Error Handling and explicit AccessLevel
     * @param record
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doInsertWithHandling(SObject record, Boolean allOrNone, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            BBApps_DMLResult sr = doInsert(record, allOrNone, accessLevel);
            BBApps_ErrorHandler.logErrors(record, sr, customFields);
            return sr;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(record, e, customFields);
            throw e;
        }
    }
    /**
     * Insert record to Database with Error Handling
     * @param record
     * @param dmlOptions
     * @param customFields custom fields to be passed in error log event
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doInsertWithHandling(SObject record, Database.DMLOptions dmlOptions, BBApps_ErrorCustomFields customFields) {
        return doInsertWithHandling(record, dmlOptions, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Insert record to Database with Error Handling, dmlOptions, and explicit AccessLevel
     * @param record
     * @param dmlOptions
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doInsertWithHandling(SObject record, Database.DMLOptions dmlOptions, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            BBApps_DMLResult sr = doInsert(record, dmlOptions, accessLevel);
            BBApps_ErrorHandler.logErrors(record, sr, customFields);
            return sr;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(record, e, customFields);
            throw e;
        }
    }
    /**
     * Insert records to Database with Error Handling
     * @param records
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doInsertWithHandling(List<SObject> records) {
        return doInsertWithHandling(records, true);
    }
    /**
     * Insert records to Database with Error Handling
     * @param records
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doInsertWithHandling(List<SObject> records, String functionality) {
        return doInsertWithHandling(records,true, functionality);
    }
    /**
     * Insert records to Database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doInsertWithHandling(List<SObject> records, AccessLevel accessLevel, String functionality) {
        return doInsertWithHandling(records, true, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Insert records to Database with Error Handling
     * @param records
     * @param customFields custom fields to be passed in error log event
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doInsertWithHandling(List<SObject> records, BBApps_ErrorCustomFields customFields) {
        return doInsertWithHandling(records, true, customFields);
    }
    /**
     * Insert records to database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doInsertWithHandling(List<SObject> records, Boolean allOrNone) {
        return doInsertWithHandling(records, allOrNone, new BBApps_ErrorCustomFields());
    }
    /**
     * Insert records to database all or none with Error Handling
     * @param records
     * @param dmlOptions
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doInsertWithHandling(List<SObject> records, Database.DMLOptions dmlOptions) {
        return doInsertWithHandling(records, dmlOptions, new BBApps_ErrorCustomFields());
    }
    /**
     * Insert records to database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doInsertWithHandling(List<SObject> records, Boolean allOrNone, String functionality) {
        return doInsertWithHandling(records, allOrNone, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Insert records to Database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doInsertWithHandling(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel, String functionality) {
        return doInsertWithHandling(records, allOrNone, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Insert records to database all or none with Error Handling
     * @param records
     * @param dmlOptions
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doInsertWithHandling(List<SObject> records, Database.DMLOptions dmlOptions, String functionality) {
        return doInsertWithHandling(records, dmlOptions, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Insert records to Database with Error Handling, dmlOptions, and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doInsertWithHandling(List<SObject> records, Database.DMLOptions dmlOptions, AccessLevel accessLevel, String functionality) {
        return doInsertWithHandling(records, dmlOptions, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Insert records to database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doInsertWithHandling(List<SObject> records, Boolean allOrNone, BBApps_ErrorCustomFields customFields) {
        return doInsertWithHandling(records, allOrNone, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Insert records to Database with Error Handling and explicit AccessLevel
     * @param records
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doInsertWithHandling(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            List<BBApps_DMLResult> srs = doInsert(records, allOrNone, accessLevel);
            BBApps_ErrorHandler.logErrors(records, srs, customFields);
            return srs;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(records, e);
            throw e;
        }
    }
    /**
     * Insert records to database all or none with Error Handling
     * @param records
     * @param dmlOptions
     * @param customFields custom fields to be passed in error log event
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doInsertWithHandling(List<SObject> records, Database.DMLOptions dmlOptions, BBApps_ErrorCustomFields customFields) {
        return doInsertWithHandling(records, dmlOptions, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Insert records to Database with Error Handling, dmlOptions, and explicit AccessLevel
     * @param records
     * @param dmlOptions
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doInsertWithHandling(List<SObject> records, Database.DMLOptions dmlOptions, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            List<BBApps_DMLResult> srs = doInsert(records, dmlOptions, accessLevel);
            BBApps_ErrorHandler.logErrors(records, srs, customFields);
            return srs;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(records, e);
            throw e;
        }
    }
    /**
     * Update records in database with Error Handling
     * @param record
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpdateWithHandling(SObject record) {
        return doUpdateWithHandling(record, true);
    }
    /**
     * Update records in database with Error Handling
     * @param record
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpdateWithHandling(SObject record, string functionality) {
        return doUpdateWithHandling(record, true, functionality);
    }
    /**
     * Update records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpdateWithHandling(SObject record, AccessLevel accessLevel, String functionality) {
        return doUpdateWithHandling(record, true, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Update records in database with Error Handling
     * @param record
     * @param customFields custom fields to be passed in error log event
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpdateWithHandling(SObject record, BBApps_ErrorCustomFields customFields) {
        return doUpdateWithHandling(record, true, customFields);
    }
    /**
     * Update records in database with Error Handling
     * @param record
     * @param allOrNone
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpdateWithHandling(SObject record, Boolean allOrNone) {
        return doUpdateWithHandling(record, allOrNone, new BBApps_ErrorCustomFields());
    }
    /**
     * Update records in database with Error Handling
     * @param record
     * @param dmlOptions
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpdateWithHandling(SObject record, Database.DMLOptions dmlOptions) {
        return doUpdateWithHandling(record, dmlOptions, new BBApps_ErrorCustomFields());
    }
    /**
     * Update records in database with Error Handling
     * @param record
     * @param allOrNone
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpdateWithHandling(SObject record, Boolean allOrNone, string functionality) {
        return doUpdateWithHandling(record, allOrNone, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Update records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpdateWithHandling(SObject record, Boolean allOrNone, AccessLevel accessLevel, String functionality) {
        return doUpdateWithHandling(record, allOrNone, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Update records in database with Error Handling
     * @param record
     * @param dmlOptions
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpdateWithHandling(SObject record, Database.DMLOptions dmlOptions, string functionality) {
        return doUpdateWithHandling(record, dmlOptions, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Update records in database with Error Handling, dmlOptions, and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpdateWithHandling(SObject record, Database.DMLOptions dmlOptions, AccessLevel accessLevel, String functionality) {
        return doUpdateWithHandling(record, dmlOptions, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Update records in database with Error Handling
     * @param record
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpdateWithHandling(SObject record, Boolean allOrNone, BBApps_ErrorCustomFields customFields) {
        return doUpdateWithHandling(record, allOrNone, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Update records in database with Error Handling and explicit AccessLevel
     * @param record
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpdateWithHandling(SObject record, Boolean allOrNone, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            BBApps_DMLResult sr = doUpdate(record, allOrNone, accessLevel);
            BBApps_ErrorHandler.logErrors(record, sr, customFields);
            return sr;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(record, e, customFields);
            throw e;
        }
    }
    /**
     * Update records in database with Error Handling
     * @param record
     * @param dmlOptions
     * @param customFields custom fields to be passed in error log event
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpdateWithHandling(SObject record, Database.DMLOptions dmlOptions, BBApps_ErrorCustomFields customFields) {
        return doUpdateWithHandling(record, dmlOptions, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Update records in database with Error Handling, dmlOptions, and explicit AccessLevel
     * @param record
     * @param dmlOptions
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpdateWithHandling(SObject record, Database.DMLOptions dmlOptions, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            BBApps_DMLResult sr = doUpdate(record, dmlOptions, accessLevel);
            BBApps_ErrorHandler.logErrors(record, sr, customFields);
            return sr;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(record, e, customFields);
            throw e;
        }
    }
    /**
     * Update records in database with Error Handling
     * @param records
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpdateWithHandling(List<SObject> records) {
        return doUpdateWithHandling(records, true);
    }
    /**
     * Update records in database with Error Handling
     * @param records
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpdateWithHandling(List<SObject> records, String functionality) {
        return doUpdateWithHandling(records, true, functionality);
    }
    /**
     * Update records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpdateWithHandling(List<SObject> records, AccessLevel accessLevel, String functionality) {
        return doUpdateWithHandling(records, true, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Update records in database with Error Handling
     * @param records
     * @param customFields custom fields to be passed in error log event
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpdateWithHandling(List<SObject> records, BBApps_ErrorCustomFields customFields) {
        return doUpdateWithHandling(records, true, customFields);
    }
    /**
     * Update records in database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpdateWithHandling(List<SObject> records, Boolean allOrNone) {
        return doUpdateWithHandling(records, allOrNone, new BBApps_ErrorCustomFields());
    }
    /**
     * Update records in database all or none with Error Handling
     * @param records
     * @param dmlOptions
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpdateWithHandling(List<SObject> records, Database.DMLOptions dmlOptions) {
        return doUpdateWithHandling(records, dmlOptions, new BBApps_ErrorCustomFields());
    }
    /**
     * Update records in database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpdateWithHandling(List<SObject> records, Boolean allOrNone, String functionality) {
        return doUpdateWithHandling(records, allOrNone, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Update records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpdateWithHandling(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel, String functionality) {
        return doUpdateWithHandling(records, allOrNone, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Update records in database all or none with Error Handling
     * @param records
     * @param dmlOptions
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpdateWithHandling(List<SObject> records, Database.DMLOptions dmlOptions, String functionality) {
        return doUpdateWithHandling(records, dmlOptions, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Update records in database with Error Handling, dmlOptions, and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpdateWithHandling(List<SObject> records, Database.DMLOptions dmlOptions, AccessLevel accessLevel, String functionality) {
        return doUpdateWithHandling(records, dmlOptions, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Update records in database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpdateWithHandling(List<SObject> records, Boolean allOrNone, BBApps_ErrorCustomFields customFields) {
        return doUpdateWithHandling(records, allOrNone, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Update records in database with Error Handling and explicit AccessLevel
     * @param records
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpdateWithHandling(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            List<BBApps_DMLResult> srs = doUpdate(records, allOrNone, accessLevel);
            BBApps_ErrorHandler.logErrors(records, srs, customFields);
            return srs;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(records, e, customFields);
            throw e;
        }
    }
    /**
     * Update records in database all or none with Error Handling
     * @param records
     * @param dmlOptions
     * @param customFields custom fields to be passed in error log event
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpdateWithHandling(List<SObject> records, Database.DMLOptions dmlOptions, BBApps_ErrorCustomFields customFields) {
        return doUpdateWithHandling(records, dmlOptions, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Update records in database with Error Handling, dmlOptions, and explicit AccessLevel
     * @param records
     * @param dmlOptions
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpdateWithHandling(List<SObject> records, Database.DMLOptions dmlOptions, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            List<BBApps_DMLResult> srs = doUpdate(records, dmlOptions, accessLevel);
            BBApps_ErrorHandler.logErrors(records, srs, customFields);
            return srs;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(records, e, customFields);
            throw e;
        }
    }
    /**
     * Delete records in database with Error Handling
     * @param record
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDeleteWithHandling(SObject record) {
        return doDeleteWithHandling(record, true);
    }
    /**
     * Delete records in database with Error Handling
     * @param record
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDeleteWithHandling(SObject record, String functionality) {
        return doDeleteWithHandling(record, true, functionality);
    }
    /**
     * Delete records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDeleteWithHandling(SObject record, AccessLevel accessLevel, String functionality) {
        return doDeleteWithHandling(record, true, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Delete records in database with Error Handling
     * @param record
     * @param customFields custom fields to be passed in error log event
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDeleteWithHandling(SObject record, BBApps_ErrorCustomFields customFields) {
        return doDeleteWithHandling(record, true, customFields);
    }
    /**
     * Delete records in database with Error Handling
     * @param record
     * @param allOrNone
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDeleteWithHandling(SObject record, Boolean allOrNone) {
        return doDeleteWithHandling(record, allOrNone, new BBApps_ErrorCustomFields());
    }
    /**
     * Delete records in database with Error Handling
     * @param record
     * @param allOrNone
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDeleteWithHandling(SObject record, Boolean allOrNone, String functionality) {
        return doDeleteWithHandling(record, allOrNone, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Delete records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDeleteWithHandling(SObject record, Boolean allOrNone, AccessLevel accessLevel, String functionality) {
        return doDeleteWithHandling(record, allOrNone, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Delete records in database with Error Handling
     * @param record
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDeleteWithHandling(SObject record, Boolean allOrNone, BBApps_ErrorCustomFields customFields) {
        return doDeleteWithHandling(record, allOrNone, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Delete records in database with Error Handling and explicit AccessLevel
     * @param record
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDeleteWithHandling(SObject record, Boolean allOrNone, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            BBApps_DMLResult sr = doDelete(record, allOrNone, accessLevel);
            BBApps_ErrorHandler.logErrors(record, sr, customFields);
            return sr;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(record, e, customFields);
            throw e;
        }
    }
    /**
     * Delete records in database with Error Handling
     * @param records
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDeleteWithHandling(List<SObject> records) {
        return doDeleteWithHandling(records, true);
    }
    /**
     * Delete records in database with Error Handling
     * @param records
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDeleteWithHandling(List<SObject> records, String functionality) {
        return doDeleteWithHandling(records, true, functionality);
    }
    /**
     * Delete records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDeleteWithHandling(List<SObject> records, AccessLevel accessLevel, String functionality) {
        return doDeleteWithHandling(records, true, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Delete records in database with Error Handling
     * @param records
     * @param customFields custom fields to be passed in error log event
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDeleteWithHandling(List<SObject> records, BBApps_ErrorCustomFields customFields) {
        return doDeleteWithHandling(records, true, customFields);
    }
    /**
     * Delete records in database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDeleteWithHandling(List<SObject> records, Boolean allOrNone) {
        return doDeleteWithHandling(records, allOrNone, new BBApps_ErrorCustomFields());
    }
    /**
     * Delete records in database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDeleteWithHandling(List<SObject> records, Boolean allOrNone, String functionality) {
        return doDeleteWithHandling(records, allOrNone, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Delete records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDeleteWithHandling(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel, String functionality) {
        return doDeleteWithHandling(records, allOrNone, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Delete records in database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDeleteWithHandling(List<SObject> records, Boolean allOrNone, BBApps_ErrorCustomFields customFields) {
        return doDeleteWithHandling(records, allOrNone, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Delete records in database with Error Handling and explicit AccessLevel
     * @param records
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDeleteWithHandling(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            List<BBApps_DMLResult> srs = doDelete(records, allOrNone, accessLevel);
            BBApps_ErrorHandler.logErrors(records, srs, customFields);
            return srs;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(records, e, customFields);
            throw e;
        }
    }
    /**
     * Delete records in database with Error Handling
     * @param record
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDeleteWithHandling(Id record) {
        return doDeleteWithHandling(record, true);
    }
    /**
     * Delete records in database with Error Handling
     * @param record
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDeleteWithHandling(Id record, String functionality) {
        return doDeleteWithHandling(record, true, functionality);
    }
    /**
     * Delete records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDeleteWithHandling(Id record, AccessLevel accessLevel, String functionality) {
        return doDeleteWithHandling(record, true, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Delete records in database with Error Handling
     * @param record
     * @param customFields custom fields to be passed in error log event
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDeleteWithHandling(Id record, BBApps_ErrorCustomFields customFields) {
        return doDeleteWithHandling(record, true, customFields);
    }
    /**
     * Delete records in database with Error Handling
     * @param record
     * @param allOrNone
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDeleteWithHandling(Id record, Boolean allOrNone) {
        return doDeleteWithHandling(record, allOrNone, new BBApps_ErrorCustomFields());
    }
    /**
     * Delete records in database with Error Handling
     * @param record
     * @param allOrNone
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDeleteWithHandling(Id record, Boolean allOrNone, String functionality) {
        return doDeleteWithHandling(record, allOrNone, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Delete records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDeleteWithHandling(Id record, Boolean allOrNone, AccessLevel accessLevel, String functionality) {
        return doDeleteWithHandling(record, allOrNone, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Delete records in database with Error Handling
     * @param record
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDeleteWithHandling(Id record, Boolean allOrNone, BBApps_ErrorCustomFields customFields) {
        return doDeleteWithHandling(record, allOrNone, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Delete records in database with Error Handling and explicit AccessLevel
     * @param record
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doDeleteWithHandling(Id record, Boolean allOrNone, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            BBApps_DMLResult sr = doDelete(record, allOrNone, accessLevel);
            BBApps_ErrorHandler.logErrors(record, sr, customFields);
            return sr;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(record, e, customFields);
            throw e;
        }
    }
    /**
     * Delete records in database with Error Handling
     * @param records
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDeleteWithHandling(List<Id> records) {
        return doDeleteWithHandling(records, true);
    }
    /**
     * Delete records in database with Error Handling
     * @param records
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDeleteWithHandling(List<Id> records, String functionality) {
        return doDeleteWithHandling(records, true, functionality);
    }
    /**
     * Delete records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDeleteWithHandling(List<Id> records, AccessLevel accessLevel, String functionality) {
        return doDeleteWithHandling(records, true, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Delete records in database with Error Handling
     * @param records
     * @param customFields custom fields to be passed in error log event
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDeleteWithHandling(List<Id> records, BBApps_ErrorCustomFields customFields) {
        return doDeleteWithHandling(records, true, customFields);
    }
    /**
     * Delete records in database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDeleteWithHandling(List<Id> records, Boolean allOrNone) {
        return doDeleteWithHandling(records, allOrNone, new BBApps_ErrorCustomFields());
    }
    /**
     * Delete records in database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDeleteWithHandling(List<Id> records, Boolean allOrNone, String functionality) {
        return doDeleteWithHandling(records, allOrNone, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Delete records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDeleteWithHandling(List<Id> records, Boolean allOrNone, AccessLevel accessLevel, String functionality) {
        return doDeleteWithHandling(records, allOrNone, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Delete records in database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDeleteWithHandling(List<Id> records, Boolean allOrNone, BBApps_ErrorCustomFields customFields) {
        return doDeleteWithHandling(records, allOrNone, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Delete records in database with Error Handling and explicit AccessLevel
     * @param records
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doDeleteWithHandling(List<Id> records, Boolean allOrNone, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            List<BBApps_DMLResult> srs = doDelete(records, allOrNone, accessLevel);
            BBApps_ErrorHandler.logErrors(records, srs, customFields);
            return srs;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(records, e, customFields);
            throw e;
        }
    }
    /**
     * Upsert records in database with Error Handling
     * @param record
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsertWithHandling(SObject record) {
        return doUpsertWithHandling(record, true);
    }
    /**
     * Upsert records in database with Error Handling
     * @param record
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsertWithHandling(SObject record, String functionality) {
        return doUpsertWithHandling(record, true, functionality);
    }
    /**
     * Upsert records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsertWithHandling(SObject record, AccessLevel accessLevel, String functionality) {
        return doUpsertWithHandling(record, true, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Upsert records in database with Error Handling
     * @param record
     * @param customFields custom fields to be passed in error log event
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsertWithHandling(SObject record, BBApps_ErrorCustomFields customFields) {
        return doUpsertWithHandling(record, true, customFields);
    }
    /**
     * Upsert records in database with Error Handling
     * @param record
     * @param allOrNone
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsertWithHandling(SObject record, Boolean allOrNone) {
        return doUpsertWithHandling(record, allOrNone, new BBApps_ErrorCustomFields());
    }
    /**
     * Upsert records in database with Error Handling
     * @param record
     * @param allOrNone
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsertWithHandling(SObject record, Boolean allOrNone, String functionality) {
        return doUpsertWithHandling(record, allOrNone, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Upsert records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsertWithHandling(SObject record, Boolean allOrNone, AccessLevel accessLevel, String functionality) {
        return doUpsertWithHandling(record, allOrNone, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Upsert records in database with Error Handling
     * @param record
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsertWithHandling(SObject record, Boolean allOrNone, BBApps_ErrorCustomFields customFields) {
        return doUpsertWithHandling(record, allOrNone, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Upsert records in database with Error Handling and explicit AccessLevel
     * @param record
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsertWithHandling(SObject record, Boolean allOrNone, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            BBApps_DMLResult sr = doUpsert(record, allOrNone, accessLevel);
            BBApps_ErrorHandler.logErrors(record, sr, customFields);
            return sr;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(record, e, customFields);
            throw e;
        }
    }
    /**
     * Upsert records in database with Error Handling
     * @param records
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsertWithHandling(List<SObject> records) {
        return doUpsertWithHandling(records, true);
    }
    /**
     * Upsert records in database with Error Handling
     * @param records
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsertWithHandling(List<SObject> records, String functionality) {
        return doUpsertWithHandling(records, true, functionality);
    }
    /**
     * Upsert records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsertWithHandling(List<SObject> records, AccessLevel accessLevel, String functionality) {
        return doUpsertWithHandling(records, true, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Upsert records in database with Error Handling
     * @param records
     * @param customFields custom fields to be passed in error log event
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsertWithHandling(List<SObject> records, BBApps_ErrorCustomFields customFields) {
        return doUpsertWithHandling(records, true, customFields);
    }
    /**
     * Upsert records in database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsertWithHandling(List<SObject> records, Boolean allOrNone) {
        return doUpsertWithHandling(records, allOrNone, new BBApps_ErrorCustomFields());
    }
    /**
     * Upsert records in database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsertWithHandling(List<SObject> records, Boolean allOrNone, String functionality) {
        return doUpsertWithHandling(records, allOrNone, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Upsert records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsertWithHandling(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel, String functionality) {
        return doUpsertWithHandling(records, allOrNone, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Upsert records in database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsertWithHandling(List<SObject> records, Boolean allOrNone, BBApps_ErrorCustomFields customFields) {
        return doUpsertWithHandling(records, allOrNone, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Upsert records in database with Error Handling and explicit AccessLevel
     * @param records
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsertWithHandling(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            List<BBApps_DMLResult> srs = doUpsert(records, allOrNone, accessLevel);
            BBApps_ErrorHandler.logErrors(records, srs, customFields);
            return srs;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(records, e, customFields);
            throw e;
        }
    }
    /**
     * Upsert records in database using external field with Error Handling
     * @param record
     * @param field
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsertWithHandling(SObject record, Schema.SObjectField field) {
        return doUpsertWithHandling(record, field, true);
    }
    /**
     * Upsert records in database using external field with Error Handling
     * @param record
     * @param field
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsertWithHandling(SObject record, Schema.SObjectField field, String functionality) {
        return doUpsertWithHandling(record, field, true, functionality);
    }
    /**
     * Upsert records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsertWithHandling(SObject record, Schema.SObjectField field, AccessLevel accessLevel, String functionality) {
        return doUpsertWithHandling(record, field, true, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Upsert records in database using external field with Error Handling
     * @param record
     * @param field
     * @param customFields custom fields to be passed in error log event
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsertWithHandling(SObject record, Schema.SObjectField field, BBApps_ErrorCustomFields customFields) {
        return doUpsertWithHandling(record, field, true, customFields);
    }
    /**
     * Upsert records in database using external field with Error Handling
     * @param record
     * @param field
     * @param allOrNone
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsertWithHandling(SObject record, Schema.SObjectField field, Boolean allOrNone) {
        return doUpsertWithHandling(record, field, allOrNone, new BBApps_ErrorCustomFields());
    }
    /**
     * Upsert records in database using external field with Error Handling
     * @param record
     * @param field
     * @param allOrNone
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsertWithHandling(SObject record, Schema.SObjectField field, Boolean allOrNone, String functionality) {
        return doUpsertWithHandling(record, field, allOrNone, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Upsert records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsertWithHandling(SObject record, Schema.SObjectField field, Boolean allOrNone, AccessLevel accessLevel, String functionality) {
        return doUpsertWithHandling(record, field, allOrNone, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Upsert records in database using external field with Error Handling
     * @param record
     * @param field
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsertWithHandling(SObject record, Schema.SObjectField field, Boolean allOrNone, BBApps_ErrorCustomFields customFields) {
        return doUpsertWithHandling(record, field, allOrNone, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Upsert records in database using external field with Error Handling and explicit AccessLevel
     * @param record
     * @param field
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUpsertWithHandling(SObject record, Schema.SObjectField field, Boolean allOrNone, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            BBApps_DMLResult sr = doUpsert(record, field, allOrNone, accessLevel);
            BBApps_ErrorHandler.logErrors(record, sr, customFields);
            return sr;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(record, e, customFields);
            throw e;
        }
    }
    /**
     * Upsert records in database using external field with Error Handling
     * @param records
     * @param field
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsertWithHandling(List<SObject> records, Schema.SObjectField field) {
        return doUpsertWithHandling(records, field, true);
    }
    /**
     * Upsert records in database using external field with Error Handling
     * @param records
     * @param field
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsertWithHandling(List<SObject> records, Schema.SObjectField field, String functionality) {
        return doUpsertWithHandling(records, field, true, functionality);
    }
    /**
     * Upsert records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsertWithHandling(List<SObject> records, Schema.SObjectField field, AccessLevel accessLevel, String functionality) {
        return doUpsertWithHandling(records, field, true, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Upsert records in database using external field with Error Handling
     * @param records
     * @param field
     * @param customFields custom fields to be passed in error log event
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsertWithHandling(List<SObject> records, Schema.SObjectField field, BBApps_ErrorCustomFields customFields) {
        return doUpsertWithHandling(records, field, true, customFields);
    }
    /**
     * Upsert records in database using external field all or none with Error Handling
     * @param records
     * @param field
     * @param allOrNone
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsertWithHandling(List<SObject> records, Schema.SObjectField field, Boolean allOrNone) {
        return doUpsertWithHandling(records, field, allOrNone, new BBApps_ErrorCustomFields());
    }
    /**
     * Upsert records in database using external field all or none with Error Handling
     * @param records
     * @param field
     * @param allOrNone
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsertWithHandling(List<SObject> records, Schema.SObjectField field, Boolean allOrNone, String functionality) {
        return doUpsertWithHandling(records, field, allOrNone, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Upsert records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsertWithHandling(List<SObject> records, Schema.SObjectField field, Boolean allOrNone, AccessLevel accessLevel, String functionality) {
        return doUpsertWithHandling(records, field, allOrNone, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Upsert records in database using external field all or none with Error Handling
     * @param records
     * @param field
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsertWithHandling(List<SObject> records, Schema.SObjectField field, Boolean allOrNone, BBApps_ErrorCustomFields customFields) {
        return doUpsertWithHandling(records, field, allOrNone, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Upsert records in database using external field with Error Handling and explicit AccessLevel
     * @param records
     * @param field
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUpsertWithHandling(List<SObject> records, Schema.SObjectField field, Boolean allOrNone, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            List<BBApps_DMLResult> srs = doUpsert(records, field, allOrNone, accessLevel);
            BBApps_ErrorHandler.logErrors(records, srs, customFields);
            return srs;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(records, e, customFields);
            throw e;
        }
    }
    /**
     * Undelete records in database with Error Handling
     * @param record
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndeleteWithHandling(SObject record) {
        return doUndeleteWithHandling(record, true);
    }
    /**
     * Undelete records in database with Error Handling
     * @param record
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndeleteWithHandling(SObject record, String functionality) {
        return doUndeleteWithHandling(record, true, functionality);
    }
    /**
     * Undelete records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndeleteWithHandling(SObject record, AccessLevel accessLevel, String functionality) {
        return doUndeleteWithHandling(record, true, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Undelete records in database with Error Handling
     * @param record
     * @param customFields custom fields to be passed in error log event
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndeleteWithHandling(SObject record, BBApps_ErrorCustomFields customFields) {
        return doUndeleteWithHandling(record, true, customFields);
    }
    /**
     * Undelete records in database with Error Handling
     * @param record
     * @param allOrNone
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndeleteWithHandling(SObject record, Boolean allOrNone) {
        return doUndeleteWithHandling(record, allOrNone, new BBApps_ErrorCustomFields());
    }
    /**
     * Undelete records in database with Error Handling
     * @param record
     * @param allOrNone
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndeleteWithHandling(SObject record, Boolean allOrNone, String functionality) {
        return doUndeleteWithHandling(record, allOrNone, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Undelete records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndeleteWithHandling(SObject record, Boolean allOrNone, AccessLevel accessLevel, String functionality) {
        return doUndeleteWithHandling(record, allOrNone, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Undelete records in database with Error Handling
     * @param record
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndeleteWithHandling(SObject record, Boolean allOrNone, BBApps_ErrorCustomFields customFields) {
        return doUndeleteWithHandling(record, allOrNone, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Undelete records in database with Error Handling and explicit AccessLevel
     * @param record
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndeleteWithHandling(SObject record, Boolean allOrNone, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            BBApps_DMLResult sr = doUndelete(record, allOrNone, accessLevel);
            BBApps_ErrorHandler.logErrors(record, sr, customFields);
            return sr;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(record, e, customFields);
            throw e;
        }
    }
    /**
     * Undelete records in database with Error Handling
     * @param records
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndeleteWithHandling(List<SObject> records) {
        return doUndeleteWithHandling(records, true);
    }
    /**
     * Undelete records in database with Error Handling
     * @param records
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndeleteWithHandling(List<SObject> records, String functionality) {
        return doUndeleteWithHandling(records, true, functionality);
    }
    /**
     * Undelete records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndeleteWithHandling(List<SObject> records, AccessLevel accessLevel, String functionality) {
        return doUndeleteWithHandling(records, true, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Undelete records in database with Error Handling
     * @param records
     * @param customFields custom fields to be passed in error log event
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndeleteWithHandling(List<SObject> records, BBApps_ErrorCustomFields customFields) {
        return doUndeleteWithHandling(records, true, customFields);
    }
    /**
     * Undelete records in database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndeleteWithHandling(List<SObject> records, Boolean allOrNone) {
        return doUndeleteWithHandling(records, allOrNone, new BBApps_ErrorCustomFields());
    }
    /**
     * Undelete records in database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndeleteWithHandling(List<SObject> records, Boolean allOrNone, String functionality) {
        return doUndeleteWithHandling(records, allOrNone, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Undelete records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndeleteWithHandling(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel, String functionality) {
        return doUndeleteWithHandling(records, allOrNone, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Undelete records in database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndeleteWithHandling(List<SObject> records, Boolean allOrNone, BBApps_ErrorCustomFields customFields) {
        return doUndeleteWithHandling(records, allOrNone, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Undelete records in database with Error Handling and explicit AccessLevel
     * @param records
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndeleteWithHandling(List<SObject> records, Boolean allOrNone, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            List<BBApps_DMLResult> srs = doUndelete(records, allOrNone, accessLevel);
            BBApps_ErrorHandler.logErrors(records, srs, customFields);
            return srs;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(records, e, customFields);
            throw e;
        }
    }
    /**
     * Undelete records in database with Error Handling
     * @param record
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndeleteWithHandling(Id record) {
        return doUndeleteWithHandling(record, true);
    }
    /**
     * Undelete records in database with Error Handling
     * @param record
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndeleteWithHandling(Id record, String functionality) {
        return doUndeleteWithHandling(record, true, functionality);
    }
    /**
     * Undelete records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndeleteWithHandling(Id record, AccessLevel accessLevel, String functionality) {
        return doUndeleteWithHandling(record, true, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Undelete records in database with Error Handling
     * @param record
     * @param customFields custom fields to be passed in error log event
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndeleteWithHandling(Id record, BBApps_ErrorCustomFields customFields) {
        return doUndeleteWithHandling(record, true, customFields);
    }
    /**
     * Undelete records in database with Error Handling
     * @param record
     * @param allOrNone
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndeleteWithHandling(Id record, Boolean allOrNone) {
        return doUndeleteWithHandling(record, allOrNone, new BBApps_ErrorCustomFields());
    }
    /**
     * Undelete records in database with Error Handling
     * @param record
     * @param allOrNone
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndeleteWithHandling(Id record, Boolean allOrNone, String functionality) {
        return doUndeleteWithHandling(record, allOrNone, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Undelete records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndeleteWithHandling(Id record, Boolean allOrNone, AccessLevel accessLevel, String functionality) {
        return doUndeleteWithHandling(record, allOrNone, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Undelete records in database with Error Handling
     * @param record
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndeleteWithHandling(Id record, Boolean allOrNone, BBApps_ErrorCustomFields customFields) {
        return doUndeleteWithHandling(record, allOrNone, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Undelete records in database with Error Handling and explicit AccessLevel
     * @param record
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `BBApps_DMLResult`
     */
    public static BBApps_DMLResult doUndeleteWithHandling(Id record, Boolean allOrNone, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            BBApps_DMLResult sr = doUndelete(record, allOrNone, accessLevel);
            BBApps_ErrorHandler.logErrors(record, sr, customFields);
            return sr;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(record, e, customFields);
            throw e;
        }
    }
    /**
     * Undelete records in database with Error Handling
     * @param records
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndeleteWithHandling(List<Id> records) {
        return doUndeleteWithHandling(records, true);
    }
    /**
     * Undelete records in database with Error Handling
     * @param records
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndeleteWithHandling(List<Id> records, String functionality) {
        return doUndeleteWithHandling(records, true, functionality);
    }
    /**
     * Undelete records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndeleteWithHandling(List<Id> records, AccessLevel accessLevel, String functionality) {
        return doUndeleteWithHandling(records, true, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Undelete records in database with Error Handling
     * @param records
     * @param customFields custom fields to be passed in error log event
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndeleteWithHandling(List<Id> records, BBApps_ErrorCustomFields customFields) {
        return doUndeleteWithHandling(records, true, customFields);
    }
    /**
     * Undelete records in database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndeleteWithHandling(List<Id> records, Boolean allOrNone) {
        return doUndeleteWithHandling(records, allOrNone, new BBApps_ErrorCustomFields());
    }
    /**
     * Undelete records in database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndeleteWithHandling(List<Id> records, Boolean allOrNone, String functionality) {
        return doUndeleteWithHandling(records, allOrNone, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Undelete records in database with Error Handling and explicit AccessLevel
     * @param accessLevel
     * @param functionality
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndeleteWithHandling(List<Id> records, Boolean allOrNone, AccessLevel accessLevel, String functionality) {
        return doUndeleteWithHandling(records, allOrNone, accessLevel, new BBApps_ErrorCustomFields(functionality));
    }
    /**
     * Undelete records in database all or none with Error Handling
     * @param records
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndeleteWithHandling(List<Id> records, Boolean allOrNone, BBApps_ErrorCustomFields customFields) {
        return doUndeleteWithHandling(records, allOrNone, AccessLevel.SYSTEM_MODE, customFields);
    }
    /**
     * Undelete records in database with Error Handling and explicit AccessLevel
     * @param records
     * @param allOrNone
     * @param customFields custom fields to be passed in error log event
     * @param accessLevel
     * @return `List<BBApps_DMLResult>`
     */
    public static List<BBApps_DMLResult> doUndeleteWithHandling(List<Id> records, Boolean allOrNone, AccessLevel accessLevel, BBApps_ErrorCustomFields customFields) {
        try {
            List<BBApps_DMLResult> srs = doUndelete(records, allOrNone, accessLevel);
            BBApps_ErrorHandler.logErrors(records, srs, customFields);
            return srs;
        }
        catch(Exception e) {
            BBApps_ErrorHandler.logErrors(records, e, customFields);
            throw e;
        }
    }
}