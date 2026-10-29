({
  init: function (cmp, event, helper) {
    helper.util = new cmputil();
    helper.maxSize = 50;
    helper.initColumns(cmp);
    helper.initOptions(cmp);
    helper.loadData(cmp);
  },
  handleTimeChange: function (cmp, evt, helper) {
    helper.loadData(cmp);
  },
  handleFilterChange: function (cmp, evt, helper) {
    cmp.set("v.curPage", 0);
    helper.setData(cmp);
  },
  handleHeaderAction: function (cmp, evt, helper) {
    let actionName = evt.getParam("action").name;
    let cols = cmp.get("v.columns");
    let colDef = evt.getParam("columnDefinition");
    let col = cols[cols.indexOf(colDef)];
    let filter = cmp.get("v.filterCols");
    let key =
      colDef.type != "url"
        ? colDef.fieldName
        : colDef.typeAttributes.label.fieldName;
    if (actionName != "all") {
      col.actions[0].checked = false;
      filter[key].all = false;
      for (let i = 0; i < col.actions.length; i++) {
        let act = col.actions[i];
        let name = act.name;
        if (name == actionName) {
          act.checked = !act.checked;
          filter[key][name] = act.checked;
          break;
        }
      }
    } else {
      col.actions[0].checked = !col.actions[0].checked;
      filter[key].all = col.actions[0].checked;
      for (let i = 0; i < col.actions.length; i++) {
        let act = col.actions[i];
        let name = act.name;
        if (name != "all") {
          act.checked = false;
          filter[key][name] = act.checked;
        }
      }
    }
    if (!col.actions[0].checked) {
      col.iconName = "utility:filterList";
    } else {
      delete col.iconName;
    }
    cmp.set("v.columns", cols);
    cmp.set("v.filterCols", filter);
    cmp.set("v.curPage", 0);
    helper.setData(cmp);
  },
  export: function(cmp, evt, helper){
    helper.export(cmp);
  },
  prevPage: function (cmp, evt, helper) {
    let curPage = cmp.get("v.curPage");
    curPage -= 1;
    cmp.set("v.curPage", curPage);
    helper.setData(cmp);
  },
  nextPage: function (cmp, evt, helper) {
    let curPage = cmp.get("v.curPage");
    curPage += 1;
    cmp.set("v.curPage", curPage);
    helper.setData(cmp);
  }
});