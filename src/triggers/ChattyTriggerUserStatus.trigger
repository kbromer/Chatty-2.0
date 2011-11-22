trigger ChattyTriggerUserStatus on User (after update) {
	list<FeedItem> theCommands = new list<FeedItem>();
				
	for(Integer i = 0; i < trigger.new.size(); i++){
		if(trigger.new[i].CurrentStatus != null && trigger.new[i].CurrentStatus.toLowerCase().StartsWith(ChattyResponder.triggerPhrase.toLowerCase())){
			FeedItem thisCommand = [select id, body, createdById, createdDate from FeedItem where ParentId = :trigger.new[i].Id ORDER BY CreatedDate DESC LIMIT 1];
			if(trigger.new[i].LastModifiedDate == thisCommand.CreatedDate){
				theCommands.add(thisCommand);
			}
		}
	}
	
	ChattyResponder theCommand = new ChattyResponder(theCommands);
}