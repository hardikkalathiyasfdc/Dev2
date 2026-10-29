({
	init: function (cmp, event, helper) {
		const objectName = cmp.get("v.sObjectName");
        cmp.set("v.cardTitle", objectName === "Account" ? "Organization Highlights" : "Contact Highlights");
		helper.util = new cmputil();
		helper.loadSummaries(cmp);
	}
});