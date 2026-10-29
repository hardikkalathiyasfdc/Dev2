({
  loadData: function (cmp) {
    let self = this;
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
          return self.util.controllerPromise(cmp, "loadPreviewData", params);
        })
      )
      .then(
        $A.getCallback(function (result) {
          if (result.records && result.records.length) {
            self.setUnconfirmedRecords(cmp, result);
          }
          cmp.set("v.isDataLoaded", true);
          cmp.set("v.isLoading", false);
        })
      )

      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
        self.util.showToastError(errMsg);
      });
  },
  setUnconfirmedRecords: function (cmp, result) {
    let unconfirmedRecords = [];
    for (let rec of result.records) {
      if (
        (rec.Organization_Name__c &&
          result.orgs[rec.Organization_Name__c.toLowerCase()] &&
          Object.keys(result.orgs[rec.Organization_Name__c.toLowerCase()])
            .length > 1) ||
        (rec.Significant_Other__c &&
          result.contacts[rec.Significant_Other__c.toLowerCase()] &&
          Object.keys(result.contacts[rec.Significant_Other__c.toLowerCase()])
            .length > 1) ||
        (rec.Assistant_Name__c &&
          result.contacts[rec.Assistant_Name__c.toLowerCase()] &&
          Object.keys(result.contacts[rec.Assistant_Name__c.toLowerCase()])
            .length > 1)
      ) {
        rec.orgError =
          rec.Organization_Name__c &&
          result.orgs[rec.Organization_Name__c.toLowerCase()] &&
          Object.keys(result.orgs[rec.Organization_Name__c.toLowerCase()])
            .length > 1;
        rec.signError =
          rec.Significant_Other__c &&
          result.contacts[rec.Significant_Other__c.toLowerCase()] &&
          Object.keys(result.contacts[rec.Significant_Other__c.toLowerCase()])
            .length > 1;
        rec.assistantError =
          rec.Assistant_Name__c &&
          result.contacts[rec.Assistant_Name__c.toLowerCase()] &&
          Object.keys(result.contacts[rec.Assistant_Name__c.toLowerCase()])
            .length > 1;
        unconfirmedRecords.push(rec);
      }
    }
    cmp.set("v.unconfirmedRecords", unconfirmedRecords);
  },
  handleSetupNext: function (cmp) {
    let msgMap = this.getSetupMessages(cmp);
    if (msgMap.error.length) {
      this.util.showToastError(msgMap.error);
      return;
    }
    if (msgMap.warning) {
      cmp.set("v.showSetupWarning", true);
      return;
    }
    this.setupNext(cmp);
  },
  updateSetupRecords: function (cmp) {
    let self = this;
    return new Promise(
      $A.getCallback(function (resolve, reject) {
        self.updateSetupRecordsHelper(cmp, [], false, resolve, reject);
      })
    );
  },
  updateSetupRecordsHelper: function (cmp, rowList, isDone, resolve, reject) {
    if (isDone) {
      resolve(rowList);
      return;
    }
    let self = this;
    self.util
      .controllerPromise(cmp, "updateRecords", {
        dataId: cmp.get("v.dataLoaderId"),
        excelColumns: cmp.get("v.excelColumns"),
        offset: rowList.length,
        batchSize: self.batchSize
      })
      .then(
        $A.getCallback(function (results) {
          if (!results) {
            self.updateSetupRecordsHelper(cmp, rowList, true, resolve, reject);
            return;
          }
          for (let i = 0; i < results.length; i++) {
            rowList.push(results[i]);
          }
          self.updateSetupRecordsHelper(cmp, rowList, false, resolve, reject);
        })
      )
      .catch((errMsg) => {
        reject(errMsg);
      });
  },
  getSetupMessages: function (cmp) {
    let excelColumns = cmp.get("v.excelColumns");
    let msgMap = {};
    msgMap.error = "";
    msgMap.warning = false;
    if (!excelColumns || !excelColumns.length) {
      msgMap.error = "No excel column info found!";
      return msgMap;
    }

    for (let i = 0; i < excelColumns.length; i++) {
      let excelCol = excelColumns[i];
      let sfCell = excelCol.cells[0];
      let excelCell = excelCol.cells[1];
      if (excelCell.class == "red") {
        msgMap.error +=
          sfCell.value + " is a required column and must be mapped.\n";
      } else if (excelCell.class == "yellow") {
        msgMap.warning = true;
      }
    }
    return msgMap;
  },
  finish: function (cmp, params) {
    let self = this;
    cmp.set("v.isLoading", true);
    if (params.listName) {
      self.util
        .controllerPromise(cmp, "createList", { listName: params.listName })
        .then(
          $A.getCallback(function (listId) {
            params.listId = listId;
            self.upsertContacts(cmp, params);
          })
        )
        .catch((errMsg) => {
          self.util.showToastError(errMsg);
          cmp.set("v.isLoading", false);
        });
    } else {
      self.upsertContacts(cmp, params);
    }
  },
  upsertContacts: function (cmp, params) {
    let self = this;
    this.finishPromise(cmp, params)
      .then(
        $A.getCallback(function (results) {
          if (results.createdTotal) {
            let success =
              "Created " + results.createdSuccess + " new Contacts.";
            self.util.showToast("Success", success, "success");
          }
          if (results.updatedTotal) {
            success = "Updated " + results.updatedSuccess + " contacts.";
            self.util.showToast("Success", success, "success");
          }
          if (results.listTotal) {
            success = "Added " + results.listSuccess + " members to list.";
            self.util.showToast("Success", success, "success");
          }
          if (results.errorList && results.errorList.length) {
            let errorMsg = "";
            for (let i = 0; i < results.errorList.length; i++) {
              errorMsg = errorMsg + results.errorList[i];
            }
            self.util.showToast("Error", errorMsg, "error");
          }
          // BRME-5632: when there are per-row errors, build + download + persist the .xlsx report.
          if (results.rowErrorList && results.rowErrorList.length) {
            self.buildAndSaveErrorReport(cmp, results.rowErrorList, params.listId);
          }
          let hasImportErrors =
            (results.errorList && results.errorList.length > 0) ||
            (results.rowErrorList && results.rowErrorList.length > 0) ||
            results.createdSuccess < results.createdTotal ||
            results.updatedSuccess < results.updatedTotal ||
            results.listSuccess < results.listTotal;
          if (!hasImportErrors) {
            self.celebration(cmp);
          }
          return self.util.controllerPromise(cmp, "updateStage", {
            dataRecordId: cmp.get("v.dataLoaderId"),
            stage: "Complete"
          });
        })
      )
      .then(
        $A.getCallback(function (results) {
          cmp.set("v.isLoading", false);
          cmp.set("v.stage", "loadFile");
        })
      )
      .catch((errMsg) => {
        self.util.showToastError(errMsg);
        cmp.set("v.isLoading", false);
      });
  },
  finishPromise: function (cmp, params) {
    let self = this;
    return new Promise(
      $A.getCallback(function (resolve, reject) {
        let results = {};
        results.listTotal = 0;
        results.listSuccess = 0;
        results.updatedTotal = 0;
        results.updatedSuccess = 0;
        results.createdTotal = 0;
        results.createdSuccess = 0;
        results.errorList = [];
        results.rowErrorList = []; // BRME-5632: structured per-row errors for the report
        self.finishHelper(cmp, params, results, resolve, reject, 0);
      })
    );
  },

  // BRME-5632: build the import error report (.xlsx) from the structured per-row errors, download it for the
  // importing user, and persist it as a ContentVersion on the Data_Load__c (which also triggers the email).
  // Layout: A1 = original filename; row 2 blank; row 3 headers; data from row 4. Only error rows appear.
  // NOTE: the report columns/values come from each failed row's stored Excel_Row__c JSON (returned on the row
  // error); the in-memory v.uploadData is only a fallback (failed rows are already marked 'Completed').
  buildAndSaveErrorReport: function (cmp, rowErrors, listId) {
    let self = this;
    let dataLoaderId = cmp.get("v.dataLoaderId");
    try {
      let uploadRows = cmp.get("v.uploadData") || [];
      let byIndex = {};
      for (let i = 0; i < uploadRows.length; i++) byIndex[i] = uploadRows[i];
      let fileName = (cmp.get("v.fileName") || "DIT_Import") + "_Errors.xlsx";
      // buildErrorReportWorkbook is async (ExcelJS) — wait for the base64 before download/save
      Promise.resolve(
        self.buildErrorReportWorkbook(rowErrors, byIndex, cmp, listId)
      )
        .then(function (base64) {
          // BRME-5632: auto-download only when more than one error was reported; any error still gets saved/emailed.
          if (rowErrors.length > 1) {
            self.downloadBase64Xlsx(base64, fileName);
          }
          // persist to the Data_Load__c
          self.util.controllerPromise(cmp, "saveErrorReport", {
            dataLoadId: dataLoaderId,
            fileName: fileName,
            base64Data: base64
          });
        })
        .catch(function (e) {
          console.log("BRME-5632 report build error: " + (e && e.message));
          self.util.showToastError(
            "Could not build the error report: " + (e && e.message)
          );
        });
    } catch (e) {
      // surface report failures to the user instead of swallowing them
      console.log("BRME-5632 report build error: " + (e && e.message));
      self.util.showToastError(
        "Could not build the error report: " + (e && e.message)
      );
    }
  },

  // BRME-5632: build the .xlsx via ExcelJS (supports red highlighting of the failing fields). Returns a Promise<base64>.
  // Layout: A1 = DIT file name, row 2 blank, row 3 = headers, data from row 4. Only errored rows are listed.
  // Columns: [Error - Please Review] + [Technical Error] + [all DIT/upload columns] + [Contact ID 18] + [List Member ID 18] + [List ID 18].
  buildErrorReportWorkbook: function (rowErrors, recordsById, cmp, listId) {
    let ExcelJS = window.ExcelJS;
    if (!ExcelJS)
      return Promise.reject(new Error("ExcelJS library not loaded"));
    // original upload columns, in source order. Primary source = the Excel_Row__c JSON the Apex returns
    // on each row error. Fall back to v.uploadColumns, then the first record's keys.
    let uploadHeaders = [];
    for (let i = 0; i < rowErrors.length; i++) {
      if (rowErrors[i].excelRow) {
        try {
          uploadHeaders = Object.keys(JSON.parse(rowErrors[i].excelRow));
        } catch (e) {}
        if (uploadHeaders.length) break;
      }
    }
    if (!uploadHeaders.length) {
      let colMap = cmp.get("v.uploadColumns") || {};
      for (let lk in colMap) {
        if (colMap[lk]) uploadHeaders.push(colMap[lk]);
      }
    }
    if (!uploadHeaders.length) {
      for (let id in recordsById) {
        let rec0 = recordsById[id];
        if (rec0) {
          // uploadData rows are header→value maps already; DLR rows carry them as Excel_Row__c JSON
          let keys = [];
          if (rec0.Excel_Row__c) {
            try {
              keys = Object.keys(JSON.parse(rec0.Excel_Row__c));
            } catch (e) {}
          } else {
            keys = Object.keys(rec0);
          }
          if (keys.length) {
            uploadHeaders = keys;
            break;
          }
        }
      }
    }
    let usedList = !!listId || rowErrors.some(function (e) {
      return e.operation === "List Member" || e.listId;
    });
    let headers = ["Error - Please Review", "Technical Error"]
      .concat(uploadHeaders)
      .concat(["Contact ID 18"]);
    if (usedList) headers = headers.concat(["List Member ID 18", "List ID 18"]);
    // header text -> column index for quick highlight lookups
    let colIndex = {};
    headers.forEach(function (h, i) {
      colIndex[String(h).toLowerCase()] = i;
    });
    let redFill = {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: "FFF8CBAD" }
    }; // light red

    let workbook = new ExcelJS.Workbook();
    let ws = workbook.addWorksheet("Import Errors");
    // A1 = DIT file name; row 2 blank; row 3 = headers; data from row 4
    ws.getCell("A1").value = cmp.get("v.fileName") || "DIT_Import";
    ws.getRow(3).values = headers;
    ws.getRow(3).font = { bold: true };

    // group errors per source row (multiple errors combined)
    let byRow = {};
    rowErrors.forEach(function (e) {
      let k = e.rowId || "row" + e.rowIndex;
      if (!byRow[k]) byRow[k] = [];
      byRow[k].push(e);
    });
    let outRow = 4;
    Object.keys(byRow).forEach(function (k) {
      let errs = byRow[k];
      let first = errs[0];
      // match the source row by Data_Load_Record row index (rowIndex == uploadData index)
      let rec = recordsById[first.rowIndex];
      let plain = errs
        .map(function (e) {
          return selfPlain(e);
        })
        .join(" | ");
      let tech = errs
        .map(function (e) {
          return e.statusCode + ": " + e.message;
        })
        .join(" | ");
      let excelRow = {};
      // primary: the Excel_Row__c JSON returned on the row error
      if (first.excelRow) {
        try {
          excelRow = JSON.parse(first.excelRow);
        } catch (e) {}
      }
      // fallback: in-memory upload data row
      if (!Object.keys(excelRow).length && rec) {
        if (rec.Excel_Row__c) {
          try {
            excelRow = JSON.parse(rec.Excel_Row__c);
          } catch (e) {}
        } else {
          excelRow = rec;
        }
      }
      let rowVals = [plain, tech].concat(
        uploadHeaders.map(function (h) {
          return excelRow[h] != null ? String(excelRow[h]) : "";
        })
      );
      rowVals.push(
        first.contactId ||
          (first.operation !== "List Member" ? first.recordId : "") ||
          ""
      );
      if (usedList) {
        rowVals.push(first.listMemberId || "");
        rowVals.push(first.listId || listId || "");
      }
      let rowObj = ws.getRow(outRow);
      rowObj.values = rowVals;
      // highlight (red) the upload-column cells for the field(s) that caused the error
      errs.forEach(function (e) {
        if (!e.fields) return;
        String(e.fields)
          .split(",")
          .forEach(function (f) {
            f = String(f).trim();
            if (!f) return;
            let match = matchUploadHeader(f, uploadHeaders, colIndex);
            if (match != null) rowObj.getCell(match + 1).fill = redFill;
          });
      });
      outRow++;
    });
    return workbook.xlsx.writeBuffer().then(function (buf) {
      return bufferToBase64(buf);
    });

    // plain-language message: keep the validation message + add corrective action
    function selfPlain(e) {
      return (e.operation ? e.operation + " failed — " : "") + e.message;
    }

    // map a Salesforce error field API name (e.g. FirstName, LastName, Email) to a DIT upload column index.
    // Exact normalized match first so e.g. "FirstName" maps to the "First Name" column, not a partial/loose match.
    function matchUploadHeader(fieldName, uploadHeaders, colIndex) {
      let f = String(fieldName)
        .toLowerCase()
        .replace(/__c$/, "")
        .replace(/[_\s\-]/g, "");
      // pass 1: exact normalized equality
      for (let i = 0; i < uploadHeaders.length; i++) {
        let h = String(uploadHeaders[i])
          .toLowerCase()
          .replace(/[_\s\-]/g, "");
        if (h === f) return colIndex[String(uploadHeaders[i]).toLowerCase()];
      }
      // pass 2: known Salesforce field -> DIT header aliases
      let aliases = {
        firstname: "firstname",
        lastname: "lastname",
        email: "businessemail",
        phone: "businessphone",
        accountid: "organizationname",
        accountname: "organizationname"
      };
      let target = aliases[f];
      if (target) {
        for (let i = 0; i < uploadHeaders.length; i++) {
          let h = String(uploadHeaders[i])
            .toLowerCase()
            .replace(/[_\s\-]/g, "");
          if (h === target)
            return colIndex[String(uploadHeaders[i]).toLowerCase()];
        }
      }
      // pass 3: starts-with (field is a prefix of the header), guarded to avoid loose substring hits
      for (let i = 0; i < uploadHeaders.length; i++) {
        let h = String(uploadHeaders[i])
          .toLowerCase()
          .replace(/[_\s\-]/g, "");
        if (h.length >= f.length && h.indexOf(f) === 0)
          return colIndex[String(uploadHeaders[i]).toLowerCase()];
      }
      return null;
    }

    function bufferToBase64(buf) {
      let bytes = new Uint8Array(buf);
      let binary = "";
      let chunk = 0x8000;
      for (let i = 0; i < bytes.length; i += chunk) {
        binary += String.fromCharCode.apply(null, bytes.subarray(i, i + chunk));
      }
      return btoa(binary);
    }
  },

  // BRME-5632: download a base64 .xlsx via a temporary anchor.
  downloadBase64Xlsx: function (base64, fileName) {
    let byteChars = atob(base64);
    let byteNumbers = new Array(byteChars.length);
    for (let i = 0; i < byteChars.length; i++)
      byteNumbers[i] = byteChars.charCodeAt(i);
    let blobFile = new Blob([new Uint8Array(byteNumbers)], {
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    });
    let link = document.createElement("a");
    link.href = URL.createObjectURL(blobFile);
    link.download = fileName;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  },
  finishHelper: function (cmp, params, results, resolve, reject, offset) {
    console.log("params--" + JSON.stringify(params));
    params.offset = offset * params.batchSize;
    let self = this;
    self.util
      .controllerPromise(cmp, "createWithList", params)
      .then(
        $A.getCallback(function (incoming) {
          for (let key in results) {
            if (incoming[key]) {
              results[key] += incoming[key];
            }
          }
          if (incoming.done) {
            resolve(results);
            return;
          }
          let errList = incoming.errors;
          if (errList && errList.length) {
            results.errorList = results.errorList.concat(errList);
          }
          // BRME-5632: accumulate structured per-row errors for the downloadable report.
          if (incoming.rowErrors && incoming.rowErrors.length) {
            results.rowErrorList = results.rowErrorList.concat(
              incoming.rowErrors
            );
          }
          // if data processed and if we have Campaign Member records to create or update
          if (
            (incoming.memListToCreate && incoming.memListToCreate.length) ||
            (incoming.memListToUpdate && incoming.memListToUpdate.length)
          ) {
            // BRME-5632: use the structured member upsert so member errors are captured for the report (not swallowed).
            self.util
              .controllerPromise(cmp, "upsertMemberRecordsWithErrors", {
                listMembersToCreate: incoming.memListToCreate,
                listMembersToUpdate: incoming.memListToUpdate
              })
              .then((memberResult) => {
                let listSuccess =
                  memberResult && memberResult.successCount
                    ? memberResult.successCount
                    : 0;
                console.log("Success so far....", listSuccess);
                results.listSuccess += listSuccess; //Updating the list success record count
                if (
                  memberResult &&
                  memberResult.rowErrors &&
                  memberResult.rowErrors.length
                ) {
                  let memberErrorContext = incoming.memberErrorContext || {};
                  memberResult.rowErrors.forEach(function (rowError) {
                    let context = memberErrorContext[rowError.contactId];
                    if (context) {
                      rowError.rowId = context.rowId;
                      rowError.rowIndex = context.rowIndex;
                      rowError.excelRow = context.excelRow;
                    }
                  });
                  results.rowErrorList = results.rowErrorList.concat(
                    memberResult.rowErrors
                  );
                }
                self.finishHelper(
                  cmp,
                  params,
                  results,
                  resolve,
                  reject,
                  offset + 1
                ); //Calling recursively for next batch of records
              })
              .catch((error) => {
                console.error("Error creating records:", error);

                let message = "Unknown error";
                if (error && error.body && error.body.message) {
                  message = error.body.message;
                }

                const toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                  title: "Error",
                  message: message,
                  type: "error",
                  mode: "sticky"
                });
                toastEvent.fire();
              });
          } else {
            self.finishHelper(
              cmp,
              params,
              results,
              resolve,
              reject,
              offset + 1
            ); //Calling recursively for next batch of records
          }
        })
      )
      .catch((errMsg) => {
        reject(errMsg);
      });
  },
  setupNext: function (cmp) {
    cmp.set("v.isLoading", true);
    let self = this;
    self
      .updateSetupRecords(cmp)
      .then(
        $A.getCallback(function (results) {
          return self.util.controllerPromise(cmp, "updateStage", {
            dataRecordId: cmp.get("v.dataLoaderId"),
            stage: "preview"
          });
        })
      )
      .then(
        $A.getCallback(function (results) {
          cmp.set("v.isLoading", false);
          cmp.set("v.stage", "preview");
        })
      )
      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
        self.util.showToastError(errMsg);
      });
  },
  previewNext: function (cmp) {
    let previewData = cmp.get("v.previewData");
    let params = { type: "validate preview", data: previewData };
    let self = this;
    cmp.set("v.isLoading", true);
    cmp.set("v.isLoading2", true);

    this.util
      .runWorker("$Resource.DITWorker", params)
      .then(
        $A.getCallback(function (results) {
          cmp.set("v.isLoading", false);
          if (results && results.length) {
            cmp.set("v.showPreviewError", true);
            cmp.set("v.previewErrors", results);
            return;
          }
          let data = { Id: cmp.get("v.dataLoaderId"), Stage__c: "unconfirm" };
          return self.util.controllerPromise(cmp, "updateData", { data: data });
        })
      )
      .then(
        $A.getCallback(function (results) {
          cmp.set("v.isLoading", false);
          cmp.set("v.isLoading2", false);
          if (results) {
            self.showContact(cmp);
          }
        })
      )
      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
        cmp.set("v.isLoading2", false);
        self.util.showToastError(errMsg);
      });
  },
  unconfirmNext: function (cmp) {
    let unconfirmedRecords = cmp.get("v.unconfirmedRecords");

    for (let contact of unconfirmedRecords) {
      if (contact.orgError || contact.signError || contact.signError) {
        this.util.showToastError(
          "You must review and resolve all errors before proceeding."
        );
        return;
      }
    }
    let self = this;
    cmp.set("v.isLoading", true);
    self.util
      .controllerPromise(cmp, "updateStage", {
        dataRecordId: cmp.get("v.dataLoaderId"),
        stage: "contact"
      })
      .then(
        $A.getCallback(function (results) {
          cmp.set("v.isLoading", false);
          cmp.set("v.stage", "contact");
        })
      )
      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
        self.util.showToastError(errMsg);
      });
  },
  contactNext: function (cmp) {
    let contactList = cmp.get("v.contactList");
    for (let i = 0; i < contactList.length; i++) {
      let contact = contactList[i];
      if (!contact.isDeleted && !contact.isConfirmed) {
        this.util.showToastError(
          "You must confirm all contacts before proceeding."
        );
        return;
      }
    }
    let self = this;
    cmp.set("v.isLoading", true);
    self.util
      .controllerPromise(cmp, "updateStage", {
        dataRecordId: cmp.get("v.dataLoaderId"),
        stage: "create"
      })
      .then(
        $A.getCallback(function (results) {
          cmp.set("v.isLoading", false);
          cmp.set("v.stage", "create");
        })
      )
      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
        self.util.showToastError(errMsg);
      });
  },
  showContact: function (cmp) {
    cmp.set("v.showPreviewError", false);
    cmp.set("v.stage", "unconfirm");
  },
  handlePreviewCellChange: function (cmp, row, cell) {
    let previewData = cmp.get("v.previewData");
    if (
      !previewData ||
      !previewData.length ||
      row > previewData.length ||
      cell > previewData[0].cells.length
    ) {
      return;
    }
    let self = this;
    let data = previewData[row].cells[cell];
    cmp.set("v.isLoading", true);
    let params = {
      orgName: data.value,
      row: row,
      col: cell,
      objName: data.obj
    };
    this.util
      .controllerPromise(cmp, "getDupe", params)
      .then(
        $A.getCallback(function (result) {
          let dupe = {};
          if (result) {
            dupe.name = result.name;
            dupe.row = result.row;
            dupe.col = result.col;
            dupe.data = result.data;
            dupe.object = result.object;
          }
          cmp.set("v.dupe", dupe);
          if (dupe.data && dupe.data.length) {
            cmp.set("v.showDupe", true);
          } else {
            self.createRecord(cmp);
          }
          cmp.set("v.isLoading", false);
        })
      )
      .catch((errMsg) => {
        cmp.set("v.isLoading", false);
        self.showToastError(errMsg);
      });
  },
  createRecord: function (cmp) {
    var createRecordEvent = $A.get("e.force:createRecord");
    let dupe = cmp.get("v.dupe");

    createRecordEvent.setParams({
      entityApiName: dupe.object,
      panelOnDestroyCallback: function (event) {
        if (windowHref !== window.location.href) {
          let splitPath = window.location.pathname.split(sObjectName + "/");
          let newId = "";
          if (splitPath.length > 1) {
            newId = splitPath[1].split("/")[0];
          }
          window.history.back();
          let previewData = cmp.get("v.previewData");
          let dupe = cmp.get("v.dupe");
          let cell = previewData[dupe.row].cells[dupe.col];
          cell.id = item.Id;
          cell.value = item.Name;
          cmp.set("v.previewData", previewData);
        }
      }
    });
    createRecordEvent.fire();
  },
  // Method for celebration confetti mode
  celebration: function (component) {
    var end = Date.now() + 5 * 1000;

    var interval = setInterval(function () {
      if (Date.now() > end) {
        return clearInterval(interval);
      }

      confetti({
        particleCount: 450,
        startVelocity: 30,
        spread: 360,
        ticks: 60,
        origin: {
          x: Math.random(),
          // since they fall down, start a bit higher than random
          y: Math.random() - 0.2
        }
      });
    }, 200);
  }
});