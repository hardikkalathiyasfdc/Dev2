({
  loadData: function (cmp) {
    let self = this;
    cmp.set("v.isDataLoaded", false);
    cmp.set("v.isLoading", true);
    this.util
      .controllerPromise(cmp, "getColumns")
      .then(
        $A.getCallback(function (columns) {
          self.columns = columns;
          cmp.set("v.columns", columns);
          let params = {
            dataLoadId: cmp.get("v.dataLoaderId")
          };
          return self.util.controllerPromise(
            cmp,
            "loadUnconfirmedData",
            params
          );
        })
      )
      .then(
        $A.getCallback(function (result) {
          let previewData = [];
          if (result.records && result.records.length) {
            let orgNames = [];
            result.records.forEach((r) => {
              if (r.Organization_Name__c) {
                orgNames.push(r.Organization_Name__c);
              }
            });

            let action = cmp.get("c.normalizeOrgNames");
            action.setParams({
              names: orgNames
            });

            action.setCallback(this, (response) => {
              let normalizedMap = response.getReturnValue();
              self.setUnconfirmedRecords(cmp, result, normalizedMap);
            });
            $A.enqueueAction(action);
          }
          let params = {
            type: "validate",
            data: previewData
          };
          cmp.set("v.isDataLoaded", true);
          cmp.set("v.isLoading", false);
          cmp.set("v.disabledNext", false);
        })
      )
      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
        cmp.set("v.disabledNext", true);
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
          title: "Error",
          message: errMsg,
          type: "error",
          mode: "sticky"
        });
        toastEvent.fire();
      });
  },

  setUnconfirmedRecords: function (cmp, result, normalizedMap) {
    let unconfirmedRecords = [];
    let isSave = false;

    for (let rec of result.records) {
      let lowerCaseOrgName = rec.Organization_Name__c
        ? rec.Organization_Name__c.toLowerCase().trim()
        : "";
      let uploadedOrgCompareName = normalizedMap[rec.Organization_Name__c];
      let orgRec = result.orgs[lowerCaseOrgName];
      if (rec.Organization_Name__c && !rec.Organization_Id__c) {
        if (!orgRec) {
          rec.Organization_Id__c = "";
          rec.orgError = true;
          rec.orgErrorMsg = rec.Organization_Name__c + " not found in BRM";
        } else {
          let orgIds = [...Object.keys(orgRec)].filter((orgId) => {
            const orgName = orgRec[orgId];
            return (
              orgName === uploadedOrgCompareName ||
              orgName === "the" + uploadedOrgCompareName
            );
          });

          let countOrg = orgIds.length;

          if (countOrg === 0) {
            rec.Organization_Id__c = "";
            rec.orgError = true;
            rec.orgErrorMsg = rec.Organization_Name__c + " not found in BRM";
          } else if (countOrg > 1) {
            rec.Organization_Id__c = "";
            rec.orgError = true;
            rec.orgErrorMsg =
              "Multiple " +
              rec.Organization_Name__c +
              " found in BRM. Please search for correct one.";
          } else {
            let candidateId = orgIds[0];
            let candidateCompareName = normalizedMap[orgRec[candidateId]];

            if (
              !candidateCompareName ||
              candidateCompareName === uploadedOrgCompareName ||
              candidateCompareName === "the" + uploadedOrgCompareName
            ) {
              rec.Organization_Id__c = candidateId;
              rec.orgError = false;
              rec.orgErrorMsg = "";
              this.updateDlRecord(cmp, rec);
            } else {
              rec.Organization_Id__c = "";
              rec.orgError = true;
              rec.orgErrorMsg =
                "Potential match found for " +
                rec.Organization_Name__c +
                ". Please search for and confirm the correct organization.";
            }
          }
        }
      }
      if (
        rec.orgError ||
        rec.signError ||
        rec.assistantError ||
        rec.isError ||
        rec.IsReviewValidate__c
      ) {
        isSave = rec.IsReviewValidate__c;
        rec.IsReviewValidate__c = true;
        unconfirmedRecords.push(rec);
      }
    }
    cmp.set("v.unconfirmedRecords", unconfirmedRecords);
  },

  updateError: function (cmp, fieldChanged, recId) {
    let unconfirmedRecords = cmp.get("v.unconfirmedRecords");
    for (let rec of unconfirmedRecords) {
      if (fieldChanged == "Organization_Name__c" && rec.Id == recId)
        rec.orgError = false;
      if (fieldChanged == "Significant_Other__c" && rec.Id == recId)
        rec.signError = false;
      if (fieldChanged == "Assistant_Name__c" && rec.Id == recId)
        rec.assistantError = false;
    }
    cmp.set("v.unconfirmedRecords", unconfirmedRecords);
  },

  // BRME-6786: align the org error message with what the row's + button actually opens.
  // The lookup (reusableLookup) has already fetched the duplicate-modal candidates for this row.
  // hasCandidates=true  -> the + button shows "Potential Duplicate Records"  -> scenario 1/3 message.
  // hasCandidates=false -> the + button opens "Create Organization"          -> scenario 2 message.
  // V3 rows ("Potential match found for ...") are intentionally left unchanged (per ticket decision).
  updateOrgMessage: function (cmp, detail) {
    if (!detail || detail.fieldChanged !== "Organization_Name__c") return;
    let unconfirmedRecords = cmp.get("v.unconfirmedRecords");
    let changed = false;
    for (let rec of unconfirmedRecords) {
      if (String(rec.Id) !== String(detail.dlRecordId) || !rec.orgError) continue;
      let msg = rec.orgErrorMsg || "";
      // V3: "Potential match found for ..." keeps its existing message.
      if (msg.indexOf("Potential match found") === 0) continue;
      let newMsg = detail.hasCandidates
        ? "Similar records exist in BRM. Please review potential duplicates."
        : "Org not found in BRM. Please create new Organization.";
      if (msg !== newMsg) {
        rec.orgErrorMsg = newMsg;
        changed = true;
      }
    }
    if (changed) cmp.set("v.unconfirmedRecords", unconfirmedRecords);
  },

  updateDlRecord: function (cmp, record) {
    this.util
      .controllerPromise(cmp, "updateDataRecord", {
        dataRecord: record
      })
      .then(
        $A.getCallback(function (data) {
          this.updateError(cmp, fieldChanged, selectedRecord.dlRecordId);
          cmp.set("v.isLoading", false);
        })
      )
      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
        console.log(errMsg);
        self.util.showToastError(errMsg);
      });
  },

  normalizeOrgName: function (value) {
    if (!value) return "";

    let normalized = value
      .toString()
      .trim()
      .replace(/^the\s+/i, "")
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "") // Remove accents
      .replace(/[^a-zA-Z0-9\s,&]/g, "") // Remove punctuation EXCEPT commas
      .replace(/\s+/g, "") // Remove spaces
      .toLowerCase();

    return normalized;
  }
});