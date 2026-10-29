/**
* Author : Gauri Sagane
* Date   : 05/05/2026
* Jira   : IM-551
* Description : This class represent the sort structure needed for Bgive API sorting.
*        Example  : [[field,value], [field,value], ...]
*/
public with sharing class BgiveApiSort {
    public List<List<String>> conditions;

    public BgiveApiSort(){
        this.conditions = new List<List<String>>();
    }
    
    /**
    * Description : Method to get json string format of current sort instance
    * Params    : none
    * Return Type : String - JSON String reprentation of sort instance.
    */
    public String getSortString(){
        return JSON.serialize(this.conditions,true);
    }

    /**
    * Description : Method to add condition of type BGiveSortCondition
    * Params    : BGiveSortCondition condition
    * Return Type : none
    */
    public void addCondition(BGiveSortCondition condition){
        this.conditions.add(condition.condition);
    }
    
    /**
    * Description : Method to add condition of type List<String>
    * Params    : List<String> condition
    * Return Type : none
    */
    public void addCondition(List<String> condition){
        this.conditions.add(condition);
    }
}