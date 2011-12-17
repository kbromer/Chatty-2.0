public with sharing class Chatty2_Comm {
    
    Command__c outboundcommand;
    list<Inbound_Message__c> inboundmessages;
    string array_address;
    string thing_address;
    Thing__c thing;
    id Parent_ID;
    
    public Chatty2_Comm(Command__c c, id ParentID){
        outboundcommand = c;
        Parent_ID = ParentID;
    }        
	
	public Chatty2_Comm(list<Inbound_Message__c> ibm){
	   inboundmessages = ibm;
	}
	
	
	public void Execute(){
		string return_message = '';
		
		map<id, RecordType> crectypes = Chatty2_Constants.getCommandRecordTypes();
		
		if (outboundcommand != null){
            
            thing = [select t.id, t.Component_Type__c, t.Array__r.Array_Address__c, t.Array__r.id, Thing_address__c from Thing__c t where t.id = :outboundcommand.Thing__c];
            array_address = thing.Array__r.Array_Address__c;                                    
            thing_address = thing.Thing_Address__c;
            
            if (array_address != null && thing_address != null){
                if (crectypes.get(outboundcommand.RecordTypeId).Name == 'Status'){
                    Chatty2_Comm.issueGetCommand(array_address, thing_address, Parent_ID, outboundcommand.id, thing.Component_Type__c);
                }
                
                else if (crectypes.get(outboundcommand.RecordTypeId).Name == 'Action'){
                    Chatty2_Comm.issuePostCommand(array_address, thing_address, Parent_ID, outboundcommand.id, thing.Component_Type__c);
                }                
            }
            else{
                return_message =  label.BadArrayAddress;
            }                               
        }	
        
        else if(inboundmessages != null){
                    	
        
        }
        else{
        	throw new Chatty2_Constants.ChattyException();
        }
	}
	
	
	@future (callout=true)
	private static void issuePostCommand(string array_address, string thing_address, id ParentID, id CommandID, string thing_name){
		string response = '';
        Command__c c = [select id, Actions__c, Action_Confirmation__c from Command__c where id = :CommandID];
		
					
			
        try{
            Http h = new http();
            HttpRequest req = new HttpRequest();
            string endpoint = 'http://' + array_address + '/' + thing_address;  
            req.setEndpoint(endpoint);
            system.debug('ENDPOINT: ' + endpoint);        
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            HTTPResponse res = h.send(req);
			
			
		}
		catch (Exception e){}
		finally{}
		
		
		
		
		
		
	}
	@future (callout=true)
	private static void issueGetCommand(string array_address, string thing_address, id ParentID, id CommandID, string thing_name){ 
		string response = '';
		Command__c c = [select id, Action_Confirmation__c from Command__c where id = :CommandID];
		
		try{
			Http h = new http();
            HttpRequest req = new HttpRequest();
            string endpoint = 'http://' + array_address + '/' + thing_address;  
            req.setEndpoint(endpoint);
            system.debug('ENDPOINT: ' + endpoint);        
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            HTTPResponse res = h.send(req);
            system.debug('RESPONSE BODY IS: ' + res.getBody());
            JSONParser parser = JSON.createParser(res.getBody());
            
            parser.nextToken();    
            parser.nextValue();
            
            system.debug('GETTING TEXT OF: ' + parser.getText());
          
            string value = parser.getText();
                                        
            //translate if needed
            response = c.Action_Confirmation__c + ' ';
            Map<String, Schema.SObjectField> M = Schema.SObjectType.Sensor_Translator__c.fields.getMap();
            system.debug('THINGS NAME: ' + thing_name);
            if (m.ContainsKey(thing_name + '__c')){
                system.debug('HAVE THING NAME');
            
                Sensor_Translator__c st = new Sensor_Translator__c(Value__c = value);
                insert st;      
                Schema.Describefieldresult f = m.get(thing_name + '__c').getDescribe();	
                system.debug('FIELDDESCRIBE NAME ' + f.getName());
                system.debug('TEST VALUE ' + st.TMP36F__c);
            	
            	list<sobject> translation = database.query('select ' + 
            	f.getName() + ' from Sensor_Translator__c where id = \'' + st.id + '\'');
            	
            	response += translation[0].get(f.getName());
            }
 
        }
        
 		catch (Exception e){
			response = e.getMessage();
		}
		
		finally{
		  insert new FeedComment(
                    FeedItemId = ParentId,
                    CreatedById = Chatty2_Constants.getChattySettings().Chatty2_User__c,
                    CommentBody = response                    
          );
		}
    
    }
	
	
	

}