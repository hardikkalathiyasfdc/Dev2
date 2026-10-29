@isTest
global with sharing class FoundationCodeCalloutMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        String resCreateUpdateBody = '{"model_attribute_value":';
        resCreateUpdateBody += '{';
        resCreateUpdateBody += '    "id":10259237,';
        resCreateUpdateBody += '    "description":"Government Innovation",';
        resCreateUpdateBody += '    "value":"Government Innovation",';
        resCreateUpdateBody += '    "model_attribute_id":240763,';
        resCreateUpdateBody += '    "migrate_id":"7X00001GxekeUAB",';
        resCreateUpdateBody += '    "retired":1,';
        resCreateUpdateBody += '    "migrate_source_name":"BRM"';
        resCreateUpdateBody += ' }';
        resCreateUpdateBody += '    }';

        /*String resUpdateBody = '{"records":{ "model_attribute_value":[';
        resUpdateBody += '{';
        resUpdateBody += '    "id":10259237,';
        resUpdateBody += '    "description":"Government Innovation",';
        resUpdateBody += '    "value":"Government Innovation",';
        resUpdateBody += '    "model_attribute_id":240763,';
        resUpdateBody += '    "migrate_id":"7X00001GxekeUAB",';
        resUpdateBody += '    "retired":1,';
        resUpdateBody += '    "migrate_source_name":"BRM"';
        resUpdateBody += ' }';
        resUpdateBody += '  ]';
        resUpdateBody += '    },';
        resUpdateBody += '    "total_pages":1,';
        resUpdateBody += '     "total_entries":1,';
        resUpdateBody += '    "current_page":1,';
        resUpdateBody += '    "per_page":1000';
        resUpdateBody += '    }';*/

        String resBody = '{"records":{ "model_attribute_value":[';
        resBody += '{';
        resBody += '    "id":10259237,';
        resBody += '    "description":"Government Innovation",';
        resBody += '    "value":"Government Innovation",';
        resBody += '    "model_attribute_id":240763,';
        resBody += '    "migrate_id":"7X00001GxekeUAB",';
        resBody += '    "retired":0,';
        resBody += '    "migrate_source_name":"BRM"';
        resBody += ' },';
        resBody += ' {';
        resBody += '    "id":10259238,';
        resBody += '    "description":"Government Innovation",';
        resBody += '    "value":"Government Innovation",';
        resBody += '    "model_attribute_id":240763,';
        resBody += '    "migrate_id":"7X00000GxekeUAB",';
        resBody += '    "retired":0';
        resBody += ' }';
        resBody += '  ]';
        resBody += '    },';
        resBody += '    "total_pages":1,';
        resBody += '     "total_entries":1,';
        resBody += '    "current_page":1,';
        resBody += '    "per_page":1000';
        resBody += '    }';
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');
        if(req.getMethod() == 'POST' || req.getMethod() == 'PUT' || req.getMethod() == 'GET'){
            res.setBody(resCreateUpdateBody);
        }
        /*else if(req.getMethod() == 'GET') {
            res.setBody(resUpdateBody);
        }*/
        res.setStatusCode(200);
        return res;
    }
}