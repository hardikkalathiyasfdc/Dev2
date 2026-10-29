({
	showToastAlert : function( message , variant) {
        console.log('I am here');
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : variant,
            message: message,
            duration:' 5000',
            type: variant,
        });
        toastEvent.fire();
    },
})