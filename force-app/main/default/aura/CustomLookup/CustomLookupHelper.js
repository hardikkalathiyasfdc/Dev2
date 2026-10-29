({
  searchHelper: function (component, event, getInputkeyWord) {
    var action = component.get("c.fetchLookUpValues");
    getInputkeyWord = this.formatInput(getInputkeyWord);
    let self = this;
    this.curSearchId = this.getSearchId();

    action.setParams({
      searchKeyWord: getInputkeyWord,
      objectName: component.get("v.objectAPIName"),
      whereClause: component.get("v.whereClause"),
      searchId: this.curSearchId
    });
    action.setCallback(this, function (response) {
      $A.util.removeClass(component.find("mySpinner"), "slds-show");
      var state = response.getState();
      if (state === "SUCCESS") {
        let res = response.getReturnValue();

        if (self.curSearchId != res.searchId) {
          return;
        }
        var storeResponse = res && res.list ? res.list : [];        
        if (storeResponse.length == 0) {
        	component.set("v.Message", "No Result Found...");
        } else {
          component.set("v.Message", "");
        }
        component.set("v.listOfSearchRecords", storeResponse);
      }
    });
    $A.enqueueAction(action);
  },
  getSearchId: function(){
    return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
      (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
    )+new Date().getTime();
  },
  formatInput: function (input) {
    if (!input || input == "") {
      return "";
    }
    let regexSpecialCharacters = [
    "\\", '"', "'", '_', "%"
	];

	regexSpecialCharacters.forEach(rgxSpecChar => 
    	input = input.replace(new RegExp("\\" + rgxSpecChar,"gm"), "\\" + 
	rgxSpecChar))
    return input;
  }
});