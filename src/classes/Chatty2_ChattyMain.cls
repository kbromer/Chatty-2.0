public with sharing class Chatty2_ChattyMain {
	  
	/*** CLASS VARS ***/
	list<ChattyMessage> cmlist = new list<ChattyMessage>();
	id running_user_id;
	list<Command__c> commandlist = new list<Command__c>();
	list<Thing__c> thinglist = new list<Thing__c>();
	Chatty2_Settings__c ChattySettings = Chatty2_Constants.getChattySettings();
	string ChattyName = Chatty2_Constants.getChattyName();
	id ChattyId = Chatty2_Constants.getChattySettings().Chatty2_User__c;
	
	/*** CONSTRUCTORS ***/ 
	
	//tocheck: this could be done with one sobject constructor, but i think
	//instanceof has a higher overhead 
	
	//handle feeditems with mentions
	public Chatty2_ChattyMain(list<FeedItem> item_list){
		getUser(); 
		//if we're @ mentioning the chatty user
        for (FeedItem f : item_list){
            system.debug('FEEDITEM PARENTID: ' + f.ParentId);
            system.debug('FEEDITEM BODY: ' + f.Body);
        
        
        	if (f.Body.startsWith('@' + Chatty2_Constants.ChattyName) || f.ParentId == ChattyId){
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
        for (FeedComment f : comment_list){
            if (f.CommentBody.startsWith('@' + Chatty2_Constants.ChattyName)){
                cmlist.add(new ChattyMessage(f, this));
            }
        }
        if (!cmlist.isEmpty()){
            loadCommandsandThings();
        }
    }	    

    //handle posts to chatty's wall 
	public Chatty2_ChattyMain(list<User> user_list, map<id, User> oldMap){
        getUser();
        for (User u : user_list){
        	//only get the feed item if its chatty, the status isn't null
        	//and its been updated
        	system.debug('USER STATUS: ' + u.CurrentStatus);
        	system.debug('CHATTY NAME: ' + Chatty2_Constants.ChattyName);
        	
        	if (u.CurrentStatus != null && u.CurrentStatus != oldMap.get(u.id).CurrentStatus
        	   && u.CurrentStatus.startsWith('@' + ChattyName)){
                FeedItem f = [select id, body, createdById, ParentID, createdDate from FeedItem where ParentId = :u.id ORDER BY CreatedDate DESC LIMIT 1];
                cmlist.add(new ChattyMessage(f, this));
        	}
        }	
        if (!cmlist.isEmpty()){
        	loadCommandsandThings();
        }
        
	}
	//handle incoming messages from the arduino array
	public Chatty2_ChattyMain(Chatty2_Comm incoming_comm){
		
		
	}
	
	/*** PRIVATE METHODS ***/
	
	private void getUser(){
		running_user_id = UserInfo.getUserID();
	}
	private void loadCommandsandThings(){
		//sosl live using the message body is also tempting
		
        thinglist = [select id from Thing__c where User__c = :running_user_id];
        commandlist = [select id, Match_Type__c, Command_Text__c, Response_Text__c from Command__c];
	}
	
	

    /*** PUBLIC METHODS ***/	

    public void execute(){
        for (ChattyMessage cm : cmlist){
            cm.executeResponse();
        }    	
    }

    /*** EXCEPTION METHODS ***/
    public class ChattyException extends Exception {}
    
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
                messagebody = f.CommentBody;
                ParentId = f.FeedItemId;
            }	
    		else if (obj instanceof FeedItem){
                FeedItem f = (FeedItem)obj;
                messagebody = (string)f.Body;
                ParentId = f.Id;    			
    		}
    		else{
                throw new ChattyException();
    		}
    	} 
    	
    	
    	
    	//decide how to respond
    	public void executeResponse(){
            
            list<FeedComment> responsepostlist = new list<FeedComment>();
            integer matchingcommandcount = 0;
            //i'm torn, i could really skip the loading of the commands and sosl
            //for matches instead, but could i vary the command type in that scenario?
            //starts w/ versus contains? i'd need to do that in apex
            //and i'd also have to sosl for each chat post, not very bulk safe 
            //we'll use the static loop here since we have all commands and can use
            //apex text comprisons
            
            //clean response body of mentions and whitespace
            messagebody = messagebody.replace('@' + mydad.ChattyName, '');
            messagebody = messagebody.trim();
            system.debug('MESSAGE BODY: ' + messagebody);
            //find all commands where the search text matches
            for (Command__c c : mydad.commandlist){
                if (c.Match_Type__c == 'Starts With'){
                    if(messagebody.startsWith(c.Command_Text__c)){
                        matchingcommandcount++;
                        responsepostlist.add(
                        new FeedComment(
                        FeedItemId = ParentId,
                        CreatedById = Chatty2_Constants.ChattySettings.Chatty2_User__c,
                        CommentBody = c.Response_Text__c
                        ));                                        	
                    	
                    }
                }
                
                else if (c.Match_Type__c == 'Contains'){
                	if(messagebody.contains(c.Command_Text__c)){
                        matchingcommandcount++;
                        responsepostlist.add(
                        new FeedComment(
                        FeedItemId = ParentId,
                        CreatedById = Chatty2_Constants.ChattySettings.Chatty2_User__c,
                        CommentBody = c.Response_Text__c
                        ));                                         
                        
                    }                     
                	
                	
                }
            }
            
            if(!responsepostlist.isEmpty()) insert responsepostlist;
            else{
            	insert new FeedComment(FeedItemId = ParentId, 
            	CreatedById = Chatty2_Constants.ChattySettings.Chatty2_User__c,
            	CommentBody = Label.UnknownCommand 
            	);
            }
    	
    	}
    	
    }



}