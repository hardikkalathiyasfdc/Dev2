({
  loadRecId: function (cmp) {
    cmp.set("v.isLoading", true);
    let self = this;
    this.util
      .controllerPromise(cmp, "getRecordTypeId")
      .then(
        $A.getCallback(function (result) {
          cmp.set("v.isLoading", false);
          if (!result || !result.length) {
            return;
          }
          cmp.set("v.recordTypeId", result);
          cmp.set("v.listId", cmp.get("v.recordId"));
        })
      )
      .catch(
        $A.getCallback(function (errMsg) {
          errMsg = errMsg && errMsg.message ? errMsg.message : errMsg;
          cmp.set("v.isLoading", false);
          self.util.showToast("Error", errMsg, "error");
          $A.get("e.force:closeQuickAction").fire();
        })
      );
  }
});