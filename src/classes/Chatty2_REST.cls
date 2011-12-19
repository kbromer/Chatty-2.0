@RestResource(urlMapping='/Chatty2/*')
global with sharing class Chatty2_REST {
  
    @HttpGet
    global static Account doGet(RestRequest req, RestResponse res) {
        String accountId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        Account result = [SELECT Id, Name, Phone, Website FROM Account WHERE Id = :accountId];
        return result;
    }
  
    @HttpPost
    global static String doPost(RestRequest req, RestResponse res, String address, String pin, string value) {
        /*FeedItem fi = new FeedItem();
        fi.ParentId = Chatty2_Constants.getChattySettings().Chatty2_User__c;
        fi.Type = 'TextPost';
        fi.Body = 'THE INTERNET SAYS: ' + name;
        fi.CreatedById = Chatty2_Constants.getChattySettings().Chatty2_User__c;
        insert fi; 
        return fi.Id;*/
        
        Inbound_Message__c message = new Inbound_Message__c();
        message.source_address__c = address;
        message.Value__c = value;
        message.pin__c = pin;
        insert message;
        
        return message.Id;        
    } 

}