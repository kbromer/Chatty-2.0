public with sharing class Chatty2_Constants {
	
    public static Chatty2_Settings__c ChattySettings;
    public static string ChattyName;
    public static list<User_Thing_URL__c> UserURLs;
    
    
    public static Chatty2_Settings__c getChattySettings(){
        
        if (ChattySettings == null){
            ChattySettings = Chatty2_Settings__c.getOrgDefaults();          

            //build default settings
            if (ChattySettings == null){
                id chattyid = [select id from User where LastName = 'Chatter Expert' limit 1].id;               
                Chatty2_Settings__c c2s = new Chatty2_Settings__c();
                c2s.Chatty2_User__c = chattyid;
                insert c2s;
            }               
        }
        return ChattySettings;
    }
    
    public static string getChattyName(){
        
        if (ChattyName == null){
            ChattyName = [select Name from User where id = :ChattySettings.Chatty2_User__c limit 1].Name;
        }
        return ChattyName;
    }
    
    public static list<User_Thing_URL__c> getUserURLs(){
        if (UserURLs == null){
            map<string, User_Thing_URL__c> userURLMap = User_Thing_URL__c.getAll();	
        	for (string s : userURLMap.keySet()){
                UserURLs.add(userURLMap.get(s));        		
        	}
        }    	
    	return UserURLs;
    }
    
    

}