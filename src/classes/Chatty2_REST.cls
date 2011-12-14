@RestResource(urlMapping='/Chatty2/*')
global with sharing class Chatty2_REST {
  
    @HttpGet
    global static Account doGet(RestRequest req, RestResponse res) {
        String accountId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        Account result = [SELECT Id, Name, Phone, Website FROM Account WHERE Id = :accountId];
        return result;
    }
  
    @HttpPost
    global static String doPost(RestRequest req, RestResponse res, String name) {
        FeedItem fi = new FeedItem();
        fi.ParentId = Chatty2_Constants.getChattySettings().Chatty2_User__c;
        fi.Type = 'TextPost';
        fi.Body = 'THE INTERNET SAYS: ' + name;
        fi.CreatedById = Chatty2_Constants.getChattySettings().Chatty2_User__c;
        insert fi; 
        return fi.Id;
    } 

}