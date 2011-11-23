public with sharing class Chatty2_Contants {

    public static Chatty2_Settings__c ChattySettings;
    
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
}