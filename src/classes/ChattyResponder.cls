public with sharing class ChattyResponder {
	
	public Map<id, User> userMap = new Map<id, User>();
	public Map<string, string> commandMap= new Map<string, string>();
	public FeedComment theResponse;
	public string unknownResponse = 'your grammar is pathetic! This is gibberish.';
	public string ChattyUserId = '005U0000000F1mN';
	public static string triggerPhrase = 'Chatty';
	public list<FeedComment> theResponses = new list<FeedComment>();
	
	public ChattyResponder(list<FeedItem> theCommands){
		
		populateCommandMap();
		populateUserMap();
		
		for(FeedItem theCommand : theCommands){
			string cleanCommand = theCommand.Body.replaceAll('[^A-Za-z0-9\\s]', '').toLowerCase();
			system.debug('CleanCommand is: ' + cleanCommand);
			if(commandMap.containsKey(cleanCommand)){
				theResponse = new FeedComment();
				theResponse.FeedItemId = theCommand.id;
				theResponse.CommentBody = userMap.get(theCommand.CreatedById).FirstName + ', ' + commandMap.get(cleanCommand);
				theResponse.CreatedById = ChattyUserId;
				theResponses.add(theResponse);
			}
			else{
				theResponse = new FeedComment();
				theResponse.FeedItemId = theCommand.id;
				theResponse.CommentBody = userMap.get(theCommand.CreatedById).FirstName + ', ' + unknownResponse;
				theResponse.CreatedById = ChattyUserId;
				theResponses.add(theResponse);
			}
			if(cleanCommand.equals(triggerPhrase.toLowerCase() + ' who are you')){
				theResponse = new FeedComment();
				theResponse.FeedItemId = theCommand.id;
				theResponse.CommentBody = 'Sorry, I meant I am your humble and loyal servant. Damn you autocorrect!';
				theResponse.CreatedById = ChattyUserId;
				theResponses.add(theResponse);
			}
		}
		insert theResponses;
	}
	
	public void populateCommandMap(){
		commandMap.put(triggerPhrase.toLowerCase() + ' turn on the light', 'I turned on the light for you.');
		commandMap.put(triggerPhrase.toLowerCase() + ' who are you', 'I am your worst nightmare.');
	}
	
	public void populateUserMap(){
		for(user thisUser : [select FirstName, LastName from User where isActive=true]){
			userMap.put(thisUser.id, thisUser);
		}
		
	}
	
}