@RestResource(urlMapping='/Chatty2/*')
global with sharing class Chatty2_REST {
  
    @HttpPost
    global static string doPost(RestRequest req, RestResponse res, String address, String pin, string value) {
        string return_body = Chatty2_REST.insertMessage(address, value, pin);
        return return_body;
    } 
    
    global static string insertMessage(string address, string value, string pin){
      
        try{       
            Inbound_Message__c message = new Inbound_Message__c();
            message.source_address__c = address;
            message.Value__c = value;
            message.pin__c = pin;
            insert message;
        }
        catch (Exception e){
        	return e.getMessage();
        }
        return 'SUCCESS'; 
    }
}