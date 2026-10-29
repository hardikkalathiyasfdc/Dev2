window.cmputil = function () {
  return {
    getErrorMessages: function (errors) {
      var errorMessages = [];
      for (var i = 0; i < errors.length; i++) {
        if (typeof errors[i].message != "undefined") {
          errorMessages.push(errors[i].message);
        }
        if (typeof errors[i].pageErrors != "undefined") {
          var pageErrors = errors[i].pageErrors;
          for (var j = 0; j < pageErrors.length; j++) {
            errorMessages.push(pageErrors[j].message);
          }
        }
        if (typeof errors[i].fieldErrors != "undefined") {
          var fieldErrorsObj = errors[i].fieldErrors;
          for (var key in fieldErrorsObj) {
            var fieldErrors = fieldErrorsObj[key];
            for (var j = 0; j < fieldErrors.length; j++) {
              errorMessages.push(fieldErrors[j].message);
            }
          }
        }
      }
      return errorMessages;
    },
    closeQuickAction: function (component, refresh) {
      $A.get("e.force:closeQuickAction").fire();
      if (refresh == true) $A.get("e.force:refreshView").fire();
    },
    showToast: function (title, message, type) {
      let messageString = "";
      if (Array.isArray(message)) {
        messageString = message.join("\n");
      } else {
        messageString = message;
      }
      let mode = "dismissible";
      let toastEvent = $A.get("e.force:showToast");
      if (type == "error") {
        mode = "sticky";
      }
      toastEvent.setParams({
        title: title,
        message: messageString,
        mode: mode,
        type: type
      });
      toastEvent.fire();
    },
    goToRecord: function (recordId) {
      var navEvt = $A.get("e.force:navigateToSObject");
      navEvt.setParams({
        recordId: recordId,
        slideDevName: "related"
      });
      navEvt.fire();
    },
    controllerPromise: function (cmp, name, params) {
      let self = this;
      return new Promise(
        $A.getCallback(function (resolve, reject) {
          let funcName = "c." + name;
          let action = cmp.get(funcName);
          if (params) {
            action.setParams(params);
          }
          action.setCallback(this, function (response) {
            let state = response.getState();
            if (state === "SUCCESS") {
              resolve(response.getReturnValue());
              return;
            }

            if (state == "INCOMPLETE") {
              resolve("incomplete");
              return;
            }

            let msg = "unknown error.";
            let errors = response.getError();
            if (!errors) {
              reject(msg);
              return;
            }

            msg = "";
            for (let i = 0; i < errors.length; i++) {
              let temp = self.getErrMsg(errors[i]);
              if (temp && temp.length) {
                msg += temp + "\n";
              }
            }
            reject(msg);
            return;
          });
          $A.enqueueAction(action);
        })
      );
    },
    showToastError: function (msg, title) {
      msg = this.getErrMsg(msg);
      title = !title ? "Error!" : title;
      this.showToast(msg, title, "error");
    },
    showToast: function (msg, title, type) {
      let toastEvent = $A.get("e.force:showToast");
      let params = {};
      params.message = msg;
      if (title) {
        params.title = title;
      }
      if (type) {
        params.type = type;
      }
      toastEvent.setParams(params);
      toastEvent.fire();
    },
    getErrMsg: function (msg) {
      if (msg && typeof msg === "string") {
        return msg;
      } else {
        return this.getErrMsgHelper(msg);
      }
    },
    getErrMsgHelper: function (msg) {
      if (!msg) {
        return null;
      }
      if (typeof msg === "object" && msg.message) {
        return msg.message;
      }
      if (Array.isArray(msg)) {
        for (let i = 0; i < msg.length; i++) {
          let check = this.getErrMsgHelper(msg[i]);
          if (check != null) {
            return check;
          }
        }
      } else if (typeof msg === "object") {
        for (let key in msg) {
          let check = this.getErrMsgHelper(msg[key]);
          if (check != null) {
            return check;
          }
        }
      }
      return null;
    },
    runWorker: function (resourceName, params) {
      let self = this;
      return new Promise(
        $A.getCallback(function (resolve, reject) {
          let url = $A.get(resourceName);
          self.worker = new Worker(url);
          self.worker.postMessage(params);
          self.worker.onmessage = function (e) {
            if (e.data && e.data.error) {
              reject(e.data.error);
            } else {
              resolve(e.data);
            }
          };
        })
      );
    }
  };
};
