public with sharing class Chatty2_Comm {
    
    Command__c outboundcommand;
    list<Inbound_Message__c> inboundmessages;
    
    public Chatty2_Comm(Command__c c){
        outboundcommand = c;
    }        
	
	public Chatty2_Comm(list<Inbound_Message__c> ibm){
	   inboundmessages = ibm;
	}
	
	
	public void Execute(){
        if (outboundcommand != null){
                    	
        	
        }	
        else if(inboundmessages != null){
        	
        	
        }
        else{
        	throw new Chatty2_Constants.ChattyException();
        }	
	}
	
	
	
	
	
	

}