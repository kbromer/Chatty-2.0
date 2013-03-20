public with sharing class Chatty2_Comm {
    
    public Command__c outboundcommand;
    list<Inbound_Message__c> inboundmessages;
    string array_address;
    string thing_address;
    Thing__c thing;
    public id Parent_ID;
    
    public Chatty2_Comm(Command__c c, id ParentID){
        outboundcommand = c;
        Parent_ID = ParentID;
    }        
	
	public Chatty2_Comm(id CommandID, id ParentID){
		outboundcommand = [select id, RecordTypeID, Thing__c from Command__c where id = :CommandID limit 1];
        if (outboundcommand != null){	   
		  delete [select id from Chatty2_Confirmation_Queue__c where Name = :ParentID];
        }		  
		Parent_ID = ParentID;
	}
	
	public Chatty2_Comm(list<Inbound_Message__c> ibm){
	   inboundmessages = ibm;
	}
	
	
	public void Execute(){
		string return_message = '';
		system.debug('==========Executing Chatty2_Comm...');
		map<id, RecordType> crectypes = Chatty2_Constants.getCommandRecordTypes();
		
		if (outboundcommand != null){
            system.debug('==========Handling Outbound Command in Chatty2)Comm, ID is: ' + outboundcommand.Id);    
            thing = [select t.id, t.Component_Type__c, t.Array__r.Array_Address__c, t.Array__r.id, Thing_address__c from Thing__c t where t.id = :outboundcommand.Thing__c];
            array_address = thing.Array__r.Array_Address__c;                                    
            thing_address = thing.Thing_Address__c;
            
            if (array_address != null && thing_address != null){
                if (crectypes.get(outboundcommand.RecordTypeId).Name == 'Status'){
                    Chatty2_Comm.userGetRequest(array_address, thing_address, Parent_ID, outboundcommand.id, thing.Component_Type__c);
                }
                
                else if (crectypes.get(outboundcommand.RecordTypeId).Name == 'Action'){
                    Chatty2_Callout.doPostCallout(array_address, thing_address, Parent_ID, outboundcommand.id, thing.Component_Type__c);
                }                
            }
            else{
                return_message = label.BadArrayAddress;
            }                               
        }	
        
        else if(inboundmessages != null){
        	system.debug('==========Handling an inbound message in Chatty2_Comm');
        	createThingStatus(inboundmessages[0]);
        }
        else{
        	throw new Chatty2_Constants.ChattyException();
        }
	}
	
	private void createThingStatus(Inbound_Message__c ibm){
        Thing__c t = new Thing__c();
        system.debug('INBOUND IBM: ' + ibm.Source_Address__c);
        t = [select t.id, t.Name, t.Component_Type__c, t.Short_Description__c, t.Thing_Address__c
                      from Thing__c t 
                      where t.Array__r.Array_Address__c = :ibm.Source_Address__c and
                      t.Thing_Address__c = :ibm.Pin__c limit 1];
        
        if (t != null){ 
            string response = t.Short_Description__c + ' is currently reading ';     
            string value = ibm.Value__c;
            string tv = translateStatus(t.Component_Type__c, value);
            response += tv;
           
            FeedItem fi = new FeedItem(
                ParentId = t.id,
                CreatedById = Chatty2_Constants.getChattySettings().Chatty2_User__c,
                Body = response
            );
            insert fi;
            
            //handle command responses
            handleCommandResponses(t, tv, fi.id);
        }	
	}
	
	//user requesting status
	@future (callout = true)
	private static void userGetRequest(string array_address, string thing_address, id ParentID, id CommandID, string thing_name){ 
		string response = '';
		Command__c c = [select id, Action_Confirmation__c from Command__c where id = :CommandID];
		
        string value = Chatty2_Callout.doGetCallout(thing_address, array_address);
        
        //it was a clean transaction
        if (!value.startsWith('ERROR')){
            response = c.Action_Confirmation__c + ' ';
            response += translateStatus(thing_name, value);
        }
        //we had an error
        else{
        	response = value;
        }
        
        insert new FeedComment(
            FeedItemId = ParentId,
            CreatedById = Chatty2_Constants.getChattySettings().Chatty2_User__c,
            CommentBody = response                    
        );
    }
	
	//translates value of status, if needed
	private static string translateStatus(string thing_name, string value){
		Map<String, Schema.SObjectField> M = Schema.SObjectType.Sensor_Translator__c.fields.getMap();
            
        if (m.ContainsKey(thing_name + '__c')){
            string response = '';
            Sensor_Translator__c st = new Sensor_Translator__c(Value__c = value);
            insert st;      
            
            Schema.Describefieldresult f = m.get(thing_name + '__c').getDescribe(); 
            list<sobject> translation = database.query('select ' + 
            f.getName() + ' from Sensor_Translator__c where id = \'' + st.id + '\'');
            response += translation[0].get(f.getName());
            delete st;
            
            system.debug('RESPONSE IS =======================' + response);
            return response;
        }
        
        else{
          	return value;
        }	
	}
	
	
	//check for commands that need to be fired as a result of this
	//thing being updated
	private static void handleCommandResponses(Thing__c t, string value, id FIid){
        //get all commands for this thing with a 
        //formula status value
        
        for (Command__c c : [select c.Status_Formula__c, c.Formula_Response__c, c.Response_Text__c
                            from Command__c c where c.Thing__c = :t.id
                            and c.Status_Formula__c != null]){
            
            string statusformula = c.Status_Formula__c;  
            boolean hasConfirmation = false;                         	
            decimal v = decimal.valueOf(value);
            
            if (statusformula.startsWith('>')){
                statusformula = statusformula.replace('>', ' ');
                statusformula = statusformula.trim();
              
                if (v > decimal.valueOf(statusformula)){                	
            	    hasConfirmation = true;
                }            	   
            }

            else if (statusformula.startsWith('<')){
            	statusformula = statusformula.replace('<', '').trim();
                
                if (v < decimal.valueOf(statusformula)){                 
                    hasConfirmation = true;
                }                   
            }
            
            else if (statusformula.startsWith('=')){
            	statusformula = statusformula.replace('=', '').trim();
                
                if (v == decimal.valueOf(statusformula)){                 
                    hasConfirmation = true;
                }                   
            }
            
            else if (statusformula.startsWith('!=')){
            	statusformula = statusformula.replace('!=', '').trim();
                
                if (v != decimal.valueOf(statusformula)){
                    hasConfirmation = true;
                }                    
            }
            
            
            if (hasConfirmation){
            system.debug('C ID IS: ' + c.id);
            system.debug('C TEXT IS: ' + c.Response_Text__c);
                FeedComment fc = new FeedComment(
                    FeedItemId = FIId,
                    CreatedById = Chatty2_Constants.getChattySettings().Chatty2_User__c,
                    CommentBody = c.Response_Text__c
                );
                insert fc;
                
                if (c.Formula_Response__c != null){                
                    Chatty2_Confirmation_Queue__c ccq = new Chatty2_Confirmation_Queue__c(Name = FIId, CommandID__c = c.Formula_Response__c);
                    insert ccq;
                }                    
            }
        }
	}
}