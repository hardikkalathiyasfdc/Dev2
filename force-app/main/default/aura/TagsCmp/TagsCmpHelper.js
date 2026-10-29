({
  setTags: function (cmp) {
    cmp.set("v.isLoading", true);
    let params = { recordId: cmp.get("v.recordId") };
    let self = this;
    this.util
      .controllerPromise(cmp, "getTags", params)
      .then(
        $A.getCallback(function (result) {
          cmp.set("v.isLoading", false);
          let tags = result && result.tags;
          if (tags) {
            cmp.set("v.tags", tags);
          }
          let whereClause = result && result.whereClause;
          if (whereClause) {
            cmp.set("v.whereClause", whereClause);
          }
          let helpText =
            result.recordName == "Account"
              ? "Use Tags to identify Organizations by specific topic. You can search for Tags alphabetically or by using keywords, just start typing!"
              : "Use Tags to identify Contacts by specific topic. You can search for Tags alphabetically or by using keywords, just start typing!";
          cmp.set("v.helpText", helpText);
        })
      )
      .catch(
        $A.getCallback(function (errMsg) {
          errMsg = errMsg && errMsg.message ? errMsg.message : errMsg;
          cmp.set("v.isLoading", false);
          self.util.showToast("Error", errMsg, "error");
        })
      );
  },
  saveTag: function (cmp, tag) {
    let tags = cmp.get("v.tags");
    if (this.isTagExists(tags, tag)  || !tag || !tag.Name) {
      return;
    }
    let self = this;
    cmp.set("v.isLoading", true);
    let params = {
      recordId: cmp.get("v.recordId"),
      tagId: tag.Id,
      tagName: tag.Name
    };
    this.util
      .controllerPromise(cmp, "saveTag", params)
      .then(
        $A.getCallback(function (newTag) {
          cmp.set("v.isLoading", false);
          if (!newTag) {
            return;
          }
          if (!newTag.label || newTag.label == "") {
            newTag.label = tag.Name;
          }
          tags.push(newTag);
          cmp.set("v.tags", tags);
        })
      )
      .catch(
        $A.getCallback(function (errMsg) {
          debugger;
          errMsg = errMsg && errMsg.message ? errMsg.message : errMsg;
          cmp.set("v.isLoading", false);
          self.util.showToast("Error", errMsg, "error");
        })
      );
  },
  isTagExists: function (cmp, tagsList, tag) {
    for (let i = 0; i < tagsList.length; i++) {
      if (tag.Id == tagsList[i].id) {
        self.util.showToast(
          "Error",
          tag.Name + " already exists on this tag",
          "error"
        );
        return true;
      }
    }
    return false;
  },
  removeTag: function (cmp, idx) {
    if (isNaN(idx) || idx < 0) {
      return;
    }

    let tags = cmp.get("v.tags");
    let tag = tags[idx];
    let self = this;
    cmp.set("v.isLoading", true);
    let params = { tagId: tag.id };
    this.util
      .controllerPromise(cmp, "delTag", params)
      .then(
        $A.getCallback(function () {
          cmp.set("v.isLoading", false);
          tags.splice(idx, 1);
          cmp.set("v.tags", tags);
        })
      )
      .catch(
        $A.getCallback(function (errMsg) {
          errMsg = errMsg && errMsg.message ? errMsg.message : errMsg;
          cmp.set("v.isLoading", false);
          self.util.showToast("Error", errMsg, "error");
        })
      );
  }
});