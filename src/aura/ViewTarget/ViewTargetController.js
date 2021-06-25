({
	doInit : function(cmp, event, helper) {
        cmp.set("v.isLoading", true);
        helper.loadUsersAndTargets(cmp);
	},
    
    reCalculate : function(cmp, event, helper) {
        helper.doReCalculate(cmp);
	},
    
    editTargets : function(cmp, event, helper) {
        cmp.set("v.isLoading", true);
        var t_target = cmp.get("v.target");
		var action = cmp.get("c.loadUsers");
        action.setParams({
            objName : t_target.Object__c,
            fieldName : t_target.Field__c
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnedData = response.getReturnValue();
                cmp.set("v.users", returnedData.targetUsers);
                cmp.set("v.editMode", true);
                cmp.set("v.currencyFlag", returnedData.isCurrency);                    
                cmp.set("v.isLoading", false);
            }
            else {
                alert("Failed, reason : "+response.getError());
                cmp.set("v.isLoading", false);
            }
        });
        $A.enqueueAction(action);
    },
    
    cancelEdit : function(cmp, event, helper) {
        cmp.set("v.editMode", false);
    },
    
    updateTargets : function(cmp, event, helper) {
        cmp.set("v.isLoading", true);
		var recId = cmp.get("v.recordId");
        var action = cmp.get("c.upsertTargets");
        action.setParams({
            objId : recId,
            jsonString : JSON.stringify(cmp.get("v.selectedUsers"))
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                cmp.set("v.isLoading", false);
                helper.doReCalculate(cmp);
            }
            else {
                alert("Failed, reason : "+response.getError());
                cmp.set("v.isLoading", false);
            }
        });
        $A.enqueueAction(action);
	},
    
    getAllUsers : function(cmp, event, helper) {
        var searchText = cmp.find('searchInput').get('v.value');
        var selectedUsers = cmp.get("v.selectedUsers");
        var fullDataList = cmp.get("v.users");
        var resultList = [];
        var tempList = [];
        if(selectedUsers.length == 0) {
            tempList = fullDataList;
        }
        else {
            tempList = fullDataList.filter(function(objFromA) {
                return !selectedUsers.find(function(objFromB) {
                    return objFromA.userTar.UserId__c === objFromB.userTar.UserId__c
                })
            });
        }
        var regex;
        try {
            regex = new RegExp(searchText, "i");
            // filter checks each row, constructs new array where function returns true
            resultList = tempList.filter(row => 
				regex.test(row.userTar.Name) 
			);
        }
        catch(e) {
            // invalid regex, use full list
        }
        cmp.set("v.tempUsers", resultList);
    },
    
    itemSelected : function(cmp, event, helper) {
        var user_id = event.currentTarget.getAttribute('data-selectedval');
        if(user_id) {
            var resultList = cmp.get("v.users");
            var selectedUsers = cmp.get("v.selectedUsers");
            resultList.forEach(function(element) {
                if(element.userTar.UserId__c == user_id) {
                    console.log('selectedUser : '+element.userTar.Name);
                    selectedUsers.push(element);
                    return;
                }                
            });
            cmp.set("v.selectedUsers", selectedUsers);
            cmp.set("v.tempUsers", []); 
        }
    },
    
    clearSelection : function(cmp, event, helper) {
        console.log('event : '+JSON.stringify(event.getSource().get('v.name')));
        var user_id = event.getSource().get('v.name');  
        if(user_id) {
            var usersList = cmp.get("v.selectedUsers");
            var resultList = [];
            usersList.forEach(function(element) {
                if(element.userTar.UserId__c != user_id) {
                    console.log('selectedUser : '+element.userName);
                    resultList.push(element);
                }                
            });
            cmp.set("v.selectedUsers", resultList);
            cmp.set("v.tempUsers", []); 
        }
    },
})