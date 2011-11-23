trigger Chatty2_UserTrigger on User (after insert) {
    Chatty2_ChattyMain c2cm = new Chatty2_ChattyMain(trigger.new, trigger.oldMap);
    c2cm.execute();
}