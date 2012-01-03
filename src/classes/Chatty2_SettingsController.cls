public with sharing class Chatty2_SettingsController {
	
	
	public boolean editUser {get; set;}
	public boolean editLoopback {get; set;}
	
	//borrow this objects user lookup
	public Thing__c thingForUser {get; set;}
	public User ChattyUser {get; set;}
	public Array_Owner__c arrayOwnerForUser {get; set;}
	public Chatty2_Settings__c c2s {get; set;} 
	
	public Chatty2_SettingsController(){
		editUser = false;
		editLoopback = false;		
		
		c2s = Chatty2_Settings__c.getOrgDefaults();
		
		if (c2s.Chatty2_User__c != null){
		  ChattyUser = [select id, Name from User where id = :c2s.Chatty2_User__c];
		  arrayOwnerForUser = new Array_Owner__c(User__c = ChattyUser.id);
		}		      
		else
		  ChattyUser = new User();
	}
	
	
	public pagereference editloopback_config(){
		
		
		return null;
	}
	
	public pagereference edituser_settings(){
		return null;
	}

}