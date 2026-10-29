// BRME-7042: Enable value + percentage + total on the 3 breakdown donut charts via Analytics API
List<Id> reportIds = new List<Id>{
    '00Obc000002Nw5NEAS', // Component
    '00Obc000002Nw5OEAS', // Geography
    '00Obc000002Nw5PEAS'  // Type of Work
};
for (Id rptId : reportIds) {
    // Get current report metadata
    String getUrl = '/services/data/v68.0/analytics/reports/' + rptId + '/describe';
    // We can't call REST from Apex directly here; this is a placeholder for a REST call via sf CLI instead.
    System.debug('Report: ' + rptId);
}
