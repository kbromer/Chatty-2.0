public with sharing class Chatty2_SettingsController {
	
	
	public boolean editUser {get; set;}
	public boolean editLoopback {get; set;}

	public Chatty2_Settings__c c2s {get; set;}
	public string selectedTab {get; set;}
	
	private string savedpassword; 
	
	public Chatty2_SettingsController(){
		editUser = false;
		editLoopback = false;	
        
        selectedTab = 'user_settings';

		c2s = Chatty2_Settings__c.getOrgDefaults();
	  
        savedpassword = c2s.Chatty_Admin_PW__c;		  
        c2s.Chatty_Admin_PW__c = 'xxxxxx';
	}
	
	
	public pagereference editloopback_config(){
		editLoopback = true;
        c2s.Chatty_Admin_PW__c = savedpassword;
        selectedtab = 'loopback_config';
		
		return null;
	}
	
	public pagereference edituser_settings(){
		editUser = true;    
		selectedTab = 'user_settings';
		
		
		
		return null;
	}
	
	public pagereference cancel(){
		edituser = false;
		editloopback = false;
		return null;
	}
	
	public pagereference saveLoopBackConfig(){
		try{
			update c2s;
		}
		catch(Exception e){
			
		}
        
        selectedtab = 'loopback_config';				
		savedpassword = c2s.Chatty_Admin_PW__c;         
        c2s.Chatty_Admin_PW__c = 'xxxxxx';
		editloopback = false;
		
		return null;
	}
	public pagereference saveUserSettings(){
		
		try{
			update c2s;
		}
		catch (Exception e){
			
		}
		
		return null;
	}
	

}