trigger Chatty2_FeedItemTrigger on FeedItem (after insert) {


    if(!Chatty2_Constants.isExecuting){
        Chatty2_ChattyMain c2cm = new Chatty2_ChattyMain(trigger.new);
        c2cm.execute();
    }        
}