({
  selectRecord: function (component, event, helper) {
    var getSelectRecord = component.get("v.oRecord");
    var compEvent = component.getEvent("oSelectedRecordEvent");
    compEvent.setParams({
      recordByEvent: getSelectRecord,
      cmpId: component.get("v.cmpId")
    });    
    compEvent.fire();
  }
});