public with sharing class Chatty2_ChattyMain {
	  
	
	list<ChattyMessage> cmlist = new list<ChattyMessage>();
	
	//handle feeditems with mentions
	public Chatty2_ChattyMain(list<FeedItem> item_list){ 
        //if we're @ mentioning the chatty user
        for (FeedItem f : item_list){
        	if (f.Body.startsWith('@' + Chatty2_Constants.ChattyName)){
                cmlist.add(new ChattyMessage(f));
        	}
        }		
	}
    
    //handle feedcomments with mentions
    public Chatty2_ChattyMain(list<FeedComment> comment_list){
        for (FeedComment f : comment_list){
            if (f.CommentBody.startsWith('@' + Chatty2_Constants.ChattyName)){
                cmlist.add(new ChattyMessage(f));
            }
        }
    }	

    //handle posts to chatty's wall 
	public Chatty2_ChattyMain(list<User> user_list, map<id, User> oldMap){
        for (User u : user_list){
        	//only get the feed item if its chatty, the status isn't null
        	//and its been updated
        	if (u.Id == Chatty2_Constants.ChattySettings.Chatty2_User__c && 
        	u.CurrentStatus != null && u.CurrentStatus != oldMap.get(u.id).CurrentStatus){
                FeedItem f = [select id, body, createdById, createdDate from FeedItem where ParentId = :u.id ORDER BY CreatedDate DESC LIMIT 1];
                cmlist.add(new ChattyMessage(f));
        	}
        }	
	}
	

	//handle incoming messages from the arduino array
	public Chatty2_ChattyMain(Chatty2_Comm incoming_comm){
		
		
	}
	

    public void execute(){
        for (ChattyMessage cm : cmlist){
            cm.executeCommand();
        }    	
    }




    public class ChattyMessage{
    	
    	public ChattyMessage(FeedComment fc){}
    	public ChattyMessage(FeedItem fi){}
    	public ChattyMessage(Chatty2_Comm c2c){}
    	
    	public void executeCommand(){}
    	
    }



}