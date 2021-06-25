({
	loadUsersAndTargets : function(cmp) {
        var recId = cmp.get("v.recordId");
		var action = cmp.get("c.loadUsersAndScores");
        action.setParams({
            objId : recId,
        });
        action.setCallback(this, function(response) {
            cmp.set("v.progressVal", 90);
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnedData = response.getReturnValue();
                cmp.set("v.selectedUsers", returnedData.targetUsers);
                cmp.set("v.target", returnedData.target);
                cmp.set("v.currencyFlag", returnedData.isCurrency);
                var year = new Date(returnedData.target.CreatedDate).getFullYear();
                cmp.set("v.thisYear", year);
                cmp.set("v.progressVal", 100);
                cmp.set("v.isLoading", false);
                cmp.set("v.isCalculating", false);
                cmp.set("v.editMode", false);
            }
            else {
                cmp.set("v.progressVal", 100);
                alert("Failed, reason : "+response.getError());
                cmp.set("v.isLoading", false);
                cmp.set("v.isCalculating", false);
            }
        });
        $A.enqueueAction(action);
	},
    
    doReCalculate : function(cmp) {
        cmp.set("v.isCalculating", true);
        cmp.set("v.progressVal", 20);
		var recId = cmp.get("v.recordId");
        var action = cmp.get("c.reCalculateScores");
        action.setParams({
            objId : recId
        });
        action.setCallback(this, function(response) {
            cmp.set("v.progressVal", 50);
            var state = response.getState();
            if(state === "SUCCESS") {
                this.loadUsersAndTargets(cmp);
                cmp.set("v.progressVal", 75);
            }
            else {
                cmp.set("v.progressVal", 100);
                alert("Failed, reason : "+response.getError());
                cmp.set("v.isCalculating", false);
            }
        });
        $A.enqueueAction(action);
	},
})