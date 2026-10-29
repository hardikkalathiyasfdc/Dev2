({
	loadSummaries: function (cmp) {
		cmp.set("v.isLoading", true);
		let params = { recordId: cmp.get("v.recordId") };
		let self = this;
		self.util.controllerPromise(cmp, "getSummaries", params)
			.then((result) => {
				result.sort((a, b) => {
					return a.sort > b.sort ? 1 : a.sort < b.sort ? -1 : 0;
				});
				cmp.set("v.summaries", result);
				cmp.set("v.isLoading", false);
			}).catch(
				$A.getCallback(function (errMsg) {
					errMsg = errMsg && errMsg.message ? errMsg.message : errMsg;
					cmp.set("v.isLoading", false);
					self.util.showToast("Error", errMsg, "error");
				})
			);
	}
});