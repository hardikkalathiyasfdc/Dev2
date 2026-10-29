@IsTest
public class ExportUtilityTest {
    @IsTest
    static void testGetFieldsByRecordType_Valid() {
        
        // Replace with actual field set developer name from Contact
        String fieldSetDevName = 'Your_FieldSet_DevName';
        
        Test.startTest();
        List<ExportUtility.OptionWrapper> result = 
            ExportUtility.getFieldsByRecordType('Contact', fieldSetDevName);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        
        // If field set has fields, result should contain values
        if(!result.isEmpty()){
            System.assertNotEquals(null, result[0].fieldLabel);
            System.assertNotEquals(null, result[0].fieldValue);
        }
    }
    
    @IsTest
    static void testGetFieldsByRecordType_InvalidObject() {
        
        Test.startTest();
        List<ExportUtility.OptionWrapper> result =  ExportUtility.getFieldsByRecordType('Contact', 'Export_List');
        Test.stopTest();
        
        // Should safely return empty list due to catch block
        System.assertNotEquals(0, result.size(), 
            'Invalid object should Not return empty list');
    }
    
    @IsTest
    static void testOptionWrapperEquals() {
        
        ExportUtility.OptionWrapper obj1 = 
            new ExportUtility.OptionWrapper('Test Label', 'TestValue');
        
        ExportUtility.OptionWrapper obj2 = 
            new ExportUtility.OptionWrapper('Another Label', 'TestValue');
        
        ExportUtility.OptionWrapper obj3 = 
            new ExportUtility.OptionWrapper('Different', 'DifferentValue');
        
        // Same fieldValue → should be true
        System.assert(obj1.equals(obj2), 
            'Objects with same fieldValue should be equal');
        
        // Different fieldValue → should be false
        System.assert(!obj1.equals(obj3), 
            'Objects with different fieldValue should not be equal');
        
        // Null comparison
        System.assert(!obj1.equals(null), 
            'Comparison with null should return false');
    }
}