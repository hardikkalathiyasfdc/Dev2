/**
* Author : Neha Gire
* Date   : 04/12/2024
* Jira   : BRME-5240
* Description : The HTTP Util class provides a set of methods to perform HTTP requests to a given endpoint
* with specified headers, url parameters, and payload. It also allows encoding of url parameters,
* getting the response object, and getting the response headers
*/
public with sharing class CalloutService {
    public enum HTTP_METHOD { GET, POST , DEL , PUT, PATCH }
    public class CalloutException extends Exception {} 
    
    private static final String ERR_CREATE_RESPONSE = 'CALLOUT_SERVICE_CREATE_RESPONSE_FAILED'; 
    
    String endPoint;
    Integer timeout;
    
    public void setEndpoint(String endPoint){
        this.endPoint = endPoint;
    }
    
    public void setTimeOut(Integer timeout){
        this.timeout = timeout;     
    }
    
    public HttpResponse get(Map<String, String> params){
        return call(HTTP_METHOD.GET,params,null);
    }
    public HttpResponse get(Map<String, String> params , Map<String, String> headers){
        return call(HTTP_METHOD.GET,params,headers);
    }
    
    public HttpResponse post(Map<String, String> params ,Map<String, String> headers){
        return call(HTTP_METHOD.POST,params,headers);
    }
    
    public HttpResponse put( Map<String, String> params , Map<String, String> headers){
        return call(HTTP_METHOD.PUT,params,headers);
    }
    
    public HttpResponse del( Map<String, String> params , Map<String, String> headers){
        return call(HTTP_METHOD.DEL,params,headers);
    }
    
    public HttpResponse call(HTTP_METHOD method , Map<String, String> params , Map<String, String> headers){
        return createResponse(method, params, headers, null);
    }
    
    public HttpResponse call(HTTP_METHOD method, String requestBody, Map<String, String> headers){
        return createResponse(method, null, headers, requestBody);
    }   
    
    public HttpResponse createResponse( HTTP_METHOD method, Map<String, String> params, Map<String, String> headers, String requestBody) {
        try{
            if(String.isBlank(endPoint)){
                throw new CalloutException('Error in Callout : Please set endpoint for the callout');
            }
            
            HttpRequest request = new HttpRequest();
            request.setMethod(getRequestMethod(method));
            
            if(timeout != null){
                request.setTimeout(timeout);
            }
            
            if(headers != null){
                setAuthorizationHeader(request , headers);
            }
            request.setEndpoint(getEndpoint(endPoint, params));
            
            if (method == HTTP_METHOD.POST || method == HTTP_METHOD.PUT || method == HTTP_METHOD.PATCH) {
                if (!String.isBlank(requestBody)) {
                    request.setBody(requestBody);
                } else if (params != null && !params.isEmpty()) {
                    request.setBody(createPayload(params));
                }
            }
            
            HttpResponse httpResponse = new Http().send(request);
            return handleResponse(httpResponse);
        } catch (Exception ex) { 
            BBApps_ErrorHandler.logErrors( ex,new BBApps_ErrorCustomFields(ERR_CREATE_RESPONSE) ); 
            throw new CalloutException('Callout failed: ' + ex.getMessage());
        } 
    }
    
    private static HttpResponse handleResponse(HTTPResponse res){
        Integer statusCode = res.getStatusCode();
        if(statusCode == 401 || statusCode == 404 || statusCode == 500){
            throw new CalloutException( 'Error in Callout : ' + statusCode + ' ( ' + res.getStatus() + ' )');
        }
        return res;
    }
    
    private String getRequestMethod(HTTP_METHOD method){
        return method.name() == 'DEL' ? 'DELETE' : method.name();
    }
    
    private void setAuthorizationHeader(HttpRequest httpRequest,Map<String, String> headers){
        if(headers != null && headers.size()>0){
            for(String key :headers.keySet()){
                string val=headers.get(key);
                httpRequest.setHeader(key,val);
            }
        }
    }
    
    private  String createPayload(Map<String, String> urlParams){
        if(urlParams != null && !urlParams.isEmpty()){
            return toUrlParams(urlParams);
        }
        return '';
    }
    
    private  String toUrlParams(Map<String,String> params){
        List<String> paramsList = new List<String>();
        for(String k : params.keySet()){
            String val = params.get(k);
            paramsList.add(k + '=' + (val != null ? EncodingUtil.URLENCODE(params.get(k),'UTF-8') :'' ));
        }
        return String.join(paramsList, '&');
    }
    
    private  String getEndpoint(String endpoint, Map<String, String> urlParams){
        if(urlParams != null && !urlParams.isEmpty()){
            endpoint = endpoint + '?' + toUrlParams(urlParams);
        }
        return endpoint;
    }
    
}