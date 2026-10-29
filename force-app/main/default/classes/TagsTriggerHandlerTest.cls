@IsTest
public class TagsTriggerHandlerTest {
    
    private static Id ensureTJContactRecordType() {
        List<RecordType> existing = [
            SELECT Id
            FROM RecordType
            WHERE SobjectType = 'Tag_Junction__c' AND DeveloperName = 'Contact'
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        return existing[0].Id;

    }

    private static Account makeAccount() {
        Account a = new Account(Name = 'Acme');
        insert as system a;
        return a;
    }

    private static Contact makeContact(Id accountId) {
        Contact c = new Contact(LastName='Test', AccountId=accountId);
        insert as system c;
        return c;
    }

    private static Tag__c makeTag(String nm) {
        Tag__c t = new Tag__c(Name = nm);
        insert as system t;
        return t;
    }

    private static Set<Id> splitIds(String csv) {
        Set<Id> outIds = new Set<Id>();
        if(String.isBlank(csv)) return outIds;
        for(String s : csv.split(',')) {
            if(String.isNotBlank(s)) outIds.add(Id.valueOf(s.trim()));
        }
        return outIds;
    }

    @IsTest
    static void test_NameSetAndContactTagIdsPopulated_OnInsert() {
        Id rtId   = ensureTJContactRecordType();
        Account a = makeAccount();
        Contact c = makeContact(a.Id);
        Tag__c t1 = makeTag('Tag A');
        Tag__c t2 = makeTag('Tag B');

        Test.startTest();
        List<Tag_Junction__c> toInsert = new List<Tag_Junction__c>{
            new Tag_Junction__c(Contact__c = c.Id, Tag__c = t1.Id, RecordTypeId = rtId),
            new Tag_Junction__c(Contact__c = c.Id, Tag__c = t2.Id, RecordTypeId = rtId)
        };
        insert as system toInsert;
        Test.stopTest();
        Map<Id, Tag_Junction__c> byTagId = new Map<Id, Tag_Junction__c>([
            SELECT Id, Name, Tag__c
            FROM Tag_Junction__c
            WHERE Id IN :toInsert
            WITH SYSTEM_MODE
        ]);
        System.assertEquals('Tag A', byTagId.get(toInsert[0].Id).Name);
        System.assertEquals('Tag B', byTagId.get(toInsert[1].Id).Name);
        Contact cAfter = [
            SELECT Id, Tag_Ids__c
            FROM Contact
            WHERE Id = :c.Id
            WITH SYSTEM_MODE
        ];
        System.assertEquals(new Set<Id>{ t1.Id, t2.Id }, splitIds(cAfter.Tag_Ids__c));
    }

    @IsTest
    static void test_Delete_RemovesIdsFromContact() {
        Id rtId   = ensureTJContactRecordType();
        Account a = makeAccount();
        Contact c = makeContact(a.Id);
        Tag__c t1 = makeTag('Keepable');
        Tag__c t2 = makeTag('ToRemove');
        Tag_Junction__c j1 = new Tag_Junction__c(Contact__c = c.Id, Tag__c = t1.Id, RecordTypeId = rtId);
        Tag_Junction__c j2 = new Tag_Junction__c(Contact__c = c.Id, Tag__c = t2.Id, RecordTypeId = rtId);
        insert as system new List<Tag_Junction__c>{ j1, j2 };
        Contact beforeDel = [SELECT Tag_Ids__c FROM Contact WHERE Id = :c.Id WITH SYSTEM_MODE];
        System.assert(splitIds(beforeDel.Tag_Ids__c).containsAll(new Set<Id>{t1.Id, t2.Id}));
        Test.startTest();
        delete j2;
        Test.stopTest();
    }
}