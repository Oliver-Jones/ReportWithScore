({
	doInit : function(component, event, helper) {
        component.set("v.isLoading", true);
        component.set("v.selectedObject", "");
        component.set("v.selectedField", "");
        component.set("v.selectedSubField", "");
        component.set("v.selectedInterval", "");
        var currentYear = new Date().getFullYear();
        component.set("v.currentYear", currentYear);
        component.set("v.selectedYear", currentYear);
        
		var action = component.get("c.loadFields");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnedData = response.getReturnValue();
                component.set("v.objects", returnedData.objectChoices);
                component.set("v.intervals", returnedData.intervalChoices);
                component.set("v.years", returnedData.yearChoices);
                component.set("v.fieldMap", JSON.parse(returnedData.jsonStringOfFieldMap));
                component.set("v.subFieldMap", JSON.parse(returnedData.jsonStringOfSubFieldMap));
                component.set("v.step1", true);
                component.set("v.isLoading", false);
            }
            else {
                alert("Failed, reason : "+response.getError());
                component.set("v.isLoading", false);
            }
        });
        $A.enqueueAction(action);
	},
     
    handleObjectChange : function(component, event, helper) {
        var objectVal = component.find("objectSelection").get("v.value");
        if(objectVal != '') {
            component.set("v.selectedObject", objectVal);
            component.set("v.fields", component.get("v.fieldMap")[0][objectVal]);
            component.set("v.selectedField", component.get("v.fieldMap")[0][objectVal][0].value);
        }
        else {
            component.set("v.selectedObject", "");
            component.set("v.fields", "");
        }
    },
     
    handleFieldChange : function(component, event, helper) {
		var fieldVal = component.find("fieldSelection").get("v.value");
        if(fieldVal != '') {
            component.set("v.selectedField", fieldVal);
            if(component.get("v.subFieldMap")[0][fieldVal] != undefined) {
                component.set("v.subFields", component.get("v.subFieldMap")[0][fieldVal]);
                component.set("v.selectedSubField", component.get("v.subFieldMap")[0][fieldVal][0].value);
            }
        }
        else {
            component.set("v.selectedField", "");
            component.set("v.subFields", "");
        }
    },
    
    handleSubFieldChange : function(component, event, helper) {
		var subFieldVal = component.find("subFieldSelection").get("v.value");
        console.log('break '+subFieldVal);
        if(subFieldVal != '')
            component.set("v.selectedSubField", subFieldVal);
        else
            component.set("v.selectedSubField", "");
    },
     
    handleIntervalChange : function(component, event, helper) {
		var intervalVal = component.find("intervalSelection").get("v.value");
        if(intervalVal != '')
            component.set("v.selectedInterval", intervalVal);
        else
            component.set("v.selectedInterval", "");
    },
    
    handleYearChange : function(component, event, helper) {
		var yearVal = component.find("yearSelection").get("v.value");
        if(yearVal != '')
            component.set("v.selectedYear", yearVal);
        else
            component.set("v.selectedYear", "");
    },
     
    handleTargetCollection : function(component, event, helper) {
        component.set("v.isLoading", true);
		var action = component.get("c.loadUsers");
        action.setParams({
            objName : component.get("v.selectedObject"),
            fieldName : component.get("v.selectedField")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnedData = response.getReturnValue();
                component.set("v.users", returnedData.targetUsers);
                component.set("v.step1", false);
                component.set("v.step2", true);
                component.set("v.isCurrency", returnedData.isCurrency);                    
                component.set("v.isLoading", false);
                var userId = $A.get("$SObjectType.CurrentUser.Id");
                var tempList = component.get("v.users").filter(function(obj) {
                    return obj.userTar.UserId__c === userId;
                });
                component.set("v.selectedUsers", tempList);
            }
            else {
                alert("Failed, reason : "+response.getError());
                component.set("v.isLoading", false);
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
    
    handleCalculation : function(cmp, event, helper) {
        cmp.set("v.step1", false);
        cmp.set("v.step2", false);
        cmp.set("v.step3", true);
        cmp.set("v.progressVal", 20);
		var action = cmp.get("c.calculateScores");
        action.setParams({
            objName : cmp.get("v.selectedObject"),
            fieldName : cmp.get("v.selectedField"),
            subFieldName : cmp.get("v.selectedSubField"),
            interval : cmp.get("v.selectedInterval"),
            year : cmp.get("v.selectedYear"),
            jsonString : JSON.stringify(cmp.get("v.selectedUsers"))
        });
        action.setCallback(this, function(response) {
            cmp.set("v.progressVal", 50);
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set("v.progressVal", 80);
                var returnedData = response.getReturnValue();
                cmp.set("v.users", returnedData.targetUsers);
                cmp.set("v.step1", false);
                cmp.set("v.step2", false);
                cmp.set("v.progressVal", 100);
                var navEvent = $A.get("e.force:navigateToSObject");
                navEvent.setParams({
                    recordId: returnedData.target.Id,
                    slideDevName: "detail"
                });
                navEvent.fire();
            }
            else {
                alert("Failed, reason : "+response.getError());
            }
        });
        $A.enqueueAction(action);
    },
})