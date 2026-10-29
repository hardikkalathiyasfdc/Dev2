/**
* Author : Neha Gire
* Date   : 04/12/2024
* Jira   : BRME-5240
* Description : This class provides a interface for set of methods to perform HTTP requests for Fluxx / BGive APIs.
* Test : BGiveApiTest
*/
public abstract class BGiveApi{
    public class BGiveCalloutException extends Exception {} 
    static Integer PAGE_SIZE_DEFAULT = 20;
    static Integer PAGE_SIZE_MAX = 10000;
    static Integer PAGE_DEFAULT = 1;
    protected String COLS_DEFAULT = '["id","contig_id"]'; 
   
    protected List<String> requiredCols; // Mandatory field for which data has to be present while creating / updating the record in BGive.
    protected List<String> immutableCols;  // List of fields for which data should not be changed in case of update.

    private static String FLUXX_NAMED_CRED;  // set value based on environment . create util method 
    private static String FLUXX_USER_ID;// set based on env;
    private String model = ''; // Object in BGive
    private String reponseModelKey = ''; // Object in BGive
    private String endPoint = '';
    Integer pageSize;
    Integer page;
    String filters;
    String sortConditions; // add sort condition in url params in format : ["field" : "order"]
    Map<String,String> nonESFilters;
    Map<String,Object> relationCols;

    private static final String ERR_BGIVE_COL_VALIDATION = 'BGIVE_COL_VALIDATION_FAILED';
    private static final String ERR_BGIVE_HANDLE_RESPONSE = 'BGIVE_HANDLE_RESPONSE_FAILED';
    private static final String ERR_BGIVE_SET_ENDPOINT = 'BGIVE_SET_ENDPOINT_FAILED';
    private static final String ERR_BGIVE_GET_ALL = 'BGIVE_GET_ALL_FAILED';
    private static final String ERR_BGIVE_GET_DATA = 'BGIVE_GET_DATA_FAILED';
    private static final String ERR_BGIVE_SET_ENV_ATTRIBUTES = 'BGIVE_SET_ENV_ATTRIBUTES_FAILED';

    // abstract method for set model
    public abstract String getModel();

    public virtual void setResponseKey(String reponseModelKey){
        this.reponseModelKey = reponseModelKey != null ? reponseModelKey : model;
    }
    
    public BGiveApi(){
        requiredCols = new List<String>(); 
        setBGiveEnvAttributes();
        setEndpoint();
        setResponseKey(model);
    }
    
    public BGiveApi(String reponseModelKey){
        requiredCols = new List<String>(); 
        setBGiveEnvAttributes();
        setEndpoint();
        setResponseKey(reponseModelKey);
    }


    private void setBGiveEnvAttributes(){
        Map<String, Object> envAttributeMap = Environment.getEnvironmentSetting(new List<String>{'Fluxx_User_Id__c', 'Fluxx_Named_Credential__c'});
        if(envAttributeMap != null ){
            if(envAttributeMap.get('Fluxx_User_Id__c') == null){
                String errorMessage = 'BGive API named credential is not configured in Environment Setting.';
                BBApps_ErrorHandler.logErrors(new BGiveCalloutException(errorMessage), new BBApps_ErrorCustomFields(ERR_BGIVE_SET_ENV_ATTRIBUTES));
                throw new BGiveCalloutException(errorMessage);
            }
            FLUXX_NAMED_CRED = String.valueOf(envAttributeMap.get('Fluxx_Named_Credential__c'));
            FLUXX_USER_ID = String.valueOf(envAttributeMap.get('Fluxx_User_Id__c'));
        }
        
    }

    public void setPage(Integer page){
        this.page = page;
    }

    public void setPageSize(Integer pageSize){
        this.pageSize = pageSize;
    }
    
    public void setPageSizeMax(){
        this.pageSize = PAGE_SIZE_MAX;
    }

    public void setFilters(String filters){
        this.filters = filters;
    }

    // Non Elastic Seacrh - add comment.
    public void setNonEsFilters(Map<String,String> filters){
        this.nonESFilters = filters;
    }

    public void setSortConditions(String sortConditions){
        this.sortConditions = sortConditions;
    }

    public void setRelationColumns(Map<String,Object> relationCols){
        this.relationCols = relationCols;
    }

    /**
     * String Model : Table Name from BGive.
     * List<String> cols : List of table column names to retrive.
     * Integer pageSize (Optional): How many number of records to get per page.
     * 
     * Usage : BGiveAPIUtil.get('BGiveTableName' , new List<String>{'col1','col2','id'} ,{2000} );
     * 
     */
   
    public Object get(List<String> cols){
        Map<String,String> urlParams = new Map<String,String>();
        urlParams.put('page' , '' + (page ?? PAGE_DEFAULT));
        urlParams.put('per_page' , '' + (pageSize ?? PAGE_SIZE_DEFAULT));
        urlParams.put('cols' , getColumnString(cols)); // get default if not present
        if(relationCols != null && !relationCols.isEmpty()){
             urlParams.put('relation' , JSON.serialize(relationCols)); 
        }
        if(!String.isBlank(filters)){
            urlParams.put('filter' , filters ?? '');
        }else if(nonESFilters != null && !nonESFilters.isEmpty()){
            addNonEsFilters(urlParams);
        }
        if(!String.isBlank(sortConditions)){
            urlParams.put('sort' , sortConditions ?? '[]');
        }
        CalloutService callout = new CalloutService();
        callout.setEndpoint(endPoint);
        HttpResponse res = callout.get(urlParams);
        return handleResponse(res , model); 
    }

    public Object get(){
        return get(null);
    }

    /**
     * This method is responsible for getting all data from BGive for given object.
     * Limit is enforced on data retrived based on Max Number of pages.
     * This method will be implemented in future when needed.
     */

    public BGiveAPIResponse getAll(List<String> cols){ 
        BBApps_ErrorHandler.logErrors(new BGiveCalloutException('GetAll operation is not supported.'), new BBApps_ErrorCustomFields(ERR_BGIVE_GET_ALL));
        throw new BGiveCalloutException('GetAll operation is not supported.');
    }

    private void addNonEsFilters(Map<String,String> urlParams){
        for(String field : nonESFilters.keySet()){
            urlParams.put('filter['+model+']['+field+']' , ''+ ( nonESFilters.get(field) ?? ''));
        }
    }

    /**
     * String Model : Table Name from BGive.
     * List<String> cols : List of table column names to retrive.
     * Integer pageSize (Optional): How many number of records to get per page.
     * 
     * Usage : BGiveAPIUtil.fetch(recordId , new List<String>{'col1','col2','id'} ,{2000} );
     * 
     */
    public Object fetch(String bgiveId , List<String> cols){
        endpoint += '/' + bgiveId;
        Map<String,String> urlParams = new Map<String,String>();
        urlParams.put('cols' , getColumnString(cols));

        CalloutService callout = new CalloutService();
        callout.setEndpoint(endPoint);

        HttpResponse res = callout.get(urlParams);
        return handleResponse(res , model); 
    }

     /**
     * String Model : Table Name from BGive.
     * String data : JSON data to update / create record in BGive.
     * List<String> cols : List of table column names to retrive.
     * 
     * Usage : BGiveAPIUtil.create('BGiveTableName','{"col1" : true , "col2":"value2","col3":value3}' , new List<String>{'col1','col2','id'});
     */
    public Object create(Map<String,Object> data, List<String> cols){
        Map<String,String> payloadMap = new Map<String,String>();
        payloadMap.put('data' , getDataString(data , true)); // updated_by_id; created_by_id; // set based on env if not given
        payloadMap.put('cols' , getColumnString(cols));
        CalloutService callout = new CalloutService();
        callout.setEndpoint(endPoint);
        HttpResponse res = callout.post(payloadMap , null);
        return handleResponse(res , model); 
    }

     /**
     * String Model : Table Name from BGive.
     * String entityId : Id of record to update in BGive
     * String data : JSON data to update / create record in BGive.
     * List<String> cols : List of table column names to retrive.
     * 
     * Usage : BGiveAPIUtil.modify('BGiveTableName','recordId','{"col1" : "value1" , "col2":"value2","col3":value3}' , new List<String>{'col1','col2','id'});
     */
    public Object modify(String bgiveId , Map<String,Object> data, List<String> cols){
        endpoint += '/'+ bgiveId;
        Map<String,String> payloadMap = new Map<String,String>();
        payloadMap.put('data' , getDataString(data , false));
        payloadMap.put('cols' , getColumnString(cols));
        CalloutService callout = new CalloutService();
        callout.setEndpoint(endPoint);
        HttpResponse res = callout.put( payloadMap , null );
        return handleResponse(res , model); 
    }

    private void setEndpoint(){
        model = getModel();
        if(String.isEmpty(model)){
            BBApps_ErrorHandler.logErrors(new BGiveCalloutException('Please specify model to perform operartion'), new BBApps_ErrorCustomFields(ERR_BGIVE_SET_ENDPOINT));
            throw new BGiveCalloutException('Please specify model to perform operartion');
        }
        endpoint =  'callout:'+FLUXX_NAMED_CRED+'/api/rest/'+Assets.FLUXX_API_VERSION+'/'+model; 
          
    }

    private String getColumnString(List<String> cols){
        if(cols != null && !cols.isEmpty() ){
            return '["' + String.join(new List<String>(cols), '","') + '"]';
        }
        return COLS_DEFAULT;
    }

    private String getDataString(Map<String,Object> dataMap, Boolean isCreate){
        if(!dataMap.isEmpty()){
            validateRequiredCols(dataMap , isCreate);
            dataMap.put('updated_by_id',FLUXX_USER_ID);
            if(isCreate){
                dataMap.put('created_by_id',FLUXX_USER_ID);
            }
            return JSON.serialize(dataMap);
        }
        BBApps_ErrorHandler.logErrors(new BGiveCalloutException('Please provide data to be updated.'), new BBApps_ErrorCustomFields(ERR_BGIVE_GET_DATA));
        throw new BGiveCalloutException('Please provide data to be updated.');
    }

    private void validateRequiredCols(Map<String,Object> dataMap , Boolean isCreate){
        if(!requiredCols.isEmpty()){
            for(String col : requiredCols){ // add null check for create
                if( (isCreate && !dataMap.containsKey(col)) || (!isCreate && dataMap.containsKey(col) && dataMap.get(col) == null) ){
                    String errorMessage = 'Please provide data for mandatory columns : '+col;
                    BBApps_ErrorHandler.logErrors(new BGiveCalloutException(errorMessage), new BBApps_ErrorCustomFields(ERR_BGIVE_COL_VALIDATION));
                    throw new BGiveCalloutException(errorMessage);
                }
            }
        }
    }
    public virtual Object handleResponse(HTTPResponse res, String model){
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        
        if(responseMap.containsKey('error')){
            Map<String, Object> errorMap = (Map<String, Object>)responseMap.get('error');
            String errorMessage = 'BGive Callout Error : ' +errorMap?.get('message') + ' ( Code : '+ errorMap?.get('code') + ' )';
            BBApps_ErrorHandler.logErrors(new BGiveCalloutException(errorMessage), new BBApps_ErrorCustomFields(ERR_BGIVE_HANDLE_RESPONSE));
            throw new BGiveCalloutException(errorMessage);
        }else{
            return getBGiveReponse(responseMap , model);
        }
    }

    private Object getBGiveReponse(Map<String, Object> responseMap, String model){
        if(responseMap.get('records') != null){
            BGiveAPIListResponse bgiveResponse = new BGiveAPIListResponse(responseMap, model, reponseModelKey);
            return bgiveResponse;
        }else{
            BGiveAPIResponse bgiveResponse = new BGiveAPIResponse(responseMap, model);
            return bgiveResponse;
        }
    }

    public class BGiveAPIResponse{
        public Object record;
        public BGiveAPIResponse(Map<String,Object> response , String model){
            this.record = response.get(model);
        }
    }


    public class BGiveAPIListResponse{ 
        public List<Object> records;
        public PageInfo pageInfo;
        public BGiveAPIListResponse(Map<String,Object> response , String model , String reponseModelKey){
            this.records = response.get('records') != null ? (List<Object>)((Map<String,Object>)(response.get('records'))).get(reponseModelKey) : new List<Object>();
            this.pageInfo = new PageInfo(response);
         
        }
    }

    public class PageInfo{
        public Integer total_pages;
        public Integer total_entries;
        public Integer current_page;
        public Integer per_page;

        public PageInfo(Map<String,Object> response) {
            this.total_pages = response.get('total_pages') != null ? Integer.valueOf(response.get('total_pages')) : null;
            this.total_entries = response.get('total_entries') != null ? Integer.valueOf(response.get('total_entries')) : null;
            this.current_page = response.get('current_page') != null ? Integer.valueOf(response.get('current_page')) : null;
            this.per_page = response.get('per_page') != null ? Integer.valueOf(response.get('per_page')) : null;
           
        }
    }
}