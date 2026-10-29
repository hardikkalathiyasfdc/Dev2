/**
* Author      : Hardik Kalathiya
* Date        : 03/10/2025
* Jira        : BRME-5776, 5777, 5768, 5769, 5772, 5774, 5775, 6366
* Description : Handles data retrieval & formatting for city-level details, Recent Mayors, City-State-Country Level Work, Bloomberg Offices, Key Partners, Office-Map and Highlights for display in CityView
* Test        : CityViewDetailPageControllerTest
*/

public with sharing class CityViewDetailPageController {

    // Recent Mayors
    @AuraEnabled
    public static List<Employment_History_and_Board_Membership__c> getRecentMayors(String geoAreaId) {
        return [
            SELECT Id, From__c, To__c, Contact_Name__r.Name, Contact_Name__c, Role__c, Organization_Name__r.Government_Geo_Area__c
            FROM Employment_History_and_Board_Membership__c
            WHERE Role__c = 'Mayor'
            AND From__c != NULL
            AND Contact_Name__r.Restricted__c = false
            AND Organization_Name__r.Government_Geo_Area__c = :geoAreaId
            WITH SECURITY_ENFORCED
            ORDER BY From__c ASC
        ];
    }

    // CityStateNational Level work
    @AuraEnabled(cacheable = true)
    public static Boolean showStateLevelData(String geoAreaId){
        Boolean isCountrySelected;
        Boolean isStateSelected;
        List<Geo_Area__c> geoArea = [
            SELECT ID, Parent__c, Recordtype.Name, Parent__r.Parent__c, Parent__r.Parent__r.BP_Uses_States__c, BP_Uses_States__c
            FROM Geo_Area__c
            WHERE Id = :geoAreaId
            AND Deleted__c = false
            AND BP_Active__c = true
            LIMIT 1
        ];

        Boolean showStateWork = false;
        if(!geoArea.isEmpty()) {
            if(geoArea[0].Recordtype.Name == Assets.GEOAREARECORDTYPECOUNTRY ){
                showStateWork = geoArea[0].BP_Uses_States__c;
            } else if(geoArea[0].Recordtype.Name == Assets.GEOAREARECORDTYPESTATE){
                showStateWork = true;
            } else{
                showStateWork = (geoArea[0].Parent__r != null && geoArea[0].Parent__r.Parent__r != null)
                    ? geoArea[0].Parent__r.Parent__r.BP_Uses_States__c : false;
            }
        }
        return showStateWork;
    }

    public static Map<String, Boolean> prepareConsecutive( List<Org_Association__c> orgAssociationList)
    {
        Map<String, Boolean> nonConsecutiveMap = new Map<String, Boolean>();
        Map<String ,Org_Association__c> orgAssociationMap = new Map<String ,Org_Association__c>();
        Id prevAssocId;
        Date prevToDate;
        for(Org_Association__c curr : orgAssociationList) {
            if(curr.RecordType.DeveloperName != 'Grant'){
                String associationKey = ''+curr.Association__r.CityView_Name_Override__c + curr.Association__r.Name+ curr.Organization__r.Government_Geo_Area__c;
                if(!orgAssociationMap.containskey(associationKey)){
                    orgAssociationMap.put(associationKey,curr);
                }else{
                    prevToDate = orgAssociationMap.get(associationKey).To__c;
                    // If current From__c > previous To__c + 1 day ⇒ Non-Consecutive
                    if(prevToDate != null && curr.From__c != null && curr.From__c.year() - prevToDate.year()>1) {
                        nonConsecutiveMap.put(associationKey, true);
                    }
                    // Keep max To__c as reference
                    if(curr.To__c != null && (prevToDate == null || curr.To__c > prevToDate)) {
                        prevToDate = curr.To__c;
                    }
                }
            }
        }
        return nonConsecutiveMap;
    }


    @AuraEnabled(cacheable = true)
    public static List<OrgAssociationWrapper> getCityLevelWork(String geoAreaId) {
        Map<String, String> focusAreaStyles = new Map<String, String>();
        Map<String, String> focusAreaColors = new Map<String, String>();
        // Fetch all focus areas and map their names to style and color codes
        for(Focus_Area__c fa : [SELECT Id, Name, Color_Code__c FROM Focus_Area__c]) {
            String updatedCss = 'border-left:10px solid ' + fa.Color_Code__c + ' !important; padding:10px;';
            focusAreaStyles.put(fa.Name, updatedCss);
            focusAreaColors.put(fa.Name, fa.Color_Code__c);
        }
        // Determine if city is using state-level data and get parent Geo Area references
        List<Geo_Area__c> geoArea = [
            SELECT ID, Parent__c, Recordtype.Name, Parent__r.Parent__c, Parent__r.Parent__r.BP_Uses_States__c,BP_Uses_States__c
            FROM Geo_Area__c
            WHERE Id = :geoAreaId
            AND Deleted__c = false
            AND BP_Active__c = true
            LIMIT 1
        ];
        Id stateGeoAreaId, countryGeoAreaId;
        Boolean showStateWork = false;
        List<Id> geoAreaIds = new List<Id>{geoAreaId};
            // Populate related Geo Area IDs and flag for showing state-level data
            if(!geoArea.isEmpty()) {
                if(geoArea[0].Recordtype.Name == Assets.GEOAREARECORDTYPECOUNTRY) {
                    countryGeoAreaId = geoAreaId;
                    geoAreaIds = getRelatedGeoAreaIds(geoAreaId);
                    showStateWork = geoArea[0].BP_Uses_States__c;
                } else if(geoArea[0].Recordtype.Name == Assets.GEOAREARECORDTYPESTATE) {
                    geoAreaIds = getRelatedGeoAreaIds(geoAreaId);
                    countryGeoAreaId = geoArea[0].Parent__c;
                    stateGeoAreaId = geoAreaId;
                    showStateWork = true;
                } else {
                    stateGeoAreaId = geoArea[0].Parent__c;
                    countryGeoAreaId = geoArea[0].Parent__r != null ? geoArea[0].Parent__r.Parent__c : null;
                    showStateWork = (geoArea[0].Parent__r != null && geoArea[0].Parent__r.Parent__r != null)
                        ? geoArea[0].Parent__r.Parent__r.BP_Uses_States__c
                        : false;
                }
            }
        // Aggregate relevant Geo Area IDs
        if(stateGeoAreaId != null) geoAreaIds.add(stateGeoAreaId);
        if(countryGeoAreaId != null) geoAreaIds.add(countryGeoAreaId);
        // Query to fetch organization associations within the specified geographic area
        List<Org_Association__c> orgAssociationList = getOrgAssociations(geoAreaIds);
        // --- Detect Non-Consecutive Associations ---
        Map<String, Boolean> nonConsecutiveMap = prepareConsecutive(orgAssociationList);
        List<OrgAssociationWrapper> wrapperData = new List<OrgAssociationWrapper>();
        if(!orgAssociationList.isEmpty()) {
            Map<String, Integer> otherNameToIndex = new Map<String, Integer>();
            Map<String, Set<String>> otherNameToRanges = new Map<String, Set<String>>();
            Map<String, Integer> grantKeyToIndex = new Map<String, Integer>();
            for(Org_Association__c org : orgAssociationList) {
                if(org.Association__r != null) {
                    OrgAssociationWrapper objWrapper = new OrgAssociationWrapper();
                    objWrapper.recordType = org.RecordType.DeveloperName;
                    objWrapper.associationName = String.isNotBlank(org.Association__r.CityView_Name_Override__c)
                        ? org.Association__r.CityView_Name_Override__c
                        : org.Association__r.Name;
                    objWrapper.showDate = org.Association__r.Show_Org_Assoc_Dates_on_CityView__c;
                    objWrapper.description = org.Association__r.Description__c;
                    objWrapper.startDate = org.From__c != null ? String.valueOf(org.From__c.year()) : 'N/A';
                    objWrapper.endDate = org.To__c != null ? String.valueOf(org.To__c.year()) : 'Present';
                    String associationKey = ''+org.Association__r.CityView_Name_Override__c + org.Association__r.Name +  org.Organization__r.Government_Geo_Area__c;
                    Boolean isGrant = (objWrapper.recordType == Assets.ORG_ASSOCIATION_RECORDTYPE_GRANT);

                    if(nonConsecutiveMap.containsKey(associationKey) && !isGrant) {
                        objWrapper.nonConsecutive = true;
                    }
                    if(org.From__c == null || !objWrapper.showDate) {
                        objWrapper.endDate = 'N/A';
                        objWrapper.showDate = false;
                    }

                    objWrapper.customCss = ((org.To__c != null && org.To__c.year() >= Date.today().year()) || org.To__c == null) ? 'boldfontcss' : '';
                    objWrapper.focusArea = org.Association__r.FC_Focus_Area__c;
                    objWrapper.colorStyle = focusAreaStyles.get(org.Association__r.FC_Focus_Area__c);
                    objWrapper.color = focusAreaColors.get(org.Association__r.FC_Focus_Area__c);
                    objWrapper.orgAssociationId = org.Id;

                    if(org.Organization__r.Government_Geo_Area__r.Recordtype.Name == Assets.GEOAREARECORDTYPECOUNTRY) {
                        objWrapper.geoAreaLevel = 'country';
                    } else if(org.Organization__r.Government_Geo_Area__r.Recordtype.Name == Assets.GEOAREARECORDTYPESTATE) {
                        objWrapper.geoAreaLevel = 'state';
                    } else if(org.Organization__r.Government_Geo_Area__r.Recordtype.Name == Assets.GEOAREARECORDTYPECITY) {
                        objWrapper.geoAreaLevel = 'city';
                    }

                    objWrapper.showState = showStateWork;
                    objWrapper.showDescription = false;
                    objWrapper.iconSize = 'x-small';

                    // Avoid duplicates by key
                    String fromKey = (org.From__c != null) ? String.valueOf(org.From__c.year()) : 'N/A';
                    String toKey = (org.To__c   != null) ? String.valueOf(org.To__c.year())   : 'Present';
                    String yearRangeKey = fromKey + '|' + toKey;
                    String nameKey = objWrapper.associationName + objWrapper.geoAreaLevel;

                    if(otherNameToIndex.containsKey(nameKey)) {
                        Integer idx = otherNameToIndex.get(nameKey);
                        OrgAssociationWrapper existing = wrapperData[idx];
                        Boolean isInitiative = (existing.recordType == Assets.ASSOCIATION_RECORDTYPE_INITIATIVE);
                        // Convert string years -> integers safely
                        Integer grantStart = Integer.valueOf(
                            objWrapper.startDate == 'N/A' ? '0' :
                            (objWrapper.startDate == 'Present' ? String.valueOf(Date.today().year()) : objWrapper.startDate)
                        );

                        Integer grantEnd = Integer.valueOf(
                            objWrapper.endDate == 'N/A' ? '0' :
                            (objWrapper.endDate == 'Present' ? String.valueOf(Date.today().year()) : objWrapper.endDate)
                        );

                        Integer initStart = Integer.valueOf(
                            existing.startDate == 'N/A' ? '0' :
                            (existing.startDate == 'Present' ? String.valueOf(Date.today().year()) : existing.startDate)
                        );

                        Integer initEnd = Integer.valueOf(
                            existing.endDate == 'N/A' ? '0' :
                            (existing.endDate == 'Present' ? String.valueOf(Date.today().year()) : existing.endDate)
                        );

                        // ===================================================
                        // Full Details to Handle the Icons & rows to show logic is mentioned on ticket BRME-6366 on Point2
                        // A. If a Grant is completely within the Initiative date range, suppress the Grant row and keep only the Initiative.
                        // Reason: The Initiative already represents this work; showing the Grant  would be redundant and misleading in the UI.
                        // ===================================================
                        if(isGrant && isInitiative &&
                            grantStart >= initStart &&
                            grantEnd   <= initEnd)
                        {
                            existing.iconName  = null;
                            existing.iconTitle = null;

                            // Keep initiative row as the single entry
                            wrapperData[idx] = existing;

                            // Skip adding grant row
                            continue;
                        }

                        // ===================================================
                        // B. Grant exists with no corresponding Initiative for this association.
                        // Display the Grant as a standalone entry and explicitly label it so users know there is funding without a strategic initiative.
                        // ===================================================
                        if(isGrant && !isInitiative)
                        {
                            objWrapper.iconName  = 'utility:favorite_alt';
                            objWrapper.iconTitle = 'Grants Geo Area Served';

                            wrapperData.add(objWrapper);
                            otherNameToIndex.put(nameKey + objWrapper.recordType, wrapperData.size() - 1);
                            continue;
                        }

                        // ===================================================
                        // C. Grant dates extend beyond the Initiative range (before or after).
                        // Show BOTH records:
                        //  - Initiative: represents strategic scope
                        //  - Grant: represents additional coverage outside that scope
                        // Reason: Hiding either would lose important timeline context.
                        // ===================================================
                        if(isGrant && isInitiative && (grantStart < initStart || grantEnd > initEnd))
                        {
                            // Initiative icon
                            existing.iconName  = 'utility:favorite';
                            existing.iconTitle = 'Strategic Initiative';
                            wrapperData[idx] = existing;

                            // Grant icon
                            objWrapper.iconName  = 'utility:favorite_alt';
                            objWrapper.iconTitle = 'Grants Geo Area Served';

                            wrapperData.add(objWrapper);
                            otherNameToIndex.put(nameKey + objWrapper.recordType, wrapperData.size() - 1);
                            continue;
                        }

                        // ===================================================
                        // D.  DEFAULT BEHAVIOR: When records share the same association but have different date ranges, do NOT force a merge.
                        // Preserve separate rows to maintain accuracy. Icons clarify the role (Initiative vs Grant).
                        // ===================================================
                        if((objWrapper.startDate != existing.startDate || objWrapper.endDate   != existing.endDate) && isGrant)
                        {
                            objWrapper.iconName  = 'utility:favorite_alt';
                            objWrapper.iconTitle = 'Grants Geo Area Served';

                            wrapperData.add(objWrapper);
                            otherNameToIndex.put(nameKey + objWrapper.recordType, wrapperData.size() - 1);

                            if(existing.recordType == Assets.ASSOCIATION_RECORDTYPE_INITIATIVE)
                            {
                                existing.iconName  = 'utility:favorite';
                                existing.iconTitle = 'Strategic Location';
                            }

                            wrapperData[idx] = existing;
                        }
                        else
                        {
                            objWrapper.startDate = existing.startDate;
                            if(grantEnd >= initEnd ){
                                objWrapper.endDate =   objWrapper.endDate ;//String.valueOf(grantEnd) == String.valueOf(Date.today().year()) ? 'Present' : String.valueOf(grantEnd) ;
                            } else {
                                objWrapper.endDate =  existing.endDate; // String.valueOf(initEnd) == String.valueOf(Date.today().year()) ? 'Present' : String.valueOf(initEnd);
                            }

                            if(existing.iconName != null) {
                                objWrapper.iconName  = existing.iconName;
                                objWrapper.iconTitle = existing.iconTitle;
                            }
                            wrapperData[idx] = objWrapper;
                        }

                    } else {
                        // If not present, add as new
                        wrapperData.add(objWrapper);
                        otherNameToIndex.put(nameKey, wrapperData.size() - 1);

                        // FIX: Apply B-rule — grant with NO initiative for this association
                        if(objWrapper.recordType == Assets.ORG_ASSOCIATION_RECORDTYPE_GRANT) {

                            Boolean initiativeExistsForKey = false;

                            // Check if an initiative ever got stored for this nameKey
                            // We check using otherNameToIndex because an initiative row would have been stored earlier for this same key.
                            if(otherNameToIndex.containsKey(nameKey)) {
                                Integer existingIdx = otherNameToIndex.get(nameKey);
                                OrgAssociationWrapper existingRow = wrapperData[existingIdx];

                                // initiative?
                                if(existingRow.recordType == Assets.ASSOCIATION_RECORDTYPE_INITIATIVE) {
                                    initiativeExistsForKey = true;
                                }
                            }

                            // If no initiative exists → grant-only (B rule)
                            if(!initiativeExistsForKey) {
                                objWrapper.iconName  = 'utility:favorite_alt';
                                objWrapper.iconTitle = 'Grants Geo Area Served';
                                wrapperData[ wrapperData.size() - 1 ] = objWrapper;
                            }
                        }
                    }

                    if(!otherNameToRanges.containsKey(nameKey)) {
                        otherNameToRanges.put(nameKey, new Set<String>());
                    }
                    otherNameToRanges.get(nameKey).add(yearRangeKey);
                }
            }
        }
        return wrapperData;
    }

    public static List<Id> getRelatedGeoAreaIds(Id geoAreaId) {
        List<Id> geoAreaIds = new List<Id>();
        if(geoAreaId == null) {
            return new List<Id>();
        }
        List<Geo_Area__c> result = [
            SELECT Id, Parent__c, RecordType.Name, Parent__r.Parent__c, Parent__r.Parent__r.BP_Uses_States__c, BP_Uses_States__c
            FROM Geo_Area__c
            WHERE (Parent__c = :geoAreaId OR Parent__r.Parent__c = :geoAreaId )
            AND Deleted__c = false
            AND BP_Active__c = true];

        for(Geo_Area__c ga : result) {
            geoAreaIds.add(ga.Id);
        }
        return geoAreaIds;
    }

    // get orgAssociations
    @AuraEnabled
    public static List<Org_Association__c> getOrgAssociations(List<Id> geoAreaIds) {
        List<Org_Association__c> orgAssociationList = [
            SELECT Id, Association__c, Association__r.Name, Association__r.Id, From__c, To__c, Association__r.FC_Focus_Area__c, Organization__r.Government_Geo_Area__c,
            Association__r.Description__c, Association__r.Show_Org_Assoc_Dates_on_CityView__c, Association__r.CityView_Name_Override__c,
            RecordType.DeveloperName, Association__r.RecordType.DeveloperName, Organization__r.Government_Geo_Area__r.Recordtype.Name
            FROM Org_Association__c
            WHERE (Association__r.RecordType.DeveloperName IN (:Assets.ASSOCIATION_RECORDTYPE_INITIATIVE, :Assets.ASSOCIATION_RECORDTYPE_STANDARD, :Assets.ASSOCIATION_RECORDTYPE_GCOM)
                   OR RecordType.DeveloperName IN (:Assets.ORG_ASSOCIATION_RECORDTYPE_GRANT))
            AND Association__r.Publish_to_CityView__c = true
            AND Association__r.Active__c = true
            AND Association__r.Deleted__c = false
            AND Deleted__c = false
            AND Organization__r.Name != :Assets.RESTRICTED_ORG_NAME
            AND Organization__r.Government_Geo_Area__c IN :geoAreaIds
            WITH SECURITY_ENFORCED
            ORDER BY Association__r.FC_Focus_Area__c, Association__r.Name, Association__r.CityView_Name_Override__c ASC, RecordType.Name DESC, From__c ASC
        ];
        return orgAssociationList.isEmpty() ? new List<Org_Association__c>() : orgAssociationList;
    }

    // City level work for country
    @AuraEnabled
    public static List<CityAssociationWrapper> getCityAssociationCounts(String geoAreaId, String selectedValue) {
        List<CityAssociationWrapper> results = new List<CityAssociationWrapper>();
        try {
            String recordType = selectedValue == 'Country'
                                ? Assets.GEOAREARECORDTYPESTATE
                                : Assets.GEOAREARECORDTYPECITY;
            /* ---------------- Focus Area Styles ---------------- */
            Map<String, String> focusAreaStyles = new Map<String, String>();
            Map<String, String> focusAreaColors = new Map<String, String>();
            for(Focus_Area__c fa : [SELECT Name, Color_Code__c FROM Focus_Area__c]) {
                focusAreaStyles.put(
                    fa.Name,
                    'border-left:10px solid ' + fa.Color_Code__c + ' !important; padding:10px;'
                );
                focusAreaColors.put(fa.Name, fa.Color_Code__c);
            }

            /* ---------------- Geo Areas ---------------- */
            List<Geo_Area__c> cityGeoAreas = [
                SELECT Id, Geo_Name__c
                FROM Geo_Area__c
                WHERE (Parent__r.Parent__c = :geoAreaId OR Parent__c = :geoAreaId)
                   AND RecordType.DeveloperName = :recordType
                   AND BP_Active__c = true
                   AND Deleted__c = false
                   AND (Geo_Area_Focus_Area_Count__c > 0 OR Has_GCOM_Association__c = true)
            ];
            if(cityGeoAreas.isEmpty()) return results;
            Map<Id, String> geoAreaIdToName = new Map<Id, String>();
            Map<Id, List<OrgAssociationWrapper>> cityToOrgList = new Map<Id, List<OrgAssociationWrapper>>();
            for(Geo_Area__c ga : cityGeoAreas) {
                geoAreaIdToName.put(ga.Id, ga.Geo_Name__c);
                cityToOrgList.put(ga.Id, new List<OrgAssociationWrapper>());
            }

            /* ---------------- Org Associations ---------------- */
            List<Org_Association__c> orgAssociations = [
                SELECT Id, Association__c, Association__r.Name, Association__r.FC_Focus_Area__c,
                       Association__r.Description__c, Association__r.Show_Org_Assoc_Dates_on_CityView__c,
                       Association__r.CityView_Name_Override__c, RecordType.DeveloperName, From__c, To__c,
                       Organization__r.Government_Geo_Area__c
                FROM Org_Association__c
                WHERE Association__r.RecordType.DeveloperName IN (
                        :Assets.ASSOCIATION_RECORDTYPE_INITIATIVE,
                        :Assets.ASSOCIATION_RECORDTYPE_STANDARD,
                        :Assets.ORG_ASSOCIATION_RECORDTYPE_GRANT)
                  AND Association__r.Publish_to_CityView__c = true
                  AND Association__r.Active__c = true
                  AND Association__r.Deleted__c = false
                  AND Organization__r.Name != :Assets.RESTRICTED_ORG_NAME
                  AND Organization__r.Government_Geo_Area__c IN :geoAreaIdToName.keySet()
                  AND Deleted__c = false
                ORDER BY Association__c, From__c ASC
            ];
            if(orgAssociations.isEmpty()) return results;
            /* ---------------- Group by Association Key ---------------- */
            Map<String, List<Org_Association__c>> assocToRecords = new Map<String, List<Org_Association__c>>();
            for(Org_Association__c rec : orgAssociations) {
                if(rec.Association__c == null || rec.Organization__r == null) continue;
                String assocKey =
                    String.isNotBlank(rec.Association__r.CityView_Name_Override__c)
                    ? rec.Association__r.CityView_Name_Override__c
                    : rec.Association__r.Name + rec.Organization__r.Government_Geo_Area__c;
                if(!assocToRecords.containsKey(assocKey)) {
                    assocToRecords.put(assocKey, new List<Org_Association__c>());
                }
                assocToRecords.get(assocKey).add(rec);
            }
            /* ---------------- Build Wrappers (Split on Non-Consecutive) ---------------- */
            Map<String, List<OrgAssociationWrapper>> associationToWrappers = new Map<String, List<OrgAssociationWrapper>>();
            for(String assocKey : assocToRecords.keySet()) {
                List<Org_Association__c> records = assocToRecords.get(assocKey);
                if(records.isEmpty()) continue;
                List<List<Org_Association__c>> continuityRanges = splitByDateContinuity(records);
                associationToWrappers.put(assocKey, new List<OrgAssociationWrapper>());
                // first record of first range
                Org_Association__c firstRec = continuityRanges[0][0];
                // last record of last range
                Org_Association__c lastRec  = continuityRanges[continuityRanges.size() - 1][continuityRanges[continuityRanges.size() - 1].size() - 1];
                // true if we merged multiple date ranges
                Boolean nonConsecutive = (continuityRanges.size() > 1);
                String iconName = '';
                String iconTitle = '';
                if(firstRec.RecordType.DeveloperName == Assets.ORG_ASSOCIATION_RECORDTYPE_GRANT) {
                    iconName = 'utility:favorite_alt';
                    iconTitle = 'Grants Geo Area Served';
                } else if(firstRec.RecordType.DeveloperName == Assets.ASSOCIATION_RECORDTYPE_INITIATIVE) {
                    iconName = 'utility:favorite';
                    iconTitle = 'Strategic Location';
                }
                OrgAssociationWrapper wrap = new OrgAssociationWrapper();
                wrap.associationName = String.isNotBlank(firstRec.Association__r.CityView_Name_Override__c)
                                       ? firstRec.Association__r.CityView_Name_Override__c
                                       : firstRec.Association__r.Name;
                wrap.showDate = firstRec.Association__r.Show_Org_Assoc_Dates_on_CityView__c;
                wrap.description = firstRec.Association__r.Description__c;
                wrap.startDate = firstRec.From__c != null ? String.valueOf(firstRec.From__c.year()) : 'N/A';
                wrap.endDate   = lastRec.To__c  != null ? String.valueOf(lastRec.To__c.year())  : 'Present';
                if(firstRec.From__c == null || !wrap.showDate) {
                    wrap.startDate = 'N/A';
                    wrap.endDate   = 'N/A';
                    wrap.showDate  = false;
                }
                wrap.focusArea = firstRec.Association__r.FC_Focus_Area__c;
                wrap.colorStyle = focusAreaStyles.get(wrap.focusArea);
                wrap.color = focusAreaColors.get(wrap.focusArea);
                wrap.orgAssociationId = assocKey + '_' + wrap.startDate + '_' + wrap.endDate;
                wrap.showDescription = false;
                if(firstRec.RecordType.DeveloperName != Assets.ORG_ASSOCIATION_RECORDTYPE_GRANT) {
                    wrap.nonConsecutive = nonConsecutive;
                }
                wrap.customCss = (lastRec.To__c == null || lastRec.To__c >= Date.today()) ? 'boldfontcss' : '';
                wrap.recordType = firstRec.RecordType.DeveloperName;
                wrap.iconName = iconName;
                wrap.iconTitle = iconTitle;
                wrap.iconSize = 'x-small';
                associationToWrappers.get(assocKey).add(wrap);
            }
            Map<String, Set<Integer>> cityToAssocBlockIndex = new Map<String, Set<Integer>>();
            for(String assocKey : associationToWrappers.keySet()) {
                List<OrgAssociationWrapper> wraps = associationToWrappers.get(assocKey);
                for(Integer blockIndex = 0; blockIndex < wraps.size(); blockIndex++) {
                    OrgAssociationWrapper wrap = wraps[blockIndex];
                    for(Org_Association__c rec : assocToRecords.get(assocKey)) {
                        Id cityId = rec.Organization__r.Government_Geo_Area__c;
                        if(!cityToOrgList.containsKey(cityId)) continue;
                        if(!cityToAssocBlockIndex.containsKey(cityId)) {
                            cityToAssocBlockIndex.put(cityId, new Set<Integer>());
                        }
                        // Dedup per association + block index (NOT by date)
                        Integer uniqueBlockKey = assocKey.hashCode() + blockIndex;
                        if(!cityToAssocBlockIndex.get(cityId).contains(uniqueBlockKey)) {
                            cityToOrgList.get(cityId).add(wrap);
                            cityToAssocBlockIndex.get(cityId).add(uniqueBlockKey);
                        }
                    }
                }
            }
            /* ---------------- Build Final Result ---------------- */
            for(Id cityId : geoAreaIdToName.keySet()) {
                List<OrgAssociationWrapper> orgs = cityToOrgList.get(cityId);
                results.add(
                    new CityAssociationWrapper(
                        geoAreaIdToName.get(cityId),
                        cityId,
                        orgs == null ? 0 : orgs.size(),
                        orgs,
                        false
                    )
                );
            }
        } catch (Exception e) {
            BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields('CityViewDetailPageController_getCityAssociationCounts_Failed'));
        }
        return results;
    }

    private static List<List<Org_Association__c>> splitByDateContinuity(List<Org_Association__c> records) {
        List<List<Org_Association__c>> blocks = new List<List<Org_Association__c>>();
        if(records.isEmpty()) return blocks;

        List<Org_Association__c> current = new List<Org_Association__c>();
        current.add(records[0]);

        for(Integer i = 1; i < records.size(); i++) {
            Org_Association__c prev = records[i - 1];
            Org_Association__c curr = records[i];

            Boolean hasGap =
                prev.To__c != null &&
                curr.From__c != null &&
                curr.From__c.year() > prev.To__c.year() + 1;

            if(hasGap) {
                // Gap detected → start a new block
                blocks.add(current);
                current = new List<Org_Association__c>();
            }
            current.add(curr);
        }
        blocks.add(current);
        return blocks;
    }

    // Key Partners
    @AuraEnabled(cacheable = true)
    public static List<Org_Geo_Area__c> getKeyPartners(String geoAreaId) {
        List<Org_Geo_Area__c> orgGeoAreaList = [
            SELECT Id, Organization__r.Name
            FROM Org_Geo_Area__c
            WHERE Geo_area__c = :geoAreaId
            AND Organization__c != null
            AND Deleted__c = false
            AND Geo_Area__r.BP_Active__c = true
            AND Geo_Area__r.Deleted__c = false
            AND Organization__r.Name != :Assets.RESTRICTED_ORG_NAME
            AND Type__c = 'Key Partner'
            WITH SECURITY_ENFORCED
            ORDER BY Sort_Order__c NULLS LAST, Organization__r.Name ASC
        ];
        return orgGeoAreaList?.isEmpty() ? null : orgGeoAreaList;
    }

    // Highlights
    @AuraEnabled(cacheable = true)
    public static List<Interaction__c> getCityViewHighlights(String geoAreaId, String duration) {
        AggregateResult[] results = [
            SELECT MAX(Interaction_Date__c) maxDate
            FROM Interaction__c
            WHERE CityView_Review_Status__c = 'Publish to CityView'
            AND Private_Interaction__c = false
            AND RecordType.DeveloperName = :Assets.INTERACTION_RECORDTYPE_ORG_ENGAGEMENT_DEVNAME
            AND Organization__c != NULL
            AND Organization__r.Government_Geo_Area__c = :geoAreaId
        ];

        String orgINTRecType = Assets.INTERACTION_RECORDTYPE_ORG_ENGAGEMENT_DEVNAME;
        String baseQuery = 'SELECT Id, FC_Focus_Area__c, Description__c, Interaction_Date__c ' + 'FROM Interaction__c ' +
            'WHERE CityView_Review_Status__c = \'Publish to CityView\' ' +
            'AND Private_Interaction__c = false ' +
            'AND RecordType.DeveloperName = :orgINTRecType ' +
            'AND Organization__c != NULL ' +
            'AND Organization__r.Government_Geo_Area__c = :geoAreaId ';
        baseQuery += 'WITH SECURITY_ENFORCED ORDER BY Interaction_Date__c DESC, FC_Focus_Area__c ASC';
        if(duration == 'MostRecent') {
            baseQuery += ' LIMIT 10';
        }
        return Database.query(baseQuery);
    }

    public static OfficeMapWrapper getOfficeWrapper(Geo_Area__c geoArea, Map<Id, Geo_Area_Focus_Area__c> maxWeightMap ){
        OfficeMapWrapper objWrapper = new OfficeMapWrapper();
        objWrapper.bmoOfficeId = geoArea.Id;
        objWrapper.addressText = geoArea.Name;
        objWrapper.latitude = geoArea.Coordinates__latitude__s;
        objWrapper.longitude = geoArea.Coordinates__longitude__s;
        objWrapper.geoArea = true;
        if( maxWeightMap.containsKey(geoArea.Id) && maxWeightMap.get(geoArea.Id) != null && maxWeightMap.get(geoArea.Id).Color_Code__c != null) {
            objWrapper.colorCode =  maxWeightMap.get(geoArea.Id).Color_Code__c;
        } else if(geoArea.Has_GCOM_Association__c && (geoArea.Cultural_Access_Count__c == 0 || geoArea.Interaction_Count__c == 0)){
            objWrapper.colorCode ='#3F843E'; //Green

        }else{
            objWrapper.colorCode ='#A9A9A9'; //grey
        }
        return objWrapper;
    }

    // OfficeMaps
    @AuraEnabled(cacheable = true)
    public static List<OfficeMapWrapper> getOfficeMapDetails(String geoAreaId) {
        List<OfficeMapWrapper> wrapperData = new List<OfficeMapWrapper>();
        Boolean isCountrySelected;
        Boolean isStateSelected;
        Map<Id, Geo_Area_Focus_Area__c> maxWeightMap = new Map<Id, Geo_Area_Focus_Area__c>();
        try {
            if(String.isBlank(geoAreaId)) return null;
            Geo_Area__c geoArea = [
                SELECT Id, Name, Coordinates__Latitude__s, Coordinates__Longitude__s, Recordtype.Name, Has_GCOM_Association__c, Cultural_Access_Count__c, Interaction_Count__c
                FROM Geo_Area__c
                WHERE Id = :geoAreaId
                  AND Deleted__c = false
                  AND BP_Active__c = true
                LIMIT 1
            ];
            String query =
                'SELECT Id, Name, Address__c, Geo_area__c, Address_Text__c, Sort_Order__c, ' +
                       'Geo_Area__r.Name, Geo_Area__r.Coordinates__c, Geo_Area__r.Coordinates__latitude__s, Geo_Area__r.Coordinates__longitude__s ' +
                'FROM Bloomberg_Office__c ' +
                'WHERE Deleted__c = false ';
            isCountrySelected  = geoArea.Recordtype.Name == Assets.GEOAREARECORDTYPECOUNTRY ? true : false;
            isStateSelected = geoArea.Recordtype.Name == Assets.GEOAREARECORDTYPESTATE ? true : false;
            List<Geo_Area_Focus_Area__c> focusAreas = [
                SELECT Id, Name, Geo_Area__c,Geo_Area__r.Name, Weight__c, Color_Code__c
                FROM Geo_Area_Focus_Area__c
                WHERE Geo_Area__c = :geoAreaId
                   OR Geo_Area__r.Parent__c= :geoAreaId
                   OR Geo_Area__r.Parent__r.Parent__c = :geoAreaId
            ];
            for(Geo_Area_Focus_Area__c fa : focusAreas) {
                if((!maxWeightMap.containsKey(fa.Geo_Area__c) || fa.Weight__c > maxWeightMap.get(fa.Geo_Area__c).Weight__c) && fa.Color_Code__c != null) {
                    maxWeightMap.put(fa.Geo_Area__c, fa);
                }
            }
            if(isStateSelected || isCountrySelected) {
                List<Geo_Area__c> geoAreaList ;
                if(isStateSelected) {
                    query += 'AND (Geo_Area__r.Parent__c = \'' + geoAreaId + '\' ';
                    geoAreaList = [
                        SELECT Id, Name, Coordinates__Latitude__s, Coordinates__Longitude__s, Cultural_Access_Count__c, Interaction_Count__c, Has_GCOM_Association__c
                        FROM Geo_Area__c
                        WHERE Parent__c = :geoAreaId
                          AND BP_Active__c = true
                          AND Deleted__c = false
                          AND Geo_Area_Focus_Area_Count__c > 0];
                } else if(isCountrySelected) {
                    query += 'AND (Geo_Area__r.Parent__r.Parent__c = \'' + geoAreaId + '\' ';
                    geoAreaList = [
                        SELECT Id, Name, Coordinates__Latitude__s, Coordinates__Longitude__s, Cultural_Access_Count__c, Interaction_Count__c, Has_GCOM_Association__c
                        FROM Geo_Area__c
                        WHERE Parent__r.Parent__c = :geoAreaId
                          AND BP_Active__c = true
                          AND Deleted__c = false
                          AND Geo_Area_Focus_Area_Count__c > 0];
                }
                query += 'OR Geo_Area__c = \'' + geoAreaId + '\' )';
                query += 'AND Geo_Area__r.BP_Active__c = true ';
                // Query all related focus areas
                for(Geo_Area__c ga : geoAreaList) {
                    wrapperData.add(getOfficeWrapper(ga, maxWeightMap));
                }
            } else {
                query += 'AND Geo_area__c = \'' + geoAreaId + '\' ';
            }
            query += 'WITH SECURITY_ENFORCED ORDER BY Sort_Order__c NULLS LAST';
            List<Bloomberg_Office__c> bloombergOfficeList = Database.query(query);
            if(!bloombergOfficeList.isEmpty()) {
                for(Bloomberg_Office__c bmo : bloombergOfficeList) {
                    Address addr = bmo.Address__c;
                    OfficeMapWrapper objWrapper = new OfficeMapWrapper();
                    objWrapper.bmoOfficeId = bmo.Id;
                    objWrapper.addressText = bmo.Address_Text__c;
                    objWrapper.street = addr.Street;
                    objWrapper.city = addr.City;
                    objWrapper.state = addr.State;
                    objWrapper.country = addr.Country;
                    objWrapper.postalCode = addr.PostalCode;
                    objWrapper.geoArea = false;
                    wrapperData.add(objWrapper);
                }
            }
            // we need this to plot the selected Geo Area based on Lat/long in detail page and above one we are using to fetch the related office address
            if(geoArea.Coordinates__latitude__s != null) {
                wrapperData.add(getOfficeWrapper(geoArea, maxWeightMap));
            }
            // Return results or null if empty
            return wrapperData;
        } catch(Exception e) {
            BBApps_ErrorHandler.logErrors(e, new BBApps_ErrorCustomFields('getOfficeMapDetails_Failed'));
            throw new AuraHandledException('Error retrieving office addresses: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Id getFirstOrgIdByGeoArea(Id geoAreaId) {
        List<Account> accounts = [
            SELECT Id
            FROM Account
            WHERE Government_Geo_Area__c = :geoAreaId
            LIMIT 1
        ];
        return accounts.isEmpty() ? null : accounts[0].Id;
    }

    // Employee Travel
    @AuraEnabled(cacheable = true)
    public static List<TravelDetail> getCityViewTravelDetails(String geoAreaId) {
        List<Event> events = [
            SELECT Id, StartDateTime, EndDateTime, Description
            FROM Event
            WHERE Type__c = 'Travel'
            AND Geo_Area__c = :geoAreaId
            AND (
                StartDateTime >= :System.today().addMonths(-3) OR
                StartDateTime >= :System.today()
            )
            ORDER BY StartDateTime DESC
        ];

        Set<Id> eventIds = new Set<Id>();
        for(Event e : events) eventIds.add(e.Id);

        Map<Id, List<String>> eventToContactNames = new Map<Id, List<String>>();
        for(EventRelation er : [
            SELECT EventId, Relation.Name
            FROM EventRelation
            WHERE EventId IN :eventIds
            AND Relation.Type = 'Contact'
            ORDER BY Relation.Name ASC])
        {
            if(!eventToContactNames.containsKey(er.EventId)) {
                eventToContactNames.put(er.EventId, new List<String>());
            }
            eventToContactNames.get(er.EventId).add(er.Relation.Name);
        }

        List<TravelDetail> details = new List<TravelDetail>();
        for(Event e : events) {
            TravelDetail td = new TravelDetail();
            td.Id = e.Id;
            td.StartDateTime = e.StartDateTime;
            td.EndDateTime = e.EndDateTime;
            td.Description = e.Description;
            td.ContactNames = String.join(eventToContactNames.get(e.Id), ', ');
            details.add(td);
        }
        return details;
    }
    // fetch geoArea details to show on Mobile Component List view
    @AuraEnabled
    public static Map<String, List<Geo_Area__c>> getListViewData(Id initiativeId){
        List<Id> geoAreaIds = new List<Id>();
        Map<String, List<Geo_Area__c>> resultMap = new Map<String, List<Geo_Area__c>>();
        if(initiativeId == null) {
            return resultMap;
        }
        Association__c association  =[SELECT Id,FC_Focus_Area__c FROM Association__c WHERE Id =:initiativeId LIMIT 1];
        geoAreaIds = CityViewFiltersController.getGeoAreasByFilters(new List<Id>{initiativeId},new List<String>{association.FC_Focus_Area__c},new List<Id>(),new List<Id>());
        If(geoAreaIds.isEmpty()){
            return resultMap;
        }
        List<Geo_Area__c> countryList =  [SELECT Id,Name FROM Geo_Area__c WHERE Recordtype.Name IN ('Country') AND Id IN : geoAreaIds AND Coordinates__latitude__s != null AND Coordinates__longitude__s != null AND Deleted__c = false AND BP_Active__c = true AND (Association_Count__c > 0 OR Grant_Association_Count__c > 0) ];
        List<Geo_Area__c> stateList =  [SELECT Id, Name FROM Geo_Area__c WHERE Recordtype.Name IN ('State') AND Id IN :geoAreaIds AND Coordinates__latitude__s != null  AND Coordinates__longitude__s != null AND Deleted__c = false AND BP_Active__c = true];
        List<Geo_Area__c> cityList =  [SELECT Id,Name FROM Geo_Area__c WHERE Recordtype.Name IN ('City') AND Id IN : geoAreaIds AND Coordinates__latitude__s != null  AND Coordinates__longitude__s != null AND Deleted__c = false AND BP_Active__c = true AND (Association_Count__c > 0 OR Grant_Association_Count__c > 0)];
        resultMap.put('Country', countryList);
        resultMap.put('State', stateList);
        resultMap.put('City', cityList);
        return resultMap;
    }

    // Helper method to return Cultural Access Org Geo Area records
    public static List<Org_Geo_Area__c> getCulturalAccess(String geoAreaId){
        List<Org_Geo_Area__c> orgGeoAreaList = [SELECT Id, Name, Geo_Area__c, Organization__c, Organization__r.Name, Organization__r.Cultural_Access_Benefits__c, Organization__r.Org_Address__c
                                                FROM Org_Geo_Area__c
                                                WHERE Geo_Area__c = :geoAreaId
                                                AND Type__c IN (:Assets.ORGGEOAREACULTURALACCESS, :Assets.ORGGEOAREACULTURALIMPLICIT)
                                                AND Organization__r.Name != :Assets.RESTRICTED_ORG_NAME
                                                AND Organization__c != null
                                                AND Deleted__c = false
                                                WITH SECURITY_ENFORCED
                                                ORDER BY Organization__r.Name ASC
                                               ];
        return orgGeoAreaList;
    }

    // Wrapper Class for Travel
    public class TravelDetail {
        @AuraEnabled public Id Id;
        @AuraEnabled public DateTime startDateTime;
        @AuraEnabled public DateTime endDateTime;
        @AuraEnabled public String description;
        @AuraEnabled public String contactNames;
    }
    // Wrapper Class Definition
    public class CulturalAccessWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String geoAreaId;
        @AuraEnabled public String organizationId;
        @AuraEnabled public String organizationName;
        @AuraEnabled public String culturalBenefit;
        @AuraEnabled public Boolean showBenefit;
        @AuraEnabled public String address;
    }
    public class OfficeMapWrapper {
        @AuraEnabled public Id bmoOfficeId;
        @AuraEnabled public String addressText;
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String country;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String colorCode;
        @AuraEnabled public Decimal latitude;
        @AuraEnabled public Decimal longitude;
        @AuraEnabled public Boolean geoArea;
    }

    public class OrgAssociationWrapper {
        @AuraEnabled public String orgAssociationId;
        @AuraEnabled public String associationName;
        @AuraEnabled public String startDate;
        @AuraEnabled public String endDate;
        @AuraEnabled public String focusArea;
        @AuraEnabled public String colorStyle;
        @AuraEnabled public String color;
        @AuraEnabled public String geoAreaLevel;
        @AuraEnabled public Boolean showState;
        @AuraEnabled public Boolean showDate;
        @AuraEnabled public Boolean showDescription;
        @AuraEnabled public String description;
        @AuraEnabled public String customCss;
        @AuraEnabled public String recordType;
        @AuraEnabled public String iconName;
        @AuraEnabled public String iconSize;
        @AuraEnabled public String iconTitle;
        @AuraEnabled public Boolean nonConsecutive;
    }

    public class CityAssociationWrapper {
        @AuraEnabled public String cityName;
        @AuraEnabled public String displayName; // cityName + (count)
        @AuraEnabled public Id cityId;
        @AuraEnabled public Boolean showAssociations;
        @AuraEnabled public Integer associationCount;
        @AuraEnabled public List<OrgAssociationWrapper> orgAssociations;

        public CityAssociationWrapper(String cityName, Id cityId, Integer count, List<OrgAssociationWrapper> orgs, Boolean showAssociation) {
            this.cityName = cityName;
            this.displayName = cityName + ' (' + count + ')';
            this.cityId = cityId;
            this.orgAssociations = orgs;
            this.showAssociations = showAssociation;
            this.associationCount = count;
        }
    }

    @AuraEnabled
    public static List<CityCulturalAccessGroup> getCulturalAccessGroups(String geoAreaId) {
        if(String.isBlank(geoAreaId)) return new List<CityCulturalAccessGroup>();

        Geo_Area__c ga = [
            SELECT Id, Name, Geo_Name__c, RecordType.DeveloperName, Parent__c, Parent__r.Parent__c
            FROM Geo_Area__c
            WHERE Id = :geoAreaId
            AND Deleted__c = false
            AND BP_Active__c = true
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        String geoFilter;
        if(ga.RecordType.DeveloperName == 'City') {
            geoFilter = 'Geo_Area__c = :geoAreaId';
        } else if(ga.RecordType.DeveloperName == 'State') {
            geoFilter = 'Geo_Area__r.Parent__c = :geoAreaId AND Geo_Area__r.RecordType.DeveloperName = \'City\'';
        } else if(ga.RecordType.DeveloperName == 'Country') {
            geoFilter = 'Geo_Area__r.Parent__r.Parent__c = :geoAreaId AND Geo_Area__r.RecordType.DeveloperName = \'City\'';
        } else {
            return new List<CityCulturalAccessGroup>();
        }

        String query = 'SELECT Id, Name, Geo_Area__c, Geo_Area__r.Name, Geo_Area__r.Geo_Name__c, ' +
            'Organization__c, Organization__r.Name, Organization__r.Cultural_Access_Benefits__c, ' +
            'Organization__r.Org_Address__c ' +
            'FROM Org_Geo_Area__c ' +
            'WHERE ' + geoFilter + ' ' +
            'AND Type__c IN (:culturalAccess, :culturalImplicit) ' +
            'AND Organization__r.Name != :restrictedOrgName ' +
            'AND Organization__c != null ' +
            'AND Deleted__c = false ' +
            'AND Geo_Area__r.Deleted__c = false ' +
            'ORDER BY Geo_Area__r.Name, Organization__r.Name ASC';

        String culturalAccess = Assets.ORGGEOAREACULTURALACCESS;
        String culturalImplicit = Assets.ORGGEOAREACULTURALIMPLICIT;
        String restrictedOrgName = Assets.RESTRICTED_ORG_NAME;

        List<Org_Geo_Area__c> all = Database.query(query);

        if(all.isEmpty()) return new List<CityCulturalAccessGroup>();

        Map<Id, CityCulturalAccessGroup> cityGroupMap = new Map<Id, CityCulturalAccessGroup>();
        Map<Id, Set<Id>> cityOrgTracker = new Map<Id, Set<Id>>();

        for(Org_Geo_Area__c r : all) {
            CityCulturalAccessGroup g = cityGroupMap.get(r.Geo_Area__c);
            if(g == null) {
                g = new CityCulturalAccessGroup();
                g.cityId = r.Geo_Area__c;
                g.cityName = String.isNotBlank(r.Geo_Area__r.Geo_Name__c) ? r.Geo_Area__r.Geo_Name__c : r.Geo_Area__r.Name;
                g.rows = new List<CulturalAccessWrapper>();
                cityGroupMap.put(r.Geo_Area__c, g);
                cityOrgTracker.put(r.Geo_Area__c, new Set<Id>());
            }

            if(!cityOrgTracker.get(r.Geo_Area__c).contains(r.Organization__c)) {
                cityOrgTracker.get(r.Geo_Area__c).add(r.Organization__c);
                CulturalAccessWrapper w = new CulturalAccessWrapper();
                w.id = r.Id;
                w.name = r.Name;
                w.geoAreaId = (String)r.Geo_Area__c;
                w.organizationId = (String)r.Organization__c;
                w.organizationName = r.Organization__r.Name;
                w.culturalBenefit = r.Organization__r.Cultural_Access_Benefits__c;
                w.showBenefit = false;
                w.address = r.Organization__r.Org_Address__c;
                g.rows.add(w);
            }
        }

        List<CityCulturalAccessGroup> result = cityGroupMap.values();
        for(CityCulturalAccessGroup g : result) {
            g.accessCount = g.rows.size();
        }

        return result;
    }

    public class CityCulturalAccessGroup {
        @AuraEnabled public Id cityId;
        @AuraEnabled public String cityName;
        @AuraEnabled public Integer accessCount;
        @AuraEnabled public List<CulturalAccessWrapper> rows;
    }
}