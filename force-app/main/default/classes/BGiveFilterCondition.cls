/**
* Author : Neha Gire
* Date   : 04/12/2024
* Jira   : IM-26
* Description : This class use to hold condition structure of type [fld , operator , value]
*				Example  :  [first_name,starts_with,test] 
*/

public without sharing class BGiveFilterCondition {
    // Enum for allowed operators in Fluxx/Bgive
    public enum Operator { EQ,NOT_EQ,LT,LTE,GT,GTE,IS_NULL,IS_NOT_NULL,STARTS_WITH,NOT_STARTS_WITH,CONTAINS,NOT_CONTAINS }
    
	public List<String> condition = new List<String>();
    
    public BGiveFilterCondition(String fld , Operator op , String val){
        condition.add(fld);
        condition.add(getOperator(op));
        condition.add(val);
    }
    
    private String getOperator(Operator op){
        switch on op {
           when NOT_EQ {
               return 'not-eq';
           }
           when IS_NULL {
               return 'null';
           }
           when IS_NOT_NULL {
               return 'not-null';
           }
           when NOT_STARTS_WITH {
               return 'not-starts_with';
           }
           when NOT_CONTAINS {
               return 'not-contains';
           }
           when else {
              return op.name().toLowerCase();
           }
        }
    }
}