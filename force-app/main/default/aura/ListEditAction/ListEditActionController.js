({
  init: function (component, event, helper) {
    let navService = component.find("navService");
    let now = new Date().getTime();
    let pageReference = {
      type: "standard__component",
      attributes: {
        componentName: "c__ListViewInlineEditCmp"
      },
      state: {
        c__id: component.get("v.recordId"),
        c__now: now
      }
    };
    navService.navigate(pageReference);
  }
});