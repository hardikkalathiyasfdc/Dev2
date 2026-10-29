// BRME-6786 pre-check: verify each fixture row's (a) initial message bucket and (b) duplicate-modal candidate availability.
// Simulates setUnconfirmedRecords (strict normalized equality over getOrgMap) and DITLookupController.fetchRecords (LIKE) logic.
System.debug('======== BRME-6786 PRE-CHECK (' + Datetime.now().format() + ') ========');
List<String> uploads = new List<String>{
    'BRME6786 Holdings',                 // scenario 1: not found msg + duplicates available
    'BRME6786 Nonexistent Foundation',   // scenario 2: not found + NO candidates -> Create Organization
    'BRME6786 City Foundation',          // scenario 3: multiple msg + duplicates available
    'BRME6786 Exact Org'                 // control: exact match, no error
};
for (String up : uploads) {
    // --- getOrgMap equivalent ---
    String key = SpecialCharactersHelper.convertSpecialCharToEnglish(up, false).toLowerCase();
    String pattern = '%' + String.escapeSingleQuotes(key) + '%';
    List<Account> hits = [SELECT Id, Name FROM Account
        WHERE AKA__c LIKE :pattern OR Legal_Name__c LIKE :pattern OR Name LIKE :pattern
           OR Converted_AKA__c LIKE :pattern OR Converted_Legal_Name__c LIKE :pattern OR Converted_Org_Name__c LIKE :pattern
        ORDER BY LastModifiedDate DESC LIMIT 5000];
    Map<Id, String> orgMapEntry = new Map<Id, String>();
    for (Account acc : hits) {
        if (String.isBlank(acc.Name)) continue;
        String accNorm = SpecialCharactersHelper.convertSpecialCharToEnglish(acc.Name, false).toLowerCase();
        Boolean keyThe = up.trim().toLowerCase().startsWith('the ');
        Boolean accThe = acc.Name.trim().toLowerCase().startsWith('the ');
        if (accThe && !keyThe) continue;
        if (accNorm.contains(key)) orgMapEntry.put(acc.Id, accNorm);
    }
    // --- setUnconfirmedRecords equivalent ---
    String uploadedCompare = SpecialCharactersHelper.convertSpecialCharToEnglish(up.trim().replaceFirst('(?i)^the\\s+', ''), false).toLowerCase();
    Integer countOrg = 0;
    for (String v : orgMapEntry.values()) {
        if (v == uploadedCompare || v == ('the' + uploadedCompare)) countOrg++;
    }
    String initMsg;
    if (orgMapEntry.isEmpty() || countOrg == 0) initMsg = '"' + up + ' not found in BRM"';
    else if (countOrg > 1) initMsg = '"Multiple ' + up + ' found in BRM. Please search for correct one."';
    else initMsg = 'AUTO-LINK or "Potential match found"';
    // --- fetchRecords (lookup/modal) equivalent ---
    String lk = SpecialCharactersHelper.convertSpecialCharToEnglish(up.replaceFirst('The ', '')).trim();
    List<Account> lkHits = [SELECT Id, Name FROM Account
        WHERE Name LIKE :('%' + String.escapeSingleQuotes(lk) + '%')
           OR Converted_AKA__c LIKE :(String.escapeSingleQuotes(lk) + '%')
           OR Converted_Legal_Name__c LIKE :(String.escapeSingleQuotes(lk) + '%')
           OR Converted_Org_Name__c LIKE :(String.escapeSingleQuotes(lk) + '%')
        LIMIT 200];
    Boolean dupModal = lkHits.size() > 1 || (lkHits.size() == 1 && up.replace('the ','') != lkHits[0].Name.replace('the ',''));
    System.debug('ROW "' + up + '" => orgMapHits=' + orgMapEntry.size() + ' countOrg=' + countOrg
        + ' | initial=' + initMsg
        + ' | modalCandidates=' + lkHits.size() + ' dupModal=' + dupModal
        + (lkHits.isEmpty() ? ' [Create Organization]' : ''));
    for (Account h : lkHits) System.debug('     cand: ' + h.Id + ' ' + h.Name);
}
System.debug('======== END ========');
