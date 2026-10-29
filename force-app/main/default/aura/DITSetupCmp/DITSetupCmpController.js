({
  init: function (component, event, helper) {
    helper.util = new cmputil();
    helper.init(component);
  },
  handleCellChange: function (cmp, event, helper) {
    let params = event.getParams();
    if (!params) {
      return;
    }
    let tableId = params.tableId;
    if (tableId != "setupTable") {
      return;
    }
    
    helper.handleSetupCellChange(cmp, params.row, params.cell);
  }
});