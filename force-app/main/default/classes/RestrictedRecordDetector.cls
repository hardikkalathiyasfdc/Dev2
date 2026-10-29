/**
 * @description Helper that detects restricted (Private) records (Organizations and
 * Contacts) for warning purposes. Runs WITHOUT sharing so counts reflect all restricted
 * records regardless of whether the running user can see those records.
 *
 * This is intentionally separate from any export/clone query (which runs WITH sharing so
 * users only process records they have access to). The counts are used purely to warn the
 * user that some selected records are Private and will not be exported/cloned/added.
 */
public without sharing class RestrictedRecordDetector {

    /**
     * @description Counts restricted Accounts within the provided organization id collection,
     * ignoring record-level sharing.
     * @param organizationIds Account (Organization) ids to evaluate.
     * @return Number of matching Accounts flagged Restricted__c = true.
     */
    public static Integer countRestrictedOrgs(Set<String> organizationIds) {
        if (organizationIds == null || organizationIds.isEmpty()) {
            return 0;
        }
        return [
            SELECT COUNT()
            FROM Account
            WHERE Id IN :organizationIds
            AND Restricted__c = true
        ];
    }

    /**
     * @description Overload accepting a List of organization ids. Delegates to the Set-based
     * implementation.
     */
    public static Integer countRestrictedOrgs(List<String> organizationIds) {
        return (organizationIds == null)
            ? 0
            : countRestrictedOrgs(new Set<String>(organizationIds));
    }

    /**
     * @description Counts restricted (Private) Contacts that are members of the given list
     * (Campaign), ignoring record-level sharing. Runs WITHOUT sharing because the Campaign
     * is Private sharing — a user who can see the list but not its restricted Contacts would
     * otherwise get 0 and never be warned. Used purely for warning the user.
     * @param campaignId The list (Campaign) id.
     * @return Number of member Contacts flagged Restricted__c = true.
     */
    public static Integer countRestrictedContactsInList(Id campaignId) {
        return (campaignId == null)
            ? 0
            : countRestrictedContactsInLists(new List<String>{ campaignId });
    }

    /**
     * @description Counts restricted (Private) Contacts that are members of ANY of the given
     * lists (Campaigns), ignoring record-level sharing.
     * @param campaignIds List of Campaign (list) ids.
     * @return Number of member Contacts flagged Restricted__c = true.
     */
    public static Integer countRestrictedContactsInLists(List<String> campaignIds) {
        if (campaignIds == null || campaignIds.isEmpty()) {
            return 0;
        }
        return [
            SELECT COUNT()
            FROM CampaignMember
            WHERE CampaignId IN :campaignIds
            AND Contact.Restricted__c = true
        ];
    }

    /**
     * @description Counts restricted (Private) Contacts within the provided contact id set,
     * ignoring record-level sharing.
     * @param contactIds List of Contact ids to evaluate.
     * @return Number of matching Contacts flagged Restricted__c = true.
     */
    public static Integer countRestrictedContacts(List<String> contactIds) {
        if (contactIds == null || contactIds.isEmpty()) {
            return 0;
        }
        return [
            SELECT COUNT()
            FROM Contact
            WHERE Id IN :contactIds
            AND Restricted__c = true
        ];
    }

    /**
     * @description Counts restricted (Private) leadership Contacts for the given Account,
     * ignoring record-level sharing.
     * @param accountId The Account (Organization) id.
     * @return Number of Contacts flagged Restricted__c = true and Leadership_Contact__c = true.
     */
    public static Integer countRestrictedLeadershipContacts(Id accountId) {
        if (accountId == null) {
            return 0;
        }
        return [
            SELECT COUNT()
            FROM Contact
            WHERE AccountId = :accountId
            AND Restricted__c = true
            AND Leadership_Contact__c = true
        ];
    }

    /**
     * @description Returns all Organization (Account) ids that are members of the given
     * Organization List Campaigns, ignoring record-level sharing. This runs WITHOUT
     * sharing because the ListOrganization__c junction is ControlledByParent (both the
     * Campaign and the restricted Account) so a user without access to the Account
     * cannot see the junction row at all, which would otherwise hide the very orgs we
     * need to warn them about.
     *
     * Callers must separately scope the exported data by record-level sharing
     * (see OrgAccessibilityFilter) so only accessible orgs are actually exported.
     * @param campaignIds Organization List (Campaign) ids.
     * @return Set of Organization (Account) ids that are members of those lists.
     */
    public static Set<String> getOrgIdsInLists(List<String> campaignIds) {
        Set<String> orgIds = new Set<String>();
        if (campaignIds == null || campaignIds.isEmpty()) {
            return orgIds;
        }
        for (ListOrganization__c listOrg : [
            SELECT Organization__c
            FROM ListOrganization__c
            WHERE List__c IN :campaignIds
            AND List__r.RecordType.Name = 'Organization List'
        ]) {
            if (String.isNotBlank(listOrg.Organization__c)) {
                orgIds.add(listOrg.Organization__c);
            }
        }
        return orgIds;
    }
}