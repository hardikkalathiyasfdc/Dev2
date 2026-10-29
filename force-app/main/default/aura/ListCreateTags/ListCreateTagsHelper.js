({
  setListInfo: function (cmp) {
    cmp.set("v.isLoading", true);
    let self = this;
    let param = { recId: cmp.get("v.recordId") };
    this.util
      .controllerPromise(cmp, "getListInfo", param)
      .then(
        $A.getCallback(function (result) {
          if (!result || !Object.keys(result).length) {
            return;
          }
          cmp.set("v.listName", result.Name);
          cmp.set("v.listCount", result.NumberOfContacts);
          cmp.set("v.listRecId", result.recTypeId);
          cmp.set("v.isLoading", false);
          let warnMsg =
            result.recordName == "Account"
              ? "This function will add tags for all Organizations on this list."
              : "This function will add tags for all Contacts on this list.";
          cmp.set("v.warnMsg", warnMsg);
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
  },
  save: function (cmp) {
    cmp.set("v.isLoading", true);
    let self = this;
    let param = {
      recId: cmp.get("v.recordId"),
      tagId: cmp.get("v.selectedTagId")
    };
    this.util
      .controllerPromise(cmp, "saveTags", param)
      .then(
        $A.getCallback(function (result) {
          cmp.set("v.isLoading", false);
          self.util.showToast(
            "Success",
            "Tags successfully updated on contacts.",
            "success"
          );
          $A.get("e.force:closeQuickAction").fire();
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