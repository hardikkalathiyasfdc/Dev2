({
  init: function (cmp, event, helper) {
    helper.util = new cmputil();
    helper.batchSize = 500;
    cmp.set('v.dataLoaderId', null);
    cmp.set('v.dataLoad', null);
    helper.loadPreviousFileList(cmp);
  },
  handleUpload: function (cmp, event, helper) {
    let files = event.getSource().get("v.files");
    helper.handleUpload(cmp, files);
  },
  handleFileLoadChange: function (cmp, event, helper) {
    let id = cmp.get('v.previousFile');
    helper.loadFile(cmp, id);
  }
});