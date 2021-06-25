public without sharing class TargetController {
    @AuraEnabled
    public List<targetWrapper> targetUsers = new List<targetWrapper>();
    @AuraEnabled
    public List<picklistWrapper> objectChoices = new List<picklistWrapper>();
    @AuraEnabled
    public List<picklistWrapper> yearChoices = new List<picklistWrapper>();
    @AuraEnabled
    public List<picklistWrapper> intervalChoices = new List<picklistWrapper>();
    @AuraEnabled
    public String jsonStringOfFieldMap = '', jsonStringOfSubFieldMap = '';
    @AuraEnabled
    public Target__c target;
    @AuraEnabled
    public Boolean isCurrency = false;
    
    public static Map<String,String> fieldMap { get { 
        Map<String,String> fieldMap = new Map<String,String>();
        fieldMap.put('Amount','Amount');
        fieldMap.put('Closed Cases','isClosed');
        fieldMap.put('Open Cases','isClosed');
        fieldMap.put('All Cases','CreatedDate');
        fieldMap.put('Escalated Cases','IsEscalated');
        fieldMap.put('High Priority Cases','Priority');
        fieldMap.put('Medium Priority Cases','Priority');
        fieldMap.put('Lower Priority Cases','Priority');
        fieldMap.put('Converted Leads','isConverted');
        fieldMap.put('Not Converted Leads','isConverted');
        fieldMap.put('All Leads','CreatedDate');
        fieldMap.put('All Opportunities','CreatedDate');
        fieldMap.put('Closed Opportunities','isClosed');
        fieldMap.put('Closed Won Opportunities','isWon');
        return fieldMap;
    }}
    
    public static Map<String,String> subFieldMap { get { 
        Map<String,String> subFieldMap = new Map<String,String>();
        subFieldMap.put('Closed Cases','ClosedDate');
        subFieldMap.put('Open Cases','CreatedDate');
        subFieldMap.put('All Cases','CreatedDate');
        subFieldMap.put('Escalated Cases','CreatedDate');
        subFieldMap.put('High Priority Cases','CreatedDate');
        subFieldMap.put('Medium Priority Cases','CreatedDate');
        subFieldMap.put('Lower Priority Cases','CreatedDate');
        subFieldMap.put('Converted Leads','ConvertedDate ');
        subFieldMap.put('Not Converted Leads','CreatedDate');
        subFieldMap.put('All Leads','CreatedDate');
        subFieldMap.put('All Opportunities','CloseDate');
        subFieldMap.put('Closed Opportunities','CloseDate');
        subFieldMap.put('Closed Won Opportunities','CloseDate');
        return subFieldMap;
    }}
        
    @AuraEnabled
    public static TargetController loadFields() {
        TargetController ctrl = new TargetController();
        
        ctrl.objectChoices.add(new picklistWrapper('None', '', true, true));
        for(Schema.PicklistEntry val : Target__c.getSObjectType().getDescribe().fields.getMap().get('Object__c').getDescribe().getPickListValues()) {
            ctrl.objectChoices.add(new picklistWrapper(val.getLabel(), val.getValue(), false, false));
        }
        ctrl.intervalChoices.add(new picklistWrapper('None', '', true, true));
        for(Schema.PicklistEntry val : Target__c.getSObjectType().getDescribe().fields.getMap().get('Interval__c').getDescribe().getPickListValues()) {
            ctrl.intervalChoices.add(new picklistWrapper(val.getLabel(), val.getValue(), false, false));
        }
        
        Map<String,List<String>> fieldDependentPicklistMap = getDependentPicklistValues(Target__c.Field__c);
        Map<String,List<picklistWrapper>> fieldChoices = new Map<String,List<picklistWrapper>>();
        for(String str : fieldDependentPicklistMap.keySet()) {
            fieldChoices.put(str, new List<picklistWrapper>{new picklistWrapper('None', '', true, true)});
            for(String val : fieldDependentPicklistMap.get(str)) {
                if(!fieldChoices.containsKey(str))
                    fieldChoices.put(str, new List<picklistWrapper>{new picklistWrapper(val, val, false, false)});
                else
                    fieldChoices.get(str).add(new picklistWrapper(val, val, false, false));
            }
        }
        
        Map<String,List<String>> subFieldDependentPicklistMap = getDependentPicklistValues(Target__c.SubField__c);
        Map<String,List<picklistWrapper>> subFieldChoices = new Map<String,List<picklistWrapper>>();
        for(String str : subFieldDependentPicklistMap.keySet()) {
            subFieldChoices.put(str, new List<picklistWrapper>{new picklistWrapper('None', '', true, true)});
            for(String val : subFieldDependentPicklistMap.get(str)) {
                if(!subFieldChoices.containsKey(str))
                    subFieldChoices.put(str, new List<picklistWrapper>{new picklistWrapper(val, val, false, false)});
                else
                    subFieldChoices.get(str).add(new picklistWrapper(val, val, false, false));
            }
        }
        
        Integer thisYear = System.today().year();
        ctrl.yearChoices.add(new picklistWrapper(thisYear+'', thisYear+'', true, false));
        ctrl.yearChoices.add(new picklistWrapper((thisYear-1)+'', (thisYear-1)+'', false, false));
        ctrl.yearChoices.add(new picklistWrapper((thisYear-2)+'', (thisYear-2)+'', false, false));
        ctrl.jsonStringOfFieldMap = JSON.serialize(fieldChoices);
        ctrl.jsonStringOfSubFieldMap = JSON.serialize(subFieldChoices);
        return ctrl;
    }
    
    @AuraEnabled
    public static TargetController loadUsers(String objName, String fieldName) {
        TargetController ctrl = new TargetController();
        for(User targetUser : [SELECT Id,Name,SmallPhotoUrl FROM User WHERE isActive = True AND Profile.UserLicense.Name = 'Salesforce']) {
            targetWrapper wrap = new targetWrapper();
            wrap.photoURL = targetUser.SmallPhotoUrl;
            wrap.userTar = new Target_User__c();
            wrap.userTar.UserId__c = targetUser.Id;
            wrap.userTar.Name = targetUser.Name;
            ctrl.targetUsers.add(wrap);
        }
        ctrl.isCurrency = checkCurrency(objName, fieldMap.get(fieldName));
        return ctrl;
    }
    
    @AuraEnabled
    public static TargetController calculateScores(String objName, String fieldName, String subFieldName, String interval, String year, String jsonString) {
        TargetController ctrl = new TargetController();
        try {
            List<targetWrapper> wrappers = (List<targetWrapper>)JSON.deserialize(jsonString, List<targetWrapper>.class);
            Target__c target = new Target__c();
            target.Field__c = fieldName;
            target.SubField__c = subFieldName;
            target.Object__c = objName;
            target.Interval__c = interval;
            target.Year__c = year != Null ? Integer.valueOf(year) : Null;
            target.Name = interval+' '+fieldName+' '+(fieldName == 'Amount' ? subFieldName : '')+' '+(interval == 'Yearly' ? '' : year)+' by '+UserInfo.getName();
            target.Run_Time__c = System.now();
            insert target;
            ctrl.target = target;
            ctrl.isCurrency = checkCurrency(objName, fieldMap.get(fieldName));
            List<targetWrapper> newTargetUsers = queryData(ctrl.isCurrency, target, wrappers);
            List<Target_User__c> t_Users = new List<Target_User__c>();
            for(targetWrapper wrap : newTargetUsers) {
                Target_User__c t_user = wrap.userTar;
                t_user.Target__c = target.Id;
                t_user.Photo_URL__c = wrap.photoURL;
                t_Users.add(t_user);
            }
        	insert t_Users;
            ctrl.targetUsers = newTargetUsers;
        }
        catch(Exception e) {
            System.debug('Exception occured '+e.getMessage());
        }
    	return ctrl;
    }
    
    @AuraEnabled
    public static TargetController reCalculateScores(String objId) {
        TargetController ctrl = new TargetController();
        ctrl.target = getTarget(objId);
        ctrl.targetUsers = getTargetUsers(objId);
        ctrl.isCurrency = checkCurrency(ctrl.target.Object__c, fieldMap.get(ctrl.target.Field__c));
        try {
            ctrl.target.Run_Time__c = System.now();
            update ctrl.target;
            List<targetWrapper> newTargetUsers = queryData(ctrl.isCurrency, ctrl.target, ctrl.targetUsers);
            List<Target_User__c> t_Users = new List<Target_User__c>();
            for(targetWrapper wrap : newTargetUsers) {
                t_Users.add(wrap.userTar);
            }
        	update t_Users;
            ctrl.targetUsers = newTargetUsers;
        }
        catch(Exception e) {
            System.debug('Exception occured '+e.getMessage());
        }
    	return ctrl;
    }
    
    @AuraEnabled
    public static TargetController loadUsersAndScores(String objId) {
        TargetController ctrl = new TargetController();
        ctrl.target = getTarget(objId);
        ctrl.targetUsers = getTargetUsers(objId);
        ctrl.isCurrency = checkCurrency(ctrl.target.Object__c, fieldMap.get(ctrl.target.Field__c));
        return ctrl;
    }
    
    @AuraEnabled
    public static TargetController upsertTargets(String objId, String jsonString) {
        TargetController ctrl = new TargetController();
        try {
            List<targetWrapper> wrappers = (List<targetWrapper>)JSON.deserialize(jsonString, List<targetWrapper>.class);
            List<Target_User__c> deleteUsers = new List<Target_User__c>();
            Map<Id,Target_User__c> t_UserMap = new Map<Id,Target_User__c>();
            for(targetWrapper wrap : wrappers) {
                Target_User__c t_user = wrap.userTar;
                if(t_user.Id == Null) {
                    t_user.Target__c = objId;
                }
                t_UserMap.put(t_user.UserId__c, t_user);
            }
            for(targetWrapper wrap : getTargetUsers(objId)) {
                if(!t_UserMap.containsKey(wrap.userTar.UserId__c))
                    deleteUsers.add(wrap.userTar);
            }
            upsert t_UserMap.values();
            delete deleteUsers;
        }
        catch(Exception e) {
            System.debug('Exception occured '+e.getMessage());
        }
    	return ctrl;
    }
    
    public static List<targetWrapper> queryData(Boolean isCurrency, Target__c target, List<targetWrapper> wrappers) {
        String whereClause = 'WHERE';
        if(isCurrency == false) {
            if(target.Field__c == 'Closed Cases')
                whereClause += ' isClosed = true ';
            else if(target.Field__c == 'Escalated')
                whereClause += ' isEscalated = true ';
            else if(target.Field__c == 'High Priority')
                whereClause += ' Priority = \'High\' ';
            else if(target.Field__c == 'Medium Priority')
                whereClause += ' Priority = \'Medium\' ';
            else if(target.Field__c == 'Lower Priority')
                whereClause += ' Priority = \'Low\' ';
            else if(target.Field__c == 'Converted')
                whereClause += ' isConverted = true ';
            else if(target.Field__c == 'Not Converted')
                whereClause += ' isConverted = false ';
            else if(target.Field__c == 'Closed Opportunities')
                whereClause += ' isClosed = true ';
            else if(target.Field__c == 'Open Cases')
                whereClause += ' isClosed = false ';
        }
        else {
            if(target.Field__c == 'Amount') {
                if(target.SubField__c == 'Closed Won Opportunities')
                    whereClause += ' isWon = true ';
                if(target.SubField__c == 'Closed Opportunities')
                    whereClause += ' isClosed = true ';
            }
        }
        for(targetWrapper wrap : wrappers) {
            String query = 'select ';
            String countAggregate = isCurrency == true ? 'sum('+target.Field__c+') ' : 'count(Id) ';
            String monthAggregate = subFieldMap.containsKey(target.SubField__c) ? 'calendar_month('+subFieldMap.get(target.SubField__c)+')' : 'calendar_month('+subFieldMap.get(target.Field__c)+')';
            String yearAggregate = subFieldMap.containsKey(target.SubField__c) ? 'calendar_year('+subFieldMap.get(target.SubField__c)+')' : 'calendar_year('+subFieldMap.get(target.Field__c)+')';
            String newWhereClause = whereClause + (whereClause == 'WHERE' ? ' OwnerId = \''+wrap.userTar.UserId__c+'\'' : ' AND OwnerId = \''+wrap.userTar.UserId__c+'\'');
            if(target.Interval__c == 'Yearly')
                query+= ' '+countAggregate+' total,'+yearAggregate+' year from '+target.Object__c+' '+newWhereClause+' group by '+yearAggregate;
            else if(target.Interval__c == 'Monthly' || target.Interval__c == 'Quarterly')
                query+= ' '+countAggregate+' total,'+monthAggregate+' month,'+yearAggregate+' year from '+target.Object__c+' '+newWhereClause+' group by '+monthAggregate+','+yearAggregate;
            System.debug('Query Run '+query);
            List<AggregateResult> aggrs = (List<AggregateResult>)Database.query(query);
            Integer thisYear = System.today().year();
            wrap.userTar.Q1_A__c = 0;
            wrap.userTar.Q2_A__c = 0;
            wrap.userTar.Q3_A__c = 0;
            wrap.userTar.Q4_A__c = 0;
            for(AggregateResult aggr : aggrs) {
                if(target.Interval__c == 'Yearly') {
                    if((Integer)aggr.get('year') == (thisYear - 3))
                        wrap.userTar.Year1_A__c = (Decimal)aggr.get('total');
                    if((Integer)aggr.get('year') == (thisYear - 2))
                        wrap.userTar.Year2_A__c = (Decimal)aggr.get('total');
                    if((Integer)aggr.get('year') == (thisYear - 1))
                        wrap.userTar.Year3_A__c = (Decimal)aggr.get('total');
                }
                else if(target.Interval__c == 'Monthly') {
                    if((Integer)aggr.get('year') == Integer.valueOf(target.Year__c) && (Integer)aggr.get('month') == 1)
                        wrap.userTar.January_A__c = (Decimal)aggr.get('total');
                    if((Integer)aggr.get('year') == Integer.valueOf(target.Year__c) && (Integer)aggr.get('month') == 2)
                        wrap.userTar.February_A__c = (Decimal)aggr.get('total');
                    if((Integer)aggr.get('year') == Integer.valueOf(target.Year__c) && (Integer)aggr.get('month') == 3)
                        wrap.userTar.March_A__c = (Decimal)aggr.get('total');
                    if((Integer)aggr.get('year') == Integer.valueOf(target.Year__c) && (Integer)aggr.get('month') == 4)
                        wrap.userTar.April_A__c = (Decimal)aggr.get('total');
                    if((Integer)aggr.get('year') == Integer.valueOf(target.Year__c) && (Integer)aggr.get('month') == 5)
                        wrap.userTar.May_A__c = (Decimal)aggr.get('total');
                    if((Integer)aggr.get('year') == Integer.valueOf(target.Year__c) && (Integer)aggr.get('month') == 6)
                        wrap.userTar.June_A__c = (Decimal)aggr.get('total');
                    if((Integer)aggr.get('year') == Integer.valueOf(target.Year__c) && (Integer)aggr.get('month') == 7)
                        wrap.userTar.July_A__c = (Decimal)aggr.get('total');
                    if((Integer)aggr.get('year') == Integer.valueOf(target.Year__c) && (Integer)aggr.get('month') == 8)
                        wrap.userTar.August_A__c = (Decimal)aggr.get('total');
                    if((Integer)aggr.get('year') == Integer.valueOf(target.Year__c) && (Integer)aggr.get('month') == 9)
                        wrap.userTar.September_A__c = (Decimal)aggr.get('total');
                    if((Integer)aggr.get('year') == Integer.valueOf(target.Year__c) && (Integer)aggr.get('month') == 10)
                        wrap.userTar.October_A__c = (Decimal)aggr.get('total');
                    if((Integer)aggr.get('year') == Integer.valueOf(target.Year__c) && (Integer)aggr.get('month') == 11)
                        wrap.userTar.November_A__c = (Decimal)aggr.get('total');
                    if((Integer)aggr.get('year') == Integer.valueOf(target.Year__c) && (Integer)aggr.get('month') == 12)
                        wrap.userTar.December_A__c = (Decimal)aggr.get('total');
                }
                else if(target.Interval__c == 'Quarterly') {
                    if((Integer)aggr.get('year') == Integer.valueOf(target.Year__c) && ((Integer)aggr.get('month') == 1) || (Integer)aggr.get('month') == 2 || (Integer)aggr.get('month') == 3)
                        wrap.userTar.Q1_A__c += (Decimal)aggr.get('total');
                    if((Integer)aggr.get('year') == Integer.valueOf(target.Year__c) && ((Integer)aggr.get('month') == 4) || (Integer)aggr.get('month') == 5 || (Integer)aggr.get('month') == 6)
                        wrap.userTar.Q2_A__c += (Decimal)aggr.get('total');
                    if((Integer)aggr.get('year') == Integer.valueOf(target.Year__c) && ((Integer)aggr.get('month') == 7) || (Integer)aggr.get('month') == 8 || (Integer)aggr.get('month') == 9)
                        wrap.userTar.Q3_A__c += (Decimal)aggr.get('total');
                    if((Integer)aggr.get('year') == Integer.valueOf(target.Year__c) && ((Integer)aggr.get('month') == 10) || (Integer)aggr.get('month') == 11 || (Integer)aggr.get('month') == 12)
                        wrap.userTar.Q4_A__c += (Decimal)aggr.get('total');
                }
            }
        }
        return wrappers;
    }
    
    public static scoreWrapper getScore(Decimal actual, Decimal target) {
        scoreWrapper wrap = new scoreWrapper();
        wrap.actual = actual == Null ? 0 : actual;
        wrap.target = target == Null ? 0 : target;
        if(wrap.target != 0) {
        	Decimal scorePercent = (wrap.actual/wrap.target)*100;
            if(scorePercent < 50)
                wrap.color = 'lightcoral';
            else if(scorePercent >= 50 && scorePercent < 75)
                wrap.color = 'peachpuff';
            else if(scorePercent >= 75 && scorePercent <= 100)
                wrap.color = 'lightgreen';
            else if(scorePercent > 100)
                wrap.color = 'greenyellow';
            wrap.score = scorePercent/100;
        }
        else
            wrap.score = 0;
        return wrap;
    }
    
    public static Map<String, List<String>> getDependentPicklistValues(Schema.sObjectField dependToken) {
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();
        if (controlToken == null) {
            return new Map<String, List<String>>();
        }
        
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries;
        if(control.getType() != Schema.DisplayType.Boolean) {
            controlEntries = control.getPicklistValues();
        }
        
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<String,List<String>> dependentPicklistValues = new Map<String,List<String>>();
        for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
            if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
                List<String> base64chars =
                    String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    Object controlValue =
                        (controlEntries == null
                         ?   (Object) (index == 1)
                         :   (Object) (controlEntries[index].isActive() ? controlEntries[index].getLabel() : null)
                        );
                    Integer bitIndex = index / 6;
                    if (bitIndex > base64chars.size() - 1) {
                        break;
                    }
                    Integer bitShift = 5 - Math.mod(index, 6);
                    if(controlValue == null || (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0)
                        continue;
                    if(!dependentPicklistValues.containsKey((String) controlValue)) {
                        dependentPicklistValues.put((String) controlValue, new List<String>());
                    }
                    dependentPicklistValues.get((String) controlValue).add(entry.getLabel());
                }
            }
        }
        return dependentPicklistValues;
    }
    
    public static Target__c getTarget(String objId) {
    	List<Target__c> targets = [SELECT Id,Name,Object__c,Field__c,SubField__c,Interval__c,Year__c,Run_Time__c,CreatedDate FROM Target__c WHERE Id =: objId LIMIT 1];
        if(!targets.isEmpty())
            return targets.get(0);
        return Null;
    }
    
    public static List<targetWrapper> getTargetUsers(String objId) {
        List<targetWrapper> targerWrappers = new List<targetWrapper>();
    	for(Target_User__c t_user : [SELECT Id,Name,UserId__c,Q1_A__c,Q1_T__c,Q2_A__c,Q2_T__c,Q3_A__c,Q3_T__c,Q4_A__c,Q4_T__c,
				January_A__c,January_T__c,February_A__c,February_T__c,March_A__c,March_T__c,April_A__c,April_T__c,
				May_A__c,May_T__c,June_A__c,June_T__c,July_A__c,July_T__c,August_A__c,August_T__c,Photo_URL__c,
                September_A__c,September_T__c,October_A__c,October_T__c,November_A__c,November_T__c,December_A__c,December_T__c,
				Year1_A__c,Year1_T__c,Year2_A__c,Year2_T__c,Year3_A__c,Year3_T__c,Target__r.CreatedDate,
				Target__r.Interval__c,Target__r.Object__c,Target__r.Field__c FROM Target_User__c WHERE Target__c =: objId]) {
            
            targetWrapper wrap = new targetWrapper();
            wrap.userTar = t_user;
			wrap.photoURL = t_user.Photo_URL__c;
            
            Decimal actualTotal,targetTotal;
            if(t_user.Target__r.Interval__c == 'Monthly') {
                actualTotal = doSum(new List<Decimal> {t_user.January_A__c,t_user.February_A__c,t_user.March_A__c,t_user.April_A__c,t_user.May_A__c,t_user.June_A__c,t_user.July_A__c,t_user.August_A__c,t_user.September_A__c,t_user.October_A__c,t_user.November_A__c,t_user.December_A__c});
                targetTotal = doSum(new List<Decimal> {t_user.January_T__c,t_user.February_T__c,t_user.March_T__c,t_user.April_T__c,t_user.May_T__c,t_user.June_T__c,t_user.July_T__c,t_user.August_T__c,t_user.September_T__c,t_user.October_T__c,t_user.November_T__c,t_user.December_T__c});
            }
            else if(t_user.Target__r.Interval__c == 'Quarterly') {
                actualTotal = doSum(new List<Decimal> {t_user.Q1_A__c,t_user.Q2_A__c,t_user.Q3_A__c,t_user.Q4_A__c});
                targetTotal = doSum(new List<Decimal> {t_user.Q1_T__c,t_user.Q2_T__c,t_user.Q3_T__c,t_user.Q4_T__c});
            }
            else if(t_user.Target__r.Interval__c == 'Yearly') {
                actualTotal = doSum(new List<Decimal> {t_user.Year1_A__c,t_user.Year2_A__c,t_user.Year3_A__c});
                targetTotal = doSum(new List<Decimal> {t_user.Year1_T__c,t_user.Year2_T__c,t_user.Year3_T__c});
            }
			
            System.debug('actualTotal '+actualTotal);
            System.debug('targetTotal '+targetTotal);
                    
			wrap.scores = new Map<String,scoreWrapper>();
            wrap.scores.put('Q1', getScore(t_user.Q1_A__c,t_user.Q1_T__c));
			wrap.scores.put('Q2', getScore(t_user.Q2_A__c,t_user.Q2_T__c));
            wrap.scores.put('Q3', getScore(t_user.Q3_A__c,t_user.Q3_T__c));
			wrap.scores.put('Q4', getScore(t_user.Q4_A__c,t_user.Q4_T__c));
            wrap.scores.put('Jan', getScore(t_user.January_A__c,t_user.January_T__c));
			wrap.scores.put('Feb', getScore(t_user.February_A__c,t_user.February_T__c));
            wrap.scores.put('Mar', getScore(t_user.March_A__c,t_user.March_T__c));
			wrap.scores.put('Apr', getScore(t_user.April_A__c,t_user.April_T__c));
            wrap.scores.put('May', getScore(t_user.May_A__c,t_user.May_T__c));
			wrap.scores.put('Jun', getScore(t_user.June_A__c,t_user.June_T__c));
            wrap.scores.put('Jul', getScore(t_user.July_A__c,t_user.July_T__c));
			wrap.scores.put('Aug', getScore(t_user.August_A__c,t_user.August_T__c));
            wrap.scores.put('Sep', getScore(t_user.September_A__c,t_user.September_T__c));
			wrap.scores.put('Oct', getScore(t_user.October_A__c,t_user.October_T__c));
            wrap.scores.put('Nov', getScore(t_user.November_A__c,t_user.November_T__c));
			wrap.scores.put('Dec', getScore(t_user.December_A__c,t_user.December_T__c));
            wrap.scores.put('Year1', getScore(t_user.Year1_A__c,t_user.Year1_T__c));
			wrap.scores.put('Year2', getScore(t_user.Year2_A__c,t_user.Year2_T__c));
            wrap.scores.put('Year3', getScore(t_user.Year3_A__c,t_user.Year3_T__c));
            wrap.scores.put('Total', getScore(actualTotal,targetTotal));
            
            targerWrappers.add(wrap);
        }
        return targerWrappers;
    }
    
    public static Boolean checkCurrency(String objName, String fieldName) {
    	Schema.DisplayType fieldType = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap().get(fieldName).getDescribe().getType();
        if(fieldType == Schema.DisplayType.CURRENCY)
            return true;
        else
            return false;
    }
    
    public static Decimal doSum(List<Decimal> numbers) {
        Decimal sum = 0;
        for(Decimal num : numbers) {
            System.debug('LOL '+num);
            sum = sum + (num != Null ? num : 0);
        }
        return sum;
    }
        
    public class targetWrapper {
        @AuraEnabled
        public String photoURL;
        @AuraEnabled
        public Target_User__c userTar;
        @AuraEnabled
        public Map<String,scoreWrapper> scores = new Map<String,scoreWrapper>();
    }
    
    public class scoreWrapper {
        @AuraEnabled
        public Decimal actual,target,score;
        @AuraEnabled
        public String color;
    }
    
    public class picklistWrapper {
        @AuraEnabled
        public String label,value;
        @AuraEnabled
        public Boolean selected,disabled;
        public picklistWrapper(String label, String value, Boolean selected, Boolean disabled) {
            this.label = label;
            this.value = value;
            this.selected = selected;
            this.disabled = disabled;
        }
    }
}