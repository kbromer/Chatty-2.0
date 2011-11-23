trigger Chatty2_FeedCommentTrigger on FeedComment (after insert) {
    Chatty2_ChattyMain c2cm = new Chatty2_ChattyMain(trigger.new);
    c2cm.execute();
}