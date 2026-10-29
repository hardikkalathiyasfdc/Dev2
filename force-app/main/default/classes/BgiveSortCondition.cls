/**
* Author : Gauri Sagane
* Date   : 05/05/2026
* Jira   : IM-551
* Description : This class use to hold condition structure of type [field, value]
*        Example  :  [created_at,asc]
*/
public with sharing class BgiveSortCondition {

    public List<String> condition = new List<String>();

    public BgiveSortCondition(String field , String sortOrder) {
        condition.add(field);
        condition.add(sortOrder);
    }
}