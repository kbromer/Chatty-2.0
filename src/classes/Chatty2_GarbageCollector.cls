public class Chatty2_GarbageCollector {

/** Provides garbage collectin services for Chatty2 **/   
    
 
    public Chatty2_GarbageCollector(){
        try{
            delete [select id from Inbound_Message__c];
            delete [select id from Sensor_Translator__c];
        }
        catch(Exception e){
        	system.debug('AN ERROR OCCURRED: ' + e.getMessage());
        }                	
    }
    

}