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
                    Chatty2_Comm.userPostRequest(array_address, thing_address, Parent_ID, outboundcommand.id, thing.Component_Type__c);
                }                
            }
            else{
                return_message = label.BadArrayAddress;
            }                               
        }	
        
        //a call out is requesting a pin
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
        t = [select t.id, t.Component_Type__c, t.Short_Description__c 
                      from Thing__c t 
                      where t.Array__r.Array_Address__c = :ibm.Source_Address__c and
                      t.Thing_Address__c = :ibm.Pin__c];
        
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
	
	@future (callout=true)
	private static void userPostRequest(string array_address, string thing_address, id ParentID, id CommandID, string thing_name){
		string response = '';
        Command__c c = [select id, Actions__c, Action_Value__c, Action_Confirmation__c from Command__c where id = :CommandID];
		string commentbody;
		string action;
		
		FeedComment fc = new FeedComment(FeedItemID = ParentId, 
            CreatedByID = Chatty2_Constants.getChattySettings().Chatty2_User__c            
         );
		
		if (c.Actions__c == 'On'){
			action = 'HIGH';
		}
		else if (c.Actions__c == 'Off'){
			action = 'LOW';
		}
		else if (c.Actions__c == 'Value'){
			action = c.Action_Value__c;
		}
		else{
			throw new Chatty2_Constants.ChattyException();
		}
		
	    try{
            Http h = new http();
            HttpRequest req = new HttpRequest();
            string endpoint = 'http://' + array_address + '/' + thing_address + 
            '/' + action;  
            req.setEndpoint(endpoint);
            system.debug('ENDPOINT: ' + endpoint);        
            req.setMethod('POST');
            req.setHeader('Content-Length', string.valueof(action.length()));
            HTTPResponse res = h.send(req);
            
            if (res.toString().contains('200') && res.toString().contains('OK')){
                commentbody = c.Action_Confirmation__c;              
            }
            else{
            	commentbody = 'Uh oh... ' + res.toString();
            }
     	}
		catch (Exception e){
            commentbody = e.getMessage();		      
		}
		finally{
		  fc.CommentBody = commentbody;
		  insert fc;
		}
	}
	
	//handles arduino calling for status check
	@future (callout=true)
	private static void getThingStatus(string array_address, string thing_address){
		Thing__c t = new Thing__c();
		t = [select t.id, t.Component_Type__c, t.Short_Description__c 
		              from Thing__c t 
		              where t.Array__r.Array_Address__c = :array_address and
		              t.Thing_Address__c = :thing_address];
        if (t != null){	
        	
        	string response = t.Short_Description__c + ' is currently reading ';	 
		    string value = doGetCallout(thing_address, array_address);
            string tv;
            //if not comm error, do the translation, if needed
            if (!value.startsWith('ERROR')){
            	tv = translateStatus(t.Component_Type__c, value);
                response += tv;
            }
            //there was a comm error
            else{
            	response = value;
            }
            
            FeedItem fi = new FeedItem(
                ParentId = t.id,
                CreatedById = Chatty2_Constants.getChattySettings().Chatty2_User__c,
                Body = response
            );
            
            insert fi; 
            if (!value.startsWith('ERROR')){
            	handleCommandResponses(t, tv, fi.id);
            }
        }
	}	
	
	//user requesting status
	@future (callout=true)
	private static void userGetRequest(string array_address, string thing_address, id ParentID, id CommandID, string thing_name){ 
		string response = '';
		Command__c c = [select id, Action_Confirmation__c from Command__c where id = :CommandID];
		
        string value = doGetCallout(thing_address, array_address);
        
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
        
       
        list <id> commandsToExecute = new list <id>();
        for (Command__c c : [select c.Status_Formula__c, c.Formula_Response__c 
                            from Command__c c where c.Thing__c = :t.id
                            and c.Status_Formula__c != null and 
                            c.Formula_Response__c != null]){
            
            string statusformula = c.Status_Formula__c;  
                                     	
            decimal v = decimal.valueOf(value);
            
            if (statusformula.startsWith('>')){
                statusformula = statusformula.replace('>', ' ');
                statusformula = statusformula.trim();
              
                if (v > decimal.valueOf(statusformula))                	
            	   commandsToExecute.add(c.Formula_Response__c);
            }

            else if (statusformula.startsWith('<')){
            	statusformula = statusformula.replace('<', '').trim();
                
                if (v < decimal.valueOf(statusformula))                 
                   commandsToExecute.add(c.Formula_Response__c);
            }
            
            else if (statusformula.startsWith('=')){
            	statusformula = statusformula.replace('=', '').trim();
                
                if (v == decimal.valueOf(statusformula))                 
                   commandsToExecute.add(c.Formula_Response__c);
            }
            
            else if (statusformula.startsWith('!=')){
            	statusformula = statusformula.replace('!=', '').trim();
                
                if (v != decimal.valueOf(statusformula))                 
                   commandsToExecute.add(c.Formula_Response__c);
            }
        }
        
        map<id, Command__c> cmap = new map<id, Command__c>([select id, Thing__c, RecordTypeID, Response_Text__c from Command__c where id IN :commandsToExecute]);
        
        //as long as we have commands to execute
        if (cmap.keySet().size() > 0){
            Chatty2_Comm c2cm = new Chatty2_Comm(cmap.get(commandsToExecute[0]), FiID);
            Chatty2_ChattyMain c2c = new Chatty2_ChattyMain(c2cm);        	
            c2c.execute();
        }
      		
	}
	
	private static string doGetCallout(string thing_name, string array_address){
        string value;
        try{
            Http h = new http();
            HttpRequest req = new HttpRequest();
            string endpoint = 'http://' + array_address + '/' + thing_name;  
            req.setEndpoint(endpoint);
            system.debug('ENDPOINT: ' + endpoint);        
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            HTTPResponse res = h.send(req);
            system.debug('RESPONSE BODY IS: ' + res.getBody());
            JSONParser parser = JSON.createParser(res.getBody());
            
            parser.nextToken();    
            parser.nextValue();
            
            value = parser.getText();
        }
        catch (Exception e){
        	value = 'ERROR: ' + e.getMessage();
        }
		finally{
            return value;	
		}
		return null;
	}
	

}