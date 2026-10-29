/**
* Author : Neha Gire
* Date   : 04/12/2024
* Jira   : BRME-5240
* Description : This is the batch class to sync give foundation codes with BGive
* Test : BatchFoundationCodeSyncTest
*/

public with sharing class BatchFoundationCodeSync implements Database.Batchable<sObject> , Database.Stateful , Database.AllowsCallouts{

    public String query;
    public Map<String , Map<String,Object>> bGiveCodesByName;
    public Map<String , Map<String,Object>> bGiveCodesByExtId;

    public Map<String , List<Foundation_Code__c>> brmCodesByName;
    public List<String> modelAttributeIds;
    List<Id> codeIds;
    Boolean syncAll;
    List<String> topLevelCodes = new List<String>{'Initiatives','Non Initiatives'};
    Map<String , Set<String>> processedCodesByModelAttr = new Map<String , Set<String>>();
    public BatchFoundationCodeSync(List<Id> codeIds) {
        this.codeIds = codeIds;
        query = 'SELECT BGive_Description__c, BGive_ID__c, Enabled_For_Associations_Interactions__c, Enabled_for_Grants__c, Enabled_for_Fundraising__c, Sort_Order__c,'+
                'Foundation_Code__c, Name, Parent__r.BGive_ID__c, Parent__r.BGive_Migrate_Id__c, Status__c, Level_0__c, Parent__r.Name , Parent__r.Foundation_Code__c , BGive_Migrate_Id__c, Sync_Error__c, Sync_Warning__c, Is_Sync_Error__c  '+
                'FROM Foundation_Code__c ';

        if(codeIds != null && !codeIds.isEmpty()){
            query += 'WHERE Id IN :codeIds AND Foundation_Code__c NOT IN :topLevelCodes';
            syncAll = false;
        }else{
            syncAll = true;
            query += 'WHERE Foundation_Code__c NOT IN :topLevelCodes';
        }
        query += ' ORDER BY Code_Level__c ASC';

        bGiveCodesByName = new Map<String , Map<String,Object>> ();
        bGiveCodesByExtId = new Map<String , Map<String,Object>> ();
    }

    public Database.QueryLocator start (Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute (Database.BatchableContext bc, List<Foundation_Code__c> codes) {

        FoundationCodeService service = new FoundationCodeService();
        try{
            getMatchingCodeByName(codes);
            initializeData(service);

            System.debug(bGiveCodesByExtId);
            System.debug(brmCodesByName);

            for( Foundation_Code__c code : codes){

                if(code.Level_0__c == 'Non Initiatives') continue;

                code.Sync_Error__c = '';
                code.Sync_Warning__c = '';
                code.Is_Sync_Error__c = false;
                service.addCodesToUpdateList(code);

                if(modelAttributeIds != null){
                    for(String modelAttributeId : modelAttributeIds){
                        System.debug('>> modelAttributeId : '+modelAttributeId);
                        FoundationCodeService.ModelAttributeValue bGiveCodeName;
                        System.debug(' >> BRM Codes : '+code.Foundation_Code__c + ' : '+brmCodesByName.get(code.Foundation_Code__c));


                        String codeExtId = code.BGive_Migrate_Id__c;
                        System.debug(' >> ExtId : '+codeExtId );
                        FoundationCodeService.ModelAttributeValue bGiveCodeExtId;
                        if(codeExtId != null){
                            System.debug('BGIVE ext Code : '+bGiveCodesByExtId.get(modelAttributeId)?.get(codeExtId));
                            bGiveCodeExtId = (FoundationCodeService.ModelAttributeValue) (bGiveCodesByExtId.get(modelAttributeId)?.get(codeExtId));
                        }

                        if(bGiveCodeExtId == null && brmCodesByName.containsKey(code.Foundation_Code__c)){
                            if(brmCodesByName.get(code.Foundation_Code__c).size() <= 1){
                                List<Object> bGiveCodes  =  (List<Object>) bGiveCodesByName.get(modelAttributeId)?.get(code.Foundation_Code__c);
                                System.debug(' >> BGive Codes : '+code.Foundation_Code__c + ' : '+bGiveCodes);
                                if(bGiveCodes != null && bGiveCodes.size() == 1){
                                    bGiveCodeName = (FoundationCodeService.ModelAttributeValue) (bGiveCodes[0]);
                                }else if(bGiveCodes != null && bGiveCodes.size() > 1){
                                    code.Sync_Warning__c = 'Duplicate BGive Code Exists.';
                                    code.Is_Sync_Error__c = true;
                                    continue;
                                }
                                System.debug(' >> BGive Code By name : '+bGiveCodeName );

                            }

                        }

                        // if matching code found in bgive either using name or external id
                        if(syncAll && ( brmCodesByName.containsKey(code.Foundation_Code__c) && bGiveCodeExtId != null )){
                            processedCodesByModelAttr.get(modelAttributeId)?.add(code.Foundation_Code__c);
                            processedCodesByModelAttr.get(modelAttributeId)?.add(codeExtId);
                        }

                        System.debug(' >> bGiveCodeExtId : '+ bGiveCodeExtId );

                        service.sync(modelAttributeId, bGiveCodeExtId, bGiveCodeName, code);
                    }
                }
            }

            service.updateCodes();
        }catch(Exception e){
            FoundationCodeUtil.createLog('', e.getMessage() + '\n' +e.getStackTraceString(), true);
        }
    }

    private void initializeData(FoundationCodeService service){

        if(modelAttributeIds == null || modelAttributeIds.isEmpty()){
            modelAttributeIds = FoundationCodeUtil.getModelAttributes();
        }

        if(bGiveCodesByName.isEmpty()){
            if(modelAttributeIds != null){
                for(String modelAttributeId : modelAttributeIds){
                    Map<String,String> filters = new Map<String,String>();
                    filters.put('model_attribute_id' , modelAttributeId);
                    List<FoundationCodeService.ModelAttributeValue> modelAttrValues = FoundationCodeUtil.getAllBGiveCodes(filters);
                    setBGiveCodeMap(modelAttrValues , modelAttributeId);
                    processedCodesByModelAttr.put(modelAttributeId ,new Set<String>());
                }
            }
        }
    }

    private void getMatchingCodeByName(List<Foundation_Code__c> codes){
        brmCodesByName = new Map<String, List<Foundation_Code__c>>();

        List<String> foundationCodeNames = new List<String>();

        for(Foundation_Code__c code : codes){
            if(!String.isBlank(code.Foundation_Code__c)){
                foundationCodeNames.add(code.Foundation_Code__c);
            }
        }

        if(!foundationCodeNames.isEmpty()){
            for( Foundation_Code__c code : [SELECT Id,Foundation_Code__c FROM Foundation_Code__c WHERE Foundation_Code__c IN :foundationCodeNames]){
                if(!brmCodesByName.containsKey(code.Foundation_Code__c))
                    brmCodesByName.put(code.Foundation_Code__c, new List<Foundation_Code__c>());

                brmCodesByName.get(code.Foundation_Code__c).add(code);
            }
        }
    }
    private void setBGiveCodeMap(List<FoundationCodeService.ModelAttributeValue> codes , String modelAttributeId){

        if(codes != null){
            Map<String , List<Object>> bGiveCodeMapByName = new Map<String , List<Object>>();
            Map<String , Object> bGiveCodeMapByExtId = new Map<String , Object>();
            for(FoundationCodeService.ModelAttributeValue attr : codes){
                if(!bGiveCodeMapByName.containsKey(attr.value)){
                    bGiveCodeMapByName.put(attr.value , new List<Object>());
                }
                bGiveCodeMapByName.get(attr.value).add(attr);
                bGiveCodeMapByExtId.put(attr.migrate_id , attr);
                System.debug('Migrate Id : '+attr.migrate_id);
                System.debug('Attr : '+attr);
            }

            bGiveCodesByName.put(modelAttributeId , bGiveCodeMapByName);
            bGiveCodesByExtId.put(modelAttributeId , bGiveCodeMapByExtId);
        }
    }

    public void finish (Database.BatchableContext bc){

      System.debug(' >> SyncAll'+syncAll);
      // update unprocessed Bgive Code as retired , if syncAll is performed.
      if(syncAll && bGiveCodesByExtId != null){
            for( String  modelAttributeId : bGiveCodesByExtId.keySet()){
                for(String extId : bGiveCodesByExtId.get(modelAttributeId).keySet()){
                    FoundationCodeService.ModelAttributeValue bgiveCode = (FoundationCodeService.ModelAttributeValue) (bGiveCodesByExtId.get(modelAttributeId)?.get(extId));
                    if( !processedCodesByModelAttr.get(modelAttributeId)?.contains(extId) && !processedCodesByModelAttr.get(modelAttributeId)?.contains(bgiveCode.value)){
                       try{
                        FoundationCodeService.retireBGiveCode(bgiveCode);
                       }catch(Exception e){
                            FoundationCodeUtil.createLog(bgiveCode.value, e.getMessage(), true);
                       }
                    }
                }
            }
      }
    }
}