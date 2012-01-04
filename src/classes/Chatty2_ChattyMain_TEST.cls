@isTest
public with sharing class Chatty2_ChattyMain_TEST {




            
    public static testMethod void testQueryFeedComment(){
        /*setup(); 
        Account a = [select id from Account limit 1];
        
        FeedItem fi = new FeedItem(
                ParentId = a.id,
                CreatedById = Chatty2_Constants.getChattySettings().Chatty2_User__c,
                Body = 'Feed Item Body'
        );
        insert fi;
        
        Test.startTest();
        insert new FeedComment( 
            FeedItemId = fi.id,
            CreatedById = Chatty2_Constants.ChattySettings.Chatty2_User__c,
            CommentBody = '@Chatty Test Query Command - uses startwith'
        );
        Test.stopTest(); */
    }
    
    public static testMethod void testQueryUserWallPost(){
        //setup();
        
         
    }
    public static testMethod void testQueryFeedItem(){
        setup(); 
        Account a = [select id from Account limit 1];
        
        FeedItem fi = new FeedItem(
                ParentId = a.id,
                CreatedById = Chatty2_Constants.getChattySettings().Chatty2_User__c,
                Body = '@Chatty Test Query Command - uses startwith'
        );
        insert fi;
        
         
    }
    
    public static testMethod void testChatFeedComment(){
        //setup();
        
        
         
    }
    
    public static testMethod void testChatUserWallPost(){
        //setup();
        
         
    }
    public static testMethod void testChatFeedItem(){
        //setup(); 
    	
    
    }
 
    
    
    @isTest
    private static void setup(){
    	Chatty2_Utilities_TEST.setupAll();
    }
    
    
}