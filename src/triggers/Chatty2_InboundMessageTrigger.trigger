trigger Chatty2_InboundMessageTrigger on Inbound_Message__c (after insert) {

    if(!Chatty2_Constants.isExecuting){
        Chatty2_Comm c2c = new Chatty2_Comm(trigger.new);
        c2c.Execute();
    }

}