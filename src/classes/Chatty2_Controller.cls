public without sharing class Chatty2_Controller {
    public Chatty2_Controller(){}
    
    public void myaction(){
        map<string, string> paramMap = ApexPages.currentPage().getParameters();
        
        if (paramMap.get('Pin') != null)
            createInboundMessage(paramMap.get('Pin'));
    }    
    
    public void doCallout(string urlMapping, string jsonBody){
        
        LoginResult lr = authenticateConnection();
        string sessionId = lr.sessionId;
        string endpoint = lr.serverUrl;
        
        //need to truncate the returned endpoint, as it
        //include the SOAP wrapper
        integer x = endpoint.indexOf('/services');
        endpoint = endpoint.substring(0, x);
        system.debug('PRE ENDPOINT: ' + endpoint);
                
        Http h = new http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint + '/services/apexrest/' + urlMapping);
        system.debug('ENDPOINT: ' + endpoint + '/services/apexrest/' + urlMapping);        
        req.setMethod('POST');
        req.setHeader('Authorization', 'OAuth '+sessionID);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);
           
        HTTPResponse res = h.send(req);
        system.debug('RESPONSE BODY IS: ' + res.getBody());
    }
    
    public void createInboundMessage(String pin) {    	 
    	//incoming IP        
        String ipAddress = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
        String jsonBody = '{"address": ' + '"' +  ipAddress + '", "pin": ' + '"' +  pin + '"}';
        
        doCallout('Chatty2', jsonBody);
    }
    
    private LoginResult authenticateConnection(){
        Soap wsSOAP = new Soap();
        return wsSOAP.login('kbromer@chatty2.com', 'npsp3333');
    }


/*
    Chatty2_Settings__c ChattySettings = Chatty2_Constants.getChattySettings();


    public void myaction(){
      map<string, string> paramMap = ApexPages.currentPage().getParameters();
        //check for a valid user
        if (paramMap.get('uid') instanceof id){
            id uid = ApexPages.currentPage().getParameters().get('uid');
            system.debug('UID IS: ' + uid);
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
                    Chatty2_Controller.reportStatus(s, paramMap.get(s));
                }
            }
        }   
        //invalid uid
        else{
            //throw error
            
        }
    }
*/


    /*** SOAP Classes ***/
    public class loginResponse_element {
        public LoginResult result;
        private String[] result_type_info = new String[]{'result','urn:partner.soap.sforce.com','LoginResult','1','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:partner.soap.sforce.com','true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }
    public class Soap {
        public String endpoint_x = 'https://www.salesforce.com/services/Soap/u/20.0';
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x;
        public SessionHeader_element SessionHeader;
        private String SessionHeader_hns = 'SessionHeader=urn:partner.soap.sforce.com';
        private String[] ns_map_type_info = new String[]{'urn:sobject.partner.soap.sforce.com', 'PartnerSoapSobject', 'urn:fault.partner.soap.sforce.com', 'PartnerSoapFault', 'urn:partner.soap.sforce.com', 'PartnerSoapService'};
        public LoginResult login(String username,String password) {
            login_element request_x = new login_element();
            loginResponse_element response_x;
            request_x.username = username;
            request_x.password = password;
            Map<String, loginResponse_element> response_map_x = new Map<String, loginResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              '',
              'urn:partner.soap.sforce.com',
              'login',
              'urn:partner.soap.sforce.com',
              'loginResponse',
              'Chatty2_Controller.loginResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.result;
        }
    }
    public class LoginResult {
        public String metadataServerUrl;
        public Boolean passwordExpired;
        public Boolean sandbox;
        public String serverUrl;
        public String sessionId;
        public String userId;
        public GetUserInfoResult userInfo;
        private String[] metadataServerUrl_type_info = new String[]{'metadataServerUrl','http://www.w3.org/2001/XMLSchema','string','1','1','true'};
        private String[] passwordExpired_type_info = new String[]{'passwordExpired','http://www.w3.org/2001/XMLSchema','boolean','1','1','false'};
        private String[] sandbox_type_info = new String[]{'sandbox','http://www.w3.org/2001/XMLSchema','boolean','1','1','false'};
        private String[] serverUrl_type_info = new String[]{'serverUrl','http://www.w3.org/2001/XMLSchema','string','1','1','true'};
        private String[] sessionId_type_info = new String[]{'sessionId','http://www.w3.org/2001/XMLSchema','string','1','1','true'};
        private String[] userId_type_info = new String[]{'userId','urn:partner.soap.sforce.com','ID','1','1','true'};
        private String[] userInfo_type_info = new String[]{'userInfo','urn:partner.soap.sforce.com','GetUserInfoResult','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:partner.soap.sforce.com','true','false'};
        private String[] field_order_type_info = new String[]{'metadataServerUrl','passwordExpired','sandbox','serverUrl','sessionId','userId','userInfo'};
    }
    public class login_element {
        public String username;
        public String password;
        private String[] username_type_info = new String[]{'username','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] password_type_info = new String[]{'password','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:partner.soap.sforce.com','true','false'};
        private String[] field_order_type_info = new String[]{'username','password'};
    }
     public class SessionHeader_element {
        public String sessionId;
        private String[] sessionId_type_info = new String[]{'sessionId','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:partner.soap.sforce.com','true','false'};
        private String[] field_order_type_info = new String[]{'sessionId'};
    }
    public class GetUserInfoResult {
        public Boolean accessibilityMode;
        public String currencySymbol;
        public String orgDefaultCurrencyIsoCode;
        public Boolean orgDisallowHtmlAttachments;
        public Boolean orgHasPersonAccounts;
        public String organizationId;
        public Boolean organizationMultiCurrency;
        public String organizationName;
        public String profileId;
        public String roleId;
        public String userDefaultCurrencyIsoCode;
        public String userEmail;
        public String userFullName;
        public String userId;
        public String userLanguage;
        public String userLocale;
        public String userName;
        public String userTimeZone;
        public String userType;
        public String userUiSkin;
        private String[] accessibilityMode_type_info = new String[]{'accessibilityMode','http://www.w3.org/2001/XMLSchema','boolean','1','1','false'};
        private String[] currencySymbol_type_info = new String[]{'currencySymbol','http://www.w3.org/2001/XMLSchema','string','1','1','true'};
        private String[] orgDefaultCurrencyIsoCode_type_info = new String[]{'orgDefaultCurrencyIsoCode','http://www.w3.org/2001/XMLSchema','string','1','1','true'};
        private String[] orgDisallowHtmlAttachments_type_info = new String[]{'orgDisallowHtmlAttachments','http://www.w3.org/2001/XMLSchema','boolean','1','1','false'};
        private String[] orgHasPersonAccounts_type_info = new String[]{'orgHasPersonAccounts','http://www.w3.org/2001/XMLSchema','boolean','1','1','false'};
        private String[] organizationId_type_info = new String[]{'organizationId','urn:partner.soap.sforce.com','ID','1','1','false'};
        private String[] organizationMultiCurrency_type_info = new String[]{'organizationMultiCurrency','http://www.w3.org/2001/XMLSchema','boolean','1','1','false'};
        private String[] organizationName_type_info = new String[]{'organizationName','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] profileId_type_info = new String[]{'profileId','urn:partner.soap.sforce.com','ID','1','1','false'};
        private String[] roleId_type_info = new String[]{'roleId','urn:partner.soap.sforce.com','ID','1','1','true'};
        private String[] userDefaultCurrencyIsoCode_type_info = new String[]{'userDefaultCurrencyIsoCode','http://www.w3.org/2001/XMLSchema','string','1','1','true'};
        private String[] userEmail_type_info = new String[]{'userEmail','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] userFullName_type_info = new String[]{'userFullName','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] userId_type_info = new String[]{'userId','urn:partner.soap.sforce.com','ID','1','1','false'};
        private String[] userLanguage_type_info = new String[]{'userLanguage','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] userLocale_type_info = new String[]{'userLocale','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] userName_type_info = new String[]{'userName','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] userTimeZone_type_info = new String[]{'userTimeZone','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] userType_type_info = new String[]{'userType','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] userUiSkin_type_info = new String[]{'userUiSkin','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
        private String[] apex_schema_type_info = new String[]{'urn:partner.soap.sforce.com','true','false'};
        private String[] field_order_type_info = new String[]{'accessibilityMode','currencySymbol','orgDefaultCurrencyIsoCode','orgDisallowHtmlAttachments','orgHasPersonAccounts','organizationId','organizationMultiCurrency','organizationName','profileId','roleId','userDefaultCurrencyIsoCode','userEmail','userFullName','userId','userLanguage','userLocale','userName','userTimeZone','userType','userUiSkin'};
    }

}