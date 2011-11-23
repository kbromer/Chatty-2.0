trigger ChattyTrigger on FeedItem (after insert) {


    system.debug('FEEDITEMTRIGGER');

	list<FeedItem> theItems = new list<FeedItem>();
		
	for(FeedItem f :trigger.new){
		if(f.Body.toLowerCase().StartsWith(ChattyResponder.triggerPhrase.toLowerCase())){
			theItems.add(f);
		}
	}
	ChattyResponder theCommand = new ChattyResponder(theItems);
}