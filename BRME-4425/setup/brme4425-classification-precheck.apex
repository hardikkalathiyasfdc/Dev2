// BRME-4425 pre-check: confirm how each fixture row classifies (exact-match / review / new) under current org data.
// Uses the same name/email matching the DIT getDupes retrieval relies on.
Set<String> lastNames = new Set<String>{'BRME4425Exact', 'BRME4425New'};
List<Contact> existing = [SELECT Id, FirstName, LastName, Email, Preferred_First_Name__c,
                                 Converted_FirstName__c, Converted_LastName__c, Converted_Full_Name__c
                          FROM Contact WHERE LastName IN :lastNames ORDER BY FirstName];
System.debug('=== EXISTING BRME4425 CONTACTS ===');
for (Contact c : existing) System.debug('  ' + c.Id + ' ' + c.FirstName + ' ' + c.LastName + ' email=' + c.Email + ' pref=' + c.Preferred_First_Name__c);

// Each fixture row: [firstName, lastName, email] -> expected classification
List<String[]> rows = new List<String[]>{
    new String[]{'Alice','BRME4425Exact','alice.brme4425@brme4425.invalid'},
    new String[]{'Brendan','BRME4425Exact','brendan.brme4425@brme4425.invalid'},
    new String[]{'Carla','BRME4425Exact','carla.brme4425@brme4425.invalid'},
    new String[]{'Carla','BRME4425Exact','carla.DIFFERENT@brme4425.invalid'},
    new String[]{'Derek','BRME4425New','derek.brme4425@brme4425.invalid'},
    new String[]{'Alice','BRME4425Exact','alice.DIFFERENT@brme4425.invalid'},
    new String[]{'Brendan','BRME4425Exact','brendan.DIFFERENT@brme4425.invalid'}
};
System.debug('=== ROW CLASSIFICATION (candidate? exact on all mapped fields?) ===');
for (String[] r : rows) {
    String fn = r[0]; String ln = r[1]; String em = r[2];
    List<Contact> cands = new List<Contact>();
    for (Contact c : existing) {
        Boolean nameMatch = (c.FirstName != null && c.FirstName.equalsIgnoreCase(fn) && c.LastName.equalsIgnoreCase(ln))
            || (c.Preferred_First_Name__c != null && c.Preferred_First_Name__c.equalsIgnoreCase(fn) && c.LastName.equalsIgnoreCase(ln));
        Boolean emailMatch = (c.Email != null && c.Email.equalsIgnoreCase(em));
        if (nameMatch || emailMatch) cands.add(c);
    }
    String verdict;
    if (cands.isEmpty()) verdict = 'NEW (no review)';
    else {
        Contact m = cands[0];
        Boolean exact = (m.FirstName != null && m.FirstName.equalsIgnoreCase(fn) && m.LastName.equalsIgnoreCase(ln)
                         && m.Email != null && m.Email.equalsIgnoreCase(em));
        verdict = exact ? 'EXACT MATCH (no review) vs ' + m.FirstName + ' ' + m.LastName : 'REVIEW (differs) vs ' + m.FirstName + ' ' + m.LastName + ' email=' + m.Email;
    }
    System.debug('  ' + fn + ' ' + ln + ' <' + em + '>  => ' + verdict);
}
