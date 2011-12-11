@RestResource(urlMapping='/Chatty2/*')
global with sharing class Chatty2_REST {
  
    @HttpGet
    global static Account doGet(RestRequest req, RestResponse res) {
        String accountId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        Account result = [SELECT Id, Name, Phone, Website FROM Account WHERE Id = :accountId];
        return result;
    }
  
    @HttpPost
    global static String doPost(RestRequest req, RestResponse res, String name,
        String phone, String website) {
        Account account = new Account();
        account.Name = name;
        account.phone = phone;
        account.website = website;
        insert account;
        return account.Id;
    }

}