public with sharing class Chatty2_Controller {


    Chatty2_Settings__c ChattySettings = Chatty2_Constants.getChattySettings();


    public Chatty2_Controller(){
        
        map<string, string> paramMap = ApexPages.currentPage().getParameters();
        
        //check for a valid user
        if (paramMap.get('uid') instanceof id){
            id uid = ApexPages.currentPage().getParameters().get('uid');
            list<Thing__c> thingList = [select id, Thing_Name__c from Thing__c where User__c = :uid];
            
            //create a thing map
            map<string, Thing__c> thingMap = new map<string, Thing__c>();
            
            for (Thing__c t : thingList){
                thingMap.put(t.Thing_Name__c, t);
            }
            
            //get other params
            for (string s : paramMap.keySet()){
                //if the param has a matching thing...
                if (thingMap.containsKey(s)){
                    
                    //temporary
                    reportStatus(s, paramMap.get(s));
                }
            }
        
        
        
        }	
    	
    	
    	//invalid uid
    	else{
    		//throw error
    		
    	}
    }
    
    @future
    public static void reportStatus(string thingname, string thingvalue){
        FeedItem fi = new FeedItem();
        fi.ParentId = Chatty2_Constants.getChattySettings().Chatty2_User__c;
        fi.Type = 'TextPost';
        fi.Body = thingname + ' Status is: ' + thingvalue;
        insert fi; 
    }

    static testMethod void testFeedItemPost(){
    	
    	Chatty2_Controller c2d = new Chatty2_Controller();
    	
    	//get the guest user
    	User u = [select id from User where id = '005U0000000F4SW'];
    	//run the callout as a guest user
    	system.runAs(u){
    	   Chatty2_Controller.reportStatus('TEST STATUS', '85');
    	}
    	
    }


}