global with sharing class Chatty2_Callout {
   
    @future (callout=true)
    global static void doPostCallout(string array_address, string thing_address, id ParentID, id CommandID, string thing_name){
        string response = '';
        Command__c c = [select id, Actions__c, Action_Value__c, Action_Confirmation__c from Command__c where id = :CommandID];
        string commentbody;
        string action;
        
        FeedComment fc = new FeedComment(FeedItemID = ParentId, 
            CreatedByID = Chatty2_Constants.getChattySettings().Chatty2_User__c            
         );
        //change
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
        	//throw exceptions
            throw new Chatty2_Constants.ChattyException();
        }

        if (Chatty2_Callout.userOwnsArray(array_address)){        
            try{
                Http h = new http();
                HttpRequest req = new HttpRequest();
                string endpoint = 'http://' + array_address + '/' + thing_address + 
                '/' + action;  
                req.setEndpoint(endpoint);
                system.debug('ENDPOINT: ' + endpoint);        
                req.setMethod('POST');
                req.setHeader('Content-Length', string.valueof(action.length()));
                HTTPResponse res;
                if (!system.Test.isRunningTest()){
                    res = h.send(req); 
                }
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
        else{
        	fc.CommentBody = label.ArrayNotOwned;
        	insert fc;
        }    
    }
    
            
    public static string doGetCallout(string thing_name, string array_address){
        string value ='';
        
        if (Chatty2_Callout.userOwnsArray(array_address)){
            try{
                Http h = new http();
                HttpRequest req = new HttpRequest();
                string endpoint = 'http://' + array_address + '/' + thing_name;  
                req.setEndpoint(endpoint);
                system.debug('ENDPOINT: ' + endpoint);        
                req.setMethod('GET');
                req.setHeader('Content-Type', 'application/json');
                HTTPResponse res;
                if (!system.Test.isRunningTest()){
                    res = h.send(req);	
                }
                system.debug('RESPONSE BODY IS: ' + res.getBody());
                JSONParser parser = JSON.createParser(res.getBody());
            
                parser.nextToken();    
                parser.nextValue();
            
                value = parser.getText();
            }
            catch (Exception e){
                value = 'ERROR:  ' + e.getMessage();
            }
            finally{
            	system.debug('VALUE IS===============================' + value);
                return value;   
            }
        }
        else{
        	value = label.ArrayNotOwned;
        }            
                    
        return value;
    }
    
    
    private static boolean userOwnsArray(string array_address){
        set<id> ownerIDs = new set<id>();
        boolean ownsArray = false;
        
    	for (Array_Owner__c a : [select id, User__c from Array_Owner__c where Array__r.Array_Address__c = :array_address]){
            ownerIDs.add(a.User__c);    		
    	}
    	
    	if (ownerIDs.contains(userInfo.getUserId())){
    		ownsArray = true;
    	}
    	
    	return ownsArray;
    }
    
}