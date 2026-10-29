({
  onfocus: function (component, event, helper) {
      component.set("v.oldSearchKey",component.get("v.SearchKeyWord"));
    $A.util.addClass(component.find("mySpinner"), "slds-show");
    var forOpen = component.find("searchRes");
    $A.util.addClass(forOpen, "slds-is-open");
    $A.util.removeClass(forOpen, "slds-is-close");
    var getInputkeyWord = component.get("v.SearchKeyWord");
    getInputkeyWord = getInputkeyWord ? getInputkeyWord : "";
    helper.searchHelper(component, event, getInputkeyWord);
  },
  onblur: function (component, event, helper) {
    component.set("v.listOfSearchRecords", null);
    var forclose = component.find("searchRes");
    $A.util.addClass(forclose, "slds-is-close");
    $A.util.removeClass(forclose, "slds-is-open");
 },
    inputOnblurfunction : function(component, event, helper) {
        window.setTimeout(
            $A.getCallback(function() {
                let oldSearchKey = component.get("v.oldSearchKey");
                var getInputkeyWord = component.get("v.SearchKeyWord");
                
                if(getInputkeyWord !=oldSearchKey || !getInputkeyWord){
                    component.set("v.oldSearchKey",getInputkeyWord);
                    var compEvent = component.getEvent("clearSelectedRecordEvent");
                    compEvent.setParams( {
                        recordByEvent:{},
                        cmpId: component.get("v.cmpId")
                    });
                    compEvent.fire();
                }
                var forclose = component.find("searchRes");
                $A.util.addClass(forclose, "slds-is-close");
                $A.util.removeClass(forclose, "slds-is-open");
            }), 200
        );
        if(!component.get("v.listOfSearchRecords") || component.get("v.listOfSearchRecords").length==0){
            var forclose = component.find("searchRes");
            $A.util.addClass(forclose, "slds-is-close");
            $A.util.removeClass(forclose, "slds-is-open");
        }
},
    
  keyPressController: function (component, event, helper) {
    let isEnter = component.get("v.enableEnter");
    var getInputkeyWord = component.get("v.SearchKeyWord");
    if (isEnter && event.which == 13) {
      getInputkeyWord = "";
      let searchList = component.get("v.listOfSearchRecords");
      if (searchList && searchList.length) {
        component.set("v.selectedRecord", searchList[0]);
        var compEvent = component.getEvent("oSelectedRecordEvent");
        compEvent.setParams({
          recordByEvent: searchList[0],
          cmpId: component.get("v.cmpId")
        });

        compEvent.fire();
         
        component.set("v.SearchKeyWord", null);
      }
      component.set("v.listOfSearchRecords", null);
      var forclose = component.find("searchRes");
      $A.util.addClass(forclose, "slds-is-close");
      $A.util.removeClass(forclose, "slds-is-open");
      return;
    }
      else
      {
          component.set("v.isStickyVal",true);
      }
    var forOpen = component.find("searchRes");
    $A.util.addClass(forOpen, "slds-is-open");
    $A.util.removeClass(forOpen, "slds-is-close");
    helper.searchHelper(component, event, getInputkeyWord);
  },
  clear: function (component, event, heplper) {
    var pillTarget = component.find("lookup-pill");
    var lookUpTarget = component.find("lookupField");

    $A.util.addClass(pillTarget, "slds-hide");
    $A.util.removeClass(pillTarget, "slds-show");

    $A.util.addClass(lookUpTarget, "slds-show");
    $A.util.removeClass(lookUpTarget, "slds-hide");
    component.set("v.SearchKeyWord", null);
    component.set("v.listOfSearchRecords", null);
    component.set("v.selectedRecord", {});
  },
  handleComponentEvent: function (component, event, helper) {
  
    var selectedAccountGetFromEvent = event.getParam("recordByEvent");
    component.set("v.selectedRecord", selectedAccountGetFromEvent);
   component.set("v.oldSearchKey",selectedAccountGetFromEvent.Name);
    var forclose = component.find("searchRes");
    $A.util.addClass(forclose, "slds-is-close");
    $A.util.removeClass(forclose, "slds-is-open");
    if (component.get("v.isStickyVal")) {
        if(selectedAccountGetFromEvent.Name)
      component.set("v.SearchKeyWord", selectedAccountGetFromEvent.Name);
    } else {
      component.set("v.SearchKeyWord", null);
    }

    component.set("v.listOfSearchRecords", null);
      
      
  },
  updateVal: function (cmp, event, helper) {
      let params = event.getParam("arguments");
      if(params.val){
          cmp.set("v.SearchKeyWord", params.val);
          cmp.find("input").set("v.value", params.val);
          $(cmp.find('input').getElement()).find('input').val(params.val);
       
      }
         var forclose = cmp.find("searchRes");
          $A.util.addClass(forclose, "slds-is-close");
          $A.util.removeClass(forclose, "slds-is-open");
  }
});