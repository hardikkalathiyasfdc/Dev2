@isTest
public class ListsContactsWithOtherListsCmpTest {
  @isTest
  public static void validateGetData() {
    Id listId = [SELECT Id FROM Campaign LIMIT 1].Id;
    Map<String, Object> config = getConfig();
    Map<String, Object> results = (Map<String, Object>) ListsContactsWithOtherListsCmpController.getData(
      listId,
      (List<String>) config.get('contactFields'),
      (List<String>) config.get('listFields'),
      0
    );
    Integer size = (Integer) results.get('size');
    System.assert(size == 1, 'failed to get data');
  }

  @isTest
  public static void validateGetCSV() {
    Id listId = [SELECT Id FROM Campaign LIMIT 1].Id;
    Map<String, Object> config = getConfig();
    Map<String, Object> result = (Map<String, Object>) ListsContactsWithOtherListsCmpController.getCSV(
      listId,
      (List<String>) config.get('contactFields'),
      (List<String>) config.get('listFields')
    );
    System.assert(
      !String.isBlank((String) result.get('cols')),
      'failed to get csv'
    );
    List<Object> data = (List<Object>) result.get('data');
    System.assert(data.size() == 1, 'failed to get csv');
  }

  private static Map<String, Object> getConfig() {
    return (Map<String, Object>) ListsContactsWithOtherListsCmpController.getConfig();
  }

  @TestSetup
  public static void makeData() {
    Campaign camp = new Campaign(Name = 'test');
    insert camp;
    Contact con = new Contact(LastName = 'test');
    insert con;
    CampaignMember mem = new CampaignMember(
      ContactId = con.Id,
      CampaignId = camp.Id
    );
    insert mem;
  }
}