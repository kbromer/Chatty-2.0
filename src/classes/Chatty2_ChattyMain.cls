public with sharing class Chatty2_ChattyMain {
       
    /*** CLASS VARS ***/
    list<ChattyMessage> cmlist = new list<ChattyMessage>();
    id running_user_id;
    list<Command__c> commandlist = new list<Command__c>();
    list<Thing__c> thinglist = new list<Thing__c>();
    Chatty2_Settings__c ChattySettings = Chatty2_Constants.getChattySettings();
    string ChattyName = Chatty2_Constants.getChattyName();
    id ChattyId = Chatty2_Constants.getChattySettings().Chatty2_User__c;
    Chatty2_Comm c2cc;
    
    /*** CONSTRUCTORS ***/ 
    
    //tocheck: this could be done with one sobject constructor, but i think
    //instanceof has a higher overhead 
    
    //handle feeditems with mentions
    public Chatty2_ChattyMain(list<FeedItem> item_list){
        getUser(); 
        Chatty2_Constants.isExecuting = true;
        //if we're @ mentioning the chatty user
        for (FeedItem f : item_list){
            if ((f.Body.startsWith('@' + Chatty2_Constants.ChattyName) || f.ParentId == ChattyId) && f.CreatedById != ChattyId){
                system.debug('==========Chatty2_Main Handling a new Feed Item');
                cmlist.add(new ChattyMessage(f, this));
            }
        }
        if (!cmlist.isEmpty()){
            loadCommandsandThings();
        }       
    }
    //handle feedcomments with mentions
    public Chatty2_ChattyMain(list<FeedComment> comment_list){
        getUser();
        Chatty2_Constants.isExecuting = true;
        map<String, Chatty2_Confirmation_Queue__c> cql = Chatty2_Confirmation_Queue__c.getAll();
        for (FeedComment f : comment_list){
            if (f.CreatedById != ChattyId && (f.CommentBody.startsWith('@' + Chatty2_Constants.ChattyName) || f.ParentId == ChattyId)){
                system.debug('==========Chatty2_Main Handling a new Feed Comment');
                cmlist.add(new ChattyMessage(f, this));
            }
            
            //handle execution confirmations            
            else if (f.CreatedById != ChattyId && f.CommentBody.toLowerCase().startsWith('yes') && cql.containsKey(f.FeedItemID)){
                Chatty2_Comm c2cm = new Chatty2_Comm(cql.get(f.FeedItemID).CommandID__c, f.FeedItemID);
                c2cm.Execute();
            }
        }
        if (!cmlist.isEmpty()){
            loadCommandsandThings();
        }
    }       

    //handle posts to chatty's wall 
    public Chatty2_ChattyMain(list<User> user_list, map<id, User> oldMap){
        getUser();
        Chatty2_Constants.isExecuting = true;
        for (User u : user_list){
            //only get the feed item if its chatty, the status isn't null
            
            if (u.CurrentStatus != null //&& u.CurrentStatus != oldMap.get(u.id).CurrentStatus
               && u.CurrentStatus.startsWith('@' + ChattyName)){
                FeedItem f = [select id, body, createdById, ParentID, createdDate from FeedItem where ParentId = :u.id ORDER BY CreatedDate DESC LIMIT 1];
                system.debug('==========Chatty2_Main Handling a new User Update');
                cmlist.add(new ChattyMessage(f, this));
            }
        }   
        if (!cmlist.isEmpty()){
            loadCommandsandThings();
        }
        
    }
    //handle automated responses to array
    public Chatty2_ChattyMain(Chatty2_Comm incoming_comm){
    	Chatty2_Constants.isExecuting = true;
        c2cc = incoming_comm;
    }
    
    /*** PRIVATE METHODS ***/
    
    private void getUser(){
        running_user_id = UserInfo.getUserID();
    }
    private void loadCommandsandThings(){       
        commandlist = [select c.Thing__c, c.Status_Formula__c, c.Response_Text__c, 
                    c.RecordTypeId, c.Query__c, c.Match_Type__c, c.Id, 
                    c.Formula_Response__c, c.Command_Text__c, c.Actions__c, 
                    c.Action_Value__c, c.Action_Confirmation__c, Limit_to_User__c,
                    c.Query_Parameters__c, c.Query_Limit__c, c.Query_Order_By__c 
                    From Command__c c];
    }
    
    /*** PUBLIC METHODS ***/    

    public void execute(){
        system.debug('==========Chatty2_Main in execute() method');
        if (cmlist != null && !cmlist.isEmpty()){
        	system.debug('==========Chatty2_Main I have comment to deal with, number: ' + cmlist.size());
            for (ChattyMessage cm : cmlist){
                cm.executeStandardResponse();
            }        
        }
        
        if (c2cc != null){
            system.debug('==========Chatty2_Main dealing with a triggered reponse');
            executeTriggeredResponse();
        }
    }
    
    //handle the callout request from a thing's status change
    //first post the acknowledgment, then fire the request via C2CComm
    public void executeTriggeredResponse(){
    	 
    	Command__c command_to_execute = c2cc.outboundcommand;
    	id ParentID = c2cc.Parent_ID;
    	
    	insert new FeedComment(
                        FeedItemId = ParentId,
                        CreatedById = Chatty2_Constants.ChattySettings.Chatty2_User__c,
                        CommentBody = command_to_execute.Response_Text__c);
    	
    	system.debug('==========Chatty2_Main in triggered response');
    	//create a new comm object
    	Chatty2_Comm c2cm = new Chatty2_Comm(command_to_execute, ParentID);
    	c2cm.Execute();
    }
    
    /*** INNER CLASSES ***/

    public class ChattyMessage{
        
        string messagebody;
        Chatty2_ChattyMain mydad;
        id ParentId;
        
        public ChattyMessage(FeedComment fc, Chatty2_ChattyMain dad){
            mydad = dad;
            setupObj(fc);
        }
        public ChattyMessage(FeedItem fi, Chatty2_ChattyMain dad){
            mydad = dad;
            setupObj(fi);
        }
        public ChattyMessage(Chatty2_Comm c2c, Chatty2_ChattyMain dad){
           mydad = dad;
        }
                 
        public void setupObj(sobject obj){                                                   
            if (obj instanceof FeedComment){
                FeedComment f = (FeedComment)obj;
                messagebody = f.CommentBody.toLowerCase();
                ParentId = f.FeedItemId;
            }   
            else if (obj instanceof FeedItem){
                FeedItem f = (FeedItem)obj;
                messagebody = (string)f.Body.toLowerCase();
                ParentId = f.Id;                
            }
            else{
                throw new Chatty2_Constants.ChattyException();
            }
        } 
        
        //decide how to respond
        public void executeStandardResponse(){
            
            //list of feedposts in response to the issued commands
            list<FeedComment> responsepostlist = new list<FeedComment>();
            //list of valid commands that need some action
            list<Command__c> commandexecutionlist = new list<Command__c>();
            //list of commands requiring a chatty_comm instance/callout
            list<Command__c> calloutList = new list<Command__c>();
           
            integer matchingcommandcount = 0;
            //i'm torn, i could really skip the loading of the commands and sosl
            //for matches instead, but could i vary the command type in that scenario?
            //starts w/ versus contains? i'd need to do that in apex
            //and i'd also have to sosl for each chat post, not very bulk safe 
            //we'll use the static loop here since we have all commands and can use
            //apex text comprisons
            
            //clean response body of mentions and whitespace
            messagebody = messagebody.trim();
            messagebody = messagebody.replace('@' + mydad.ChattyName, '');
            messagebody = messagebody.replace('@' + mydad.ChattyName.toLowerCase(), '');
            messagebody = messagebody.trim();
            system.debug('MESSAGE BODY: ' + messagebody);
           
            //find all commands where the search text matches
            //and filter the ones we want to respond to
            for (Command__c c : mydad.commandlist){
                if(c.Command_Text__c != null){   
                   string ctext = (c.Command_Text__c.toLowerCase()).trim();  
                   system.debug('ctext: ' + ctext);
                   system.debug('messagebody: ' + messagebody);
                
                    if (c.Match_Type__c == 'Starts With'){
                        if(messagebody.startsWith(ctext)){
                            matchingcommandcount++;
                            commandexecutionlist.add(c);
                        }
                    }                
                    
                    else if (c.Match_Type__c == 'Contains'){
                        if(messagebody.contains(ctext)){
                            matchingcommandcount++;
                            commandexecutionlist.add(c);
                        }
                    }
                    //bad match type
                    else{
                        throw new Chatty2_Constants.ChattyException();
                    }
                }
            }//close matching loop
            
            //found no matches, so
            //unrecognized command
            if(commandexecutionlist.isEmpty()){
                insert new FeedComment(FeedItemId = ParentId, 
                CreatedById = Chatty2_Constants.ChattySettings.Chatty2_User__c,
                CommentBody = Label.UnknownCommand 
                );
            }
            
            //we have at least one matching command...
            //decide how to handle the command based on 
            //type and request
            else{
                map<id, RecordType> commandRecordTypes = Chatty2_Constants.getCommandRecordTypes();
                
                for (Command__c c : commandexecutionlist){
                   //if its just chat, simply provide the response
                    if (commandRecordTypes.get(c.RecordTypeId).Name == 'Chat'){
                        responsepostlist.add(
                        new FeedComment(
                        FeedItemId = ParentId,
                        CreatedById = Chatty2_Constants.ChattySettings.Chatty2_User__c,
                        CommentBody = c.Response_Text__c));
                    }
                    
                    //if its a query, provide a response to the query
                    else if (commandRecordTypes.get(c.RecordTypeId).Name == 'Query'){
                        responsepostList.addall(queryResult(c));                     
                    }
                    
                    else if (commandRecordTypes.get(c.RecordTypeId).Name == 'Action'){
                        responsepostlist.add(
                        new FeedComment(
                        FeedItemId = ParentId,
                        CreatedById = Chatty2_Constants.ChattySettings.Chatty2_User__c,
                        CommentBody = c.Response_Text__c
                        ));
                        
                        
                        /*  NEED TO FIGURE OUT HOW TO CHECK THIS EASILY AND WHERE
                        Thing__c t = [select t.Array__r.id from Thing__c where t.id = :c.Thing__c];
                        integer x = [select count() from Array_Owner__c where User__c = :UserInfo.getUserID() and Array__c = :t.Array__r.id];
                        */
                        calloutlist.add(c);
                    }
                    
                    else if (commandRecordTypes.get(c.RecordTypeId).Name == 'Status'){
                        responsepostlist.add(
                        new FeedComment(
                        FeedItemId = ParentId,
                        CreatedById = Chatty2_Constants.ChattySettings.Chatty2_User__c,
                        CommentBody = c.Response_Text__c
                        ));                        
                        calloutlist.add(c);
                    }
                }
            }
        
            if (!responsepostlist.isEmpty()) insert responsepostlist;
                           
            //send the commands out for processing
            list<FeedComment> callOutResponses = new list<FeedComment>();
      
            if (!calloutlist.isEmpty()){
                for (Command__c c : calloutlist){
                    Chatty2_Comm c2c = new Chatty2_Comm(c, ParentID);
                    c2c.Execute();                    
                }   
            }               
        
        }//close executeResponse
        
        private list<FeedComment> queryResult(Command__c c){
            list<FeedComment> returnlist = new list<FeedComment>();
            
            if(c.Query__c != null){
                                                                                    
                string soql = '';
                soql += c.Query__c;
                soql = soql.toLowerCase();
                
                //extract the field list
                string q = soql;
                integer x = soql.indexOf('from');
                q = q.substring(0, x);
                system.debug('PLUCKED OUT THE SUBSTRING: ' + q);
                q = q.replace('select', '');
                q = q.trim();
                system.debug('FIELD LIST: ' + q);
                list<string> fieldlist = q.split(',');
                
                if (c.Limit_to_User__c){
                    soql += ' WHERE OwnerId = \'' + UserInfo.getUserID() + '\'';
                }
                
                if (c.Query_Parameters__c != null){
                    if (c.Limit_to_User__c){
                        soql+= ' AND ';
                    }                        
                    else{
                        soql += ' WHERE ';
                    }
                    soql += c.Query_Parameters__c;
                }
                            
                if (c.Query_Order_By__c != null){
                    soql += ' ORDER BY ' + c.Query_Order_By__c + ' ';
                }
                
                soql += ' LIMIT ' + c.Query_Limit__c;
                system.debug('QUERY: ' + soql);
                list<sobject> objectList = new list<sobject>(); 
                objectList = database.query(soql);
                string queryresponse = '';
                string baseurl = system.Url.getSalesforceBaseUrl().toExternalForm();
                
                //write body
                for (sobject obj : objectList){
                	FeedComment f = new FeedComment();
                    f.FeedItemId = ParentId; 
                    f.CreatedById = Chatty2_Constants.ChattySettings.Chatty2_User__c;
                    integer counter = 0;
                    for (string s : fieldlist){
                    	s = s.trim();
                    	
                    	if (s != 'id'){
                    		if (obj.get(s) != null){
                                queryresponse += obj.get(s);
                    		}                                
                            else{
                                queryresponse += '-';                    		  
                            }
                    	}
                    	counter++;
                    	if (counter < fieldlist.size() && queryresponse.length() > 0)
                    	   queryresponse += ', ';
                    }
                    
                    queryresponse += '\n'; 
                    queryresponse += baseurl + '/' + obj.get('id') + '\n';
                    
                    /*
                    Chatty2_bitly b = new Chatty2_bitly();
                    Chatty2_bitly.shorturl s = b.shorten(objurl);
                    queryresponse += s.url; */
                    f.CommentBody = queryresponse;
                    returnlist.add(f);
                    queryresponse = '';                        
                }     
            }
            
            //query didn't return anything         
            else{
                returnlist.add(
                 new FeedComment(
                    FeedItemId = ParentId, 
                    CreatedById = Chatty2_Constants.ChattySettings.Chatty2_User__c,
                    CommentBody = Label.NoQueryResults
                ));
            }
            
            return returnlist;
            
        }//close query response
    }//close ChattyMessage
}//close Chatty2_Main