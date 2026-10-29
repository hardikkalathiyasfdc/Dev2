/**
* Author : Neha Gire
* Date   : 04/12/2024
* Jira   : IM-26
* Description : This class represent the filter structure needed for Bgive API filtering.
*				Example  : { "group_type": "or", "conditions": [ [field,operator,value] , { "group_type": "and", "conditions": [ [field,operator,value] , ...] }] }
*/

public without sharing class BGiveApiFilter {
    public String group_type;
    public List<Object> conditions;
    
    /* 
     * Default group_type will always be and;
     */
    public BGiveApiFilter(){
        this.group_type = 'and';
        this.conditions = new List<Object>();
    }
    
    
   /**
    * Description : Method to set group_type for the condtion
    * Params	  : groupType - String value which can be either 'or' / 'and'.
    * Return Type : none
    */
    public void setGroupType(String groupType){
        this.group_type = groupType;
    }
    
    /**
    * Description : Method to get json string format of current filter instance
    * Params	  : none
    * Return Type : String - JSON String reprentation of filter instance.
    */
    public String getFilterString(){
        return JSON.serialize(this,true); // suppresssing null values since those are not needed.
    }
    
     /**
    * Description : Method to add condition of type BGiveFilterCondition
    * Params	  : BGiveFilterCondition - Condition to specify field value check
    * Return Type : none
    */
    public void addCondition(BGiveFilterCondition condition){
        this.conditions.add(condition.condition);
    }
    
     /**
    * Description : Method to add condition of type BGiveApiFilter
    * Params	  : BGiveApiFilter - specify condition with group_type and condition
    * Return Type : none
    */
    public void addCondition(BGiveApiFilter condition){
        this.conditions.add(condition);
    }
    
}