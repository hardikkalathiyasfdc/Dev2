/**
 * `BBApps_ErrorHandler` is a class used to fire off the `BBApps_Error_Log_Event__e` platform event for processing errors from `Database.SaveResult`, `Database.DeleteResult`, and general Exceptions.
 * @author Marcus Little
 * @since 2024-07-29
 *
 * @group Error Logging Framework
 * @group-content ./customAssets/html/error_logging_framework.html
 */
public without sharing class BBApps_ErrorHandler
{
    /**
     * Logs errors from `BBApps_DMLResult`
     *
     * @param records  `SObject` records that were part of the Database call
     * @param srs dml results returned from the Database call
     * @return  `List<BBApps_DMLResult>`  returns List<BBApps_DMLResult> from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(SObject record, BBApps_DMLResult sr) {
        return logErrors(new List<SObject>{record}, new List<BBApps_DMLResult>{sr});
    }
    /**
     * Logs errors from `BBApps_DMLResult`
     *
     * @param records  `SObject` records that were part of the Database call
     * @param srs dml results returned from the Database call
     * @param customFields custom object containing custom data that's not part of the error logging platform event
     * @return  `List<BBApps_DMLResult>`  returns List<BBApps_DMLResult> from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(SObject record, BBApps_DMLResult sr, BBApps_ErrorCustomFields customFields) {
        return logErrors(new List<SObject>{record}, new List<BBApps_DMLResult>{sr}, customFields);
    }
    /**
     * Logs errors from `List<BBApps_DMLResult>`
     *
     * @param records  `SObject` records that were part of the Database call
     * @param srs dml results returned from the Database call
     * @return  `List<BBApps_DMLResult>`  returns List<BBApps_DMLResult> from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(List<SObject> records, List<BBApps_DMLResult> srs) {
        return logErrors(records ?? new List<SObject>(), srs, new DmlException(), null);
    }
    /**
     * Logs errors from `List<BBApps_DMLResult>`
     *
     * @param records  `SObject` records that were part of the Database call
     * @param srs dml results returned from the Database call
     * @param customFields custom object containing custom data that's not part of the error logging platform event
     * @return  `List<BBApps_DMLResult>`  returns List<BBApps_DMLResult> from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(List<SObject> records, List<BBApps_DMLResult> srs, BBApps_ErrorCustomFields customFields) {
        return logErrors(records ?? new List<SObject>(), srs, new DmlException(), customFields);
    }
    /**
     * Logs errors from `BBApps_DMLResult`
     *
     * @param id  `SObject` Id that were part of the Database call
     * @param sr dml results returned from the Database call
     * @return  `List<BBApps_DMLResult>`  returns List<BBApps_DMLResult> from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(Id id, BBApps_DMLResult sr) {
        return logErrors(new List<Id>{id}, new List<BBApps_DMLResult>{sr});
    }
    /**
     * Logs errors from `BBApps_DMLResult`
     *
     * @param id  `SObject` Id that were part of the Database call
     * @param sr dml results returned from the Database call
     * @param customFields custom object containing custom data that's not part of the error logging platform event
     * @return  `List<BBApps_DMLResult>`  returns List<BBApps_DMLResult> from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(Id id, BBApps_DMLResult sr, BBApps_ErrorCustomFields customFields) {
        return logErrors(new List<Id>{id}, new List<BBApps_DMLResult>{sr}, customFields);
    }
    /**
     * Logs errors from `List<BBApps_DMLResult>`
     *
     * @param ids  `SObject` Ids that were part of the Database call
     * @param srs dml results returned from the Database call
     * @return  `List<BBApps_DMLResult>`  returns List<BBApps_DMLResult> from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(List<Id> ids, List<BBApps_DMLResult> srs) {
        List<SObject> records = new List<SObject>();
        for (Id id : ids ?? new List<Id>()) {
            records.add(id.getSobjectType().newSObject(id));
        }
        return logErrors(records, srs, new DmlException(), null);
    }
    /**
     * Logs errors from `List<BBApps_DMLResult>`
     *
     * @param ids  `SObject` Ids that were part of the Database call
     * @param srs dml results returned from the Database call
     * @param customFields custom object containing custom data that's not part of the error logging platform event
     * @return  `List<BBApps_DMLResult>`  returns List<BBApps_DMLResult> from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(List<Id> ids, List<BBApps_DMLResult> srs, BBApps_ErrorCustomFields customFields) {
        List<SObject> records = new List<SObject>();
        for (Id id : ids ?? new List<Id>()) {
            records.add(id.getSobjectType().newSObject(id));
        }
        return logErrors(records, srs, new DmlException(), customFields);
    }
    /**
     * Logs errors from `List<BBApps_DMLResult>`
     *
     * @param records  `SObject` records that were part of the Database call
     * @param srs dml results returned from the Database call
     * @param e Exception used to get stack trace
     * @param customFields custom object containing custom data that's not part of the error logging platform event
     * @return  `List<BBApps_DMLResult>`  returns List<BBApps_DMLResult> from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(List<SObject> records, List<BBApps_DMLResult> srs, Exception e, BBApps_ErrorCustomFields customFields) {
        String stackTrace = removeDataFromStack(e.getStackTraceString());
        Matcher m = generateMatcher(stackTrace.substringBefore('\n'));

        List<BBApps_Error_Log_Event__e> events = new List<BBApps_Error_Log_Event__e>();

        Integer index = 0;
        for (BBApps_DMLResult sr : srs) {

            if (sr.isSuccess()) {
                continue;
            }

            String errMsg = '';
            for (Database.Error err : sr.getErrors()) {
                errMsg += err.getStatusCode() + ' : ' + err.getMessage() + '\n';
            }

            e.setMessage(errMsg);

            ClassData classData = new ClassData(m, stacktrace, e);

            BBApps_Error_Log_Event__e event = createErrorLogEvent(classData, records != null && records.size() > index ? records[index] : null, customFields);
            events.add(event);

            index++;
        }

        return new BBApps_DMLResultList(EventBus.publish(events)).genResults;
    }
    /**
     * Logs error due to general exception
     *
     * @param record record that triggered the exception if available
     * @param ex thrown exception caught during error handling
     * @return  `List<BBApps_DMLResult>`  returns SaveResult from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(SObject record, Exception ex) {
        return logErrors(new List<SObject> {record}, new List<Exception> {ex}, null);
    }
    /**
     * Logs error due to general exception
     *
     * @param record record that triggered the exception if available
     * @param ex thrown exception caught during error handling
     * @param customFields custom object containing custom data that's not part of the error logging platform event
     * @return  `List<BBApps_DMLResult>`  returns SaveResult from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(SObject record, Exception ex, BBApps_ErrorCustomFields customFields) {
        return logErrors(new List<SObject> {record}, new List<Exception> {ex}, customFields);
    }
    /**
     * Logs error due to general exception
     *
     * @param id record that triggered the exception if available
     * @param ex thrown exception caught during error handling
     * @return  `List<BBApps_DMLResult>`  returns SaveResult from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(Id id, Exception ex) {
        return logErrors(new List<Id> {id}, new List<Exception> {ex});
    }
    /**
     * Logs error due to general exception
     *
     * @param id record that triggered the exception if available
     * @param ex thrown exception caught during error handling
     * @return  `List<BBApps_DMLResult>`  returns SaveResult from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(Id id, Exception ex, BBApps_ErrorCustomFields customFields) {
        return logErrors(new List<Id> {id}, new List<Exception> {ex}, customFields);
    }
    /**
     * Logs error due to general exceptions
     *
     * @param ids records that triggered the exception if available
     * @param exs thrown exceptions caught during error handling
     * @return  `List<BBApps_DMLResult>`  returns SaveResult from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(List<Id> ids, List<Exception> exs) {
        List<SObject> records = new List<SObject>();
        for (Id id : ids ?? new List<Id>()) {
            records.add(id.getSobjectType().newSObject(id));
        }
        return logErrors(records, exs, null);
    }
    /**
     * Logs error due to general exceptions
     *
     * @param ids records that triggered the exception if available
     * @param exs thrown exceptions caught during error handling
     * @return  `List<BBApps_DMLResult>`  returns SaveResult from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(List<Id> ids, List<Exception> exs, BBApps_ErrorCustomFields customFields) {
        List<SObject> records = new List<SObject>();
        for (Id id : ids ?? new List<Id>()) {
            records.add(id.getSobjectType().newSObject(id));
        }
        return logErrors(records, exs, customFields);
    }
    /**
     * Logs error due to general exceptions
     *
     * @param records records that triggered the exception if available
     * @param exs thrown exceptions caught during error handling
     * @return  `List<BBApps_DMLResult>`  returns SaveResult from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(List<SObject> records, List<Exception> exs) {
       return logErrors(records, exs, null);
    }
    /**
     * Logs error due to general exceptions
     *
     * @param records records that triggered the exception if available
     * @param exs thrown exceptions caught during error handling
     * @param customFields custom object containing custom data that's not part of the error logging platform event
     * @return  `List<BBApps_DMLResult>`  returns SaveResult from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(List<SObject> records, List<Exception> exs, BBApps_ErrorCustomFields customFields) {
        List<BBApps_Error_Log_Event__e> events = new List<BBApps_Error_Log_Event__e>();
        for (Exception ex : exs) {
            String stackTrace = removeDataFromStack(ex.getStackTraceString());
            Matcher m = generateMatcher(stackTrace.substringBefore('\n'));
            ClassData classData = new ClassData(m,stackTrace, ex);
            Integer exceptionIndex = exs.indexOf(ex);
            BBApps_Error_Log_Event__e event = createErrorLogEvent(classData, records != null && records.size() > exceptionIndex ? records[exceptionIndex] : null, customFields);
            events.add(event);
        }

        return new BBApps_DMLResultList(EventBus.publish(events)).genResults;
    }
    /**
     * Logs error due to general exceptions
     *
     * @param ids records that triggered the exception
     * @param ex thrown exception caught during error handling
     * @return  `List<BBApps_DMLResult>`  returns SaveResult from publishing platform event
     */
    public static BBApps_DMLResult logErrors(List<Id> ids, Exception ex) {
        List<SObject> records = new List<SObject>();
        for (Id id : ids ?? new List<Id>()) {
            records.add(id.getSobjectType().newSObject(id));
        }
        return logErrors(records, ex);
    }
    /**
     * Logs error due to general exceptions
     *
     * @param ids records that triggered the exception
     * @param ex thrown exception caught during error handling
     * @param customFields custom object containing custom data that's not part of the error logging platform event
     * @return  `List<BBApps_DMLResult>`  returns SaveResult from publishing platform event
     */
    public static BBApps_DMLResult logErrors(List<Id> ids, Exception ex, BBApps_ErrorCustomFields customFields) {
        List<SObject> records = new List<SObject>();
        for (Id id : ids ?? new List<Id>()) {
            records.add(id.getSobjectType().newSObject(id));
        }
        return logErrors(records, ex, customFields);
    }
    /**
     * Logs error due to general exceptions
     *
     * @param records records that triggered the exception
     * @param ex thrown exception caught during error handling
     * @return  `List<BBApps_DMLResult>`  returns SaveResult from publishing platform event
     */
    public static BBApps_DMLResult logErrors(List<SObject> records, Exception ex) {
        return logErrors(records, ex, null);
    }
    /**
     * Logs error due to general exceptions
     *
     * @param records records that triggered the exception
     * @param ex thrown exception caught during error handling
     * @param customFields custom object containing custom data that's not part of the error logging platform event
     * @return  `List<BBApps_DMLResult>`  returns SaveResult from publishing platform event
     */
    public static BBApps_DMLResult logErrors(List<SObject> records, Exception ex, BBApps_ErrorCustomFields customFields) {
        String stackTrace = removeDataFromStack(ex.getStackTraceString());
        Matcher m = generateMatcher(stackTrace.substringBefore('\n'));
        ClassData classData = new ClassData(m,stackTrace, ex);
        BBApps_Error_Log_Event__e event = createErrorLogEvent(classData, records, customFields);
        return new BBApps_DMLResult(EventBus.publish(event));
    }
    /**
     * Logs error due to general exceptions
     *
     * @param ex thrown exception caught during error handling
     * @return  `List<BBApps_DMLResult>`  returns SaveResult from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(Exception ex) {
        return logErrors(new List<SObject>(), new List<Exception>{ex});
    }
    /**
     * Logs error due to general exceptions
     *
     * @param ex thrown exception caught during error handling
     * @param customFields custom object containing custom data that's not part of the error logging platform event
     * @return  `List<BBApps_DMLResult>`  returns SaveResult from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(Exception ex, BBApps_ErrorCustomFields customFields) {
        return logErrors(new List<SObject>(), new List<Exception>{ex});
    }
    /**
     * Logs error due to general exceptions
     *
     * @param exs thrown exceptions caught during error handling
     * @return  `List<BBApps_DMLResult>`  returns SaveResult from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(List<Exception> exs) {
        return logErrors(new List<SObject>(), exs);
    }
    /**
     * Logs error due to general exceptions
     *
     * @param exs thrown exceptions caught during error handling
     * @param customFields custom object containing custom data that's not part of the error logging platform event
     * @return  `List<BBApps_DMLResult>`  returns SaveResult from publishing platform event
     */
    public static List<BBApps_DMLResult> logErrors(List<Exception> exs, BBApps_ErrorCustomFields customFields) {
        return logErrors(new List<SObject>(), exs, customFields);
    }
    /**
     * Creates a `BBApps_Error_Log_Event__e` record
     * @param classData custom class containing stacktrace data
     * @param record record that triggered error if available
     * @param customFields custom object containing custom data that's not part of the error logging platform event
     * @return  `BBApps_Error_Log_Event__e`
     */
    private static BBApps_Error_Log_Event__e createErrorLogEvent(ClassData classData, SObject record, BBApps_ErrorCustomFields customFields) {
        BBApps_Error_Log_Event__e event = new BBApps_Error_Log_Event__e(
            Class__c = classData.ClassName,
            Column__c = classData.Column,
            Created_By_User__c = UserInfo.getUserId(),
            Custom_Data__c = customFields != null ? JSON.serialize(customFields) : null,
            Error_Details__c = classData.errorMsg,
            Error_Type__c = classData.errorType,
            Functionality__c = customFields != null ? customFields.Functionality : null,
            Line_Number__c = classData.LineNumber,
            Method__c = classData.MethodName,
            Object__c = record != null ? record.getSObjectType().getDescribe().getName() : null,
            Record_Id__c = record != null ? record.Id : null,
            Record_JSON__c = record != null ? JSON.serialize(record) : null,
            Stack_Trace__c = classData.stackTrace
        );

        return event;
    }
    /**
     * Creates a `BBApps_Error_Log_Event__e` record
     * @param classData custom class containing stacktrace data
     * @param records records that triggered error if available
     * @param customFields custom object containing custom data that's not part of the error logging platform event
     * @return  `BBApps_Error_Log_Event__e`
     */
    private static BBApps_Error_Log_Event__e createErrorLogEvent(ClassData classData, List<SObject> records, BBApps_ErrorCustomFields customFields) {
        BBApps_Error_Log_Event__e event = new BBApps_Error_Log_Event__e(
            Class__c = classData.ClassName,
            Column__c = classData.Column,
            Created_By_User__c = UserInfo.getUserId(),
            Custom_Data__c = customFields != null ? JSON.serialize(customFields) : null,
            Error_Details__c = classData.errorMsg,
            Error_Type__c = classData.errorType,
            Functionality__c = customFields != null ? customFields.Functionality : null,
            Line_Number__c = classData.LineNumber,
            Method__c = classData.MethodName,
            Object__c = records.getSObjectType() != null ? records.getSObjectType().getDescribe().getName() : null,
            Record_Id__c = null,
            Record_JSON__c = JSON.serialize(records),
            Stack_Trace__c = classData.stackTrace
        );

        return event;
    }
    /**
     * Formats apex class method name
     * @param name name of class method
     * @return  `String`
     */
    private static String prettifyMethodName(String name)  {
        return (name == null) ? null :
            name.replace('<init>', '(constructor) ')
                .replace('__sfdc_', '(getter/setter) ');
    }
    /**
     * Creates a matcher object used to parse stacktrace data
     *
     * @param firstLine line of stacktrace
     * @return  `Matcher`
     */
    private static Matcher generateMatcher(String firstLine) {
        return Pattern.compile(
            '(?i)^(?:class\\.)?([^.]+)\\.?([^\\.\\:]+)?[\\.\\:]?([^\\.\\:]*): line (\\d+), column (\\d+)$'
        ).matcher(firstLine);
    }
    /**
     * removes unnecessary class data from the stack trace
     *
     * @param stackTrace stack trace of error to be modified
     * @return  `string`
     */
    private static string removeDataFromStack(String stackTrace) {
        List<String> newStackTrace = stackTrace.split('\n');

        while (!newStackTrace.isEmpty()) {
            if (newStackTrace.get(0).startsWith('Class.BBApps_Crud.')) {
                newStackTrace.remove(0);
                continue;
            }

            if (newStackTrace.get(0).startsWith('Class.BBApps_ErrorHandler.')) {
                newStackTrace.remove(0);
                continue;
            }

            break;
        }

        System.debug(String.join(newStackTrace, '\n'));
        return String.join(newStackTrace, '\n');
    }
    /** Custom class containing stacktrace data */
    private class ClassData {
        public final String className;
        public final Integer column;
        public final Integer lineNumber;
        public final String methodName;
        public final String stackTrace;
        public final String errorType;
        public final String errorMsg;

        /**
         * Contructor assigns instance variables for object
         *
         * @param m Matcher used to retrieve stacktrace data
         * @param stackTrace complete stacktrace of exception location
         * @param ex exception containing the error data
         */
        ClassData(Matcher m, String stackTrace, Exception ex) {
            m.reset();
            if (m.find())
            {
                if (String.isBlank(m.group(3)))
                {
                    this.className = m.group(1);
                    this.methodName = prettifyMethodName(m.group(2));
                }
                else
                {
                    this.className = m.group(1) + '.' + m.group(2);
                    this.methodName = prettifyMethodName(m.group(3));
                }
                this.lineNumber = Integer.valueOf(m.group(4));
                this.column = Integer.valueOf(m.group(5));
            }

            this.errorMsg = ex.getMessage();
            this.errorType = ex.getTypeName();
            this.stackTrace = stackTrace;
        }
    }
}