@isTest
private class ImageSizeReduceCallout_Test {

	public class MockHttpResponseGenerator implements HttpCalloutMock {
	    // Implement this interface method
	    public HTTPResponse respond(HTTPRequest req) {
	        
	        // Create a fake response
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        String imageData = '{"data":"29302320uir0wjfsfjsdoifjosdijfosdijfosdfjsdio"}';
	        res.setBody(imageData);
	        res.setStatusCode(200);
	        return res;
	    }
	}

	@testSetup
	static void dataPrep() {
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        TestDataFactory.createMultipleContacts(acct.Id, 1, true);
        
	}

	@isTest
    static void testCallout() {
    	Contact con1 = [SELECT Id ,Bio_Photo__c FROM Contact LIMIT 1];     
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        ImageSizeReduceCallout.updateReduceImageData(con1.Id);
        Test.stopTest();

        System.assert(String.isNotBlank([SELECT ReducedImage__c,Bio_Photo__c From Contact WHERE Id =: con1.Id][0].Bio_Photo__c));
    }

    @isTest
    static void testCalloutBatch() {
        ImageSizeReduceBatch batch = new ImageSizeReduceBatch();
        batch.query = 'SELECT Id, Bio_Photo__c, ReducedImage__c FROM Contact';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();
    }

    @isTest
    static void testDirectCalloutMethod() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());   
        Test.startTest();
        String result = ImageSizeReduceCallout.callout('https://dummyurl.com');
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals('29302320uir0wjfsfjsdoifjosdijfosdijfosdfjsdio', result);
    }
    
    @isTest
    static void testSchedulableExecution() {
        // Step 1: Create test data
        Contact c  = [SELECT Id ,Bio_Photo__c FROM Contact LIMIT 1];
        
        c.Bio_Photo__c = 'https://example.com/bbrm/test.jpg';
        c.BioPhotoUpdated__c = true;
        update c;
        
        // Step 2: Mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Step 3: Schedule job
        Test.startTest();
        
        String cronExp = '0 0 0 1 1 ? 2099'; // future date
        System.schedule('Test Image Batch Job', cronExp, new ImageSizeReduceBatch());
        
        Test.stopTest();
        
        // Step 4: Verify result
        Contact updated = [SELECT Id, ReducedImage__c, BioPhotoUpdated__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(true, updated.BioPhotoUpdated__c);
    }
}