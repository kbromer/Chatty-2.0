@isTest 
public with sharing class Chatty2_Utilities_TEST {
   
    public static void setupAll(){
        Chatty2_Utilities_TEST.setupTestArrays(1);
    }
    
    public static void setupTestArrays(integer num_of_arrays) {
        
        list<Array__c> arraylist = new list<Array__c>();
        integer i;
        for (i=0; i<=num_of_arrays; i++){
            Array__c a = new Array__c(Array_Address__c = '1.2.3.4.5.6');
            arraylist.add(a);	
        }
        
        insert arraylist; 
        Chatty2_Utilities_TEST.setupTestThings(arraylist, 2);
    }   
     
    public static void setupTestThings(list<Array__c> arraylist, integer things_per_array){
        
        list<Thing__c> thinglist = new list<Thing__c>();
        integer i;
        
        for (Array__c a : arraylist){
            for (i=0; i<= things_per_array; i++){
                Thing__c t = new Thing__c(
                Array__c = a.id,
                Short_Description__c = 'Test Thing ' + i + ' for Array ' + a.Name,
                Thing_Address__c = a.Name + i 
                );	
                
                if (i < 1){
                    t.Thing_Type__c = 'Digital';                	
                }
                else{
                	t.Thing_Type__c = 'Analog';
                }
                
                t.Component_Type__c = 'Boolean';
                
                thinglist.add(t);
            }	
        }
        
        insert thinglist;
        Chatty2_Utilities_TEST.setupTestCommands(thinglist, 4);
    }
   
    public static void setupTestCommands(list<Thing__c> thinglist, integer commands_per_thing){ 
        list<Command__c> commandlist = new list<Command__c>();
        integer i; 
        
        map<id, RecordType> rectypes = Chatty2_Constants.getCommandRecordTypes();
        map<string, id> recmap = new map<string, id>();
        //create a map by string
        for (id rid : rectypes.keyset()){
        	RecordType rt = rectypes.get(rid);
        	recmap.put(rt.Name, rt.id);
        }        
        
        for (Thing__c t : thinglist){
        	for (i=0; i<=commands_per_thing; i++){
        	   
                Command__c c = new Command__c(Thing__c = t.id);
                
                //action
                if (i==0){
                	c.Command_Text__c = 'Test Action Command';
                	c.Match_Type__c = 'Starts With';
                	c.RecordTypeId = recmap.get('Action');
                    c.Response_Text__c = 'Test Response Text';
                    c.Actions__c = 'ON';
                    c.Action_Confirmation__c = 'Test Action Confirmation';	
                }
                //chat
                if (i==1){
                	c.Command_Text__c = 'Test Chat Command';
                	c.Match_Type__c = 'Contains';
                	c.RecordTypeId = recmap.get('Chat');
                	c.Response_Text__c = 'Test Response Text';
                }
                //query
                if (i==2){
                	c.Command_Text__c = 'Test Query Command';
                	c.Match_Type__c = 'Starts With';
                	c.RecordTypeId = recmap.get('Query');
                	c.Query__c = 'select id, Name from Contact';
                	c.Query_Parameters__c = 'LastName != \'TestName\'';
                	c.Query_Order_By__c = 'LastName desc';
                	c.Query_Limit__c = '5';
                	c.Limit_to_User__c = true;                	
                }
                //status
                if (i == 3){
                    c.Command_Text__c = 'Test Status Command';
                    c.Match_Type__c = 'Contains';
                    c.Status_Formula__c = '< 75';
                    c.Formula_Response__c = commandlist[0].id;  
                    c.Response_Text__c = 'Test Response Text';
                    c.RecordTypeId = recmap.get('Status');
                    c.Action_Confirmation__c = 'Test Action Confirmation';
                }
                commandlist.add(c);	
        	}
        } 
        
        insert commandlist;
    }
}