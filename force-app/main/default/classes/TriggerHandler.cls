/**
 * Interface containing methods Trigger Handlers must implement to enforce best practice
 * and bulkification of triggers.
 */
public virtual class TriggerHandler {
	public List<SObject> newRecordList;
	public List<SObject> oldRecordList;
	public Map<Id, SObject> newRecordMap;
	public Map<Id, SObject> oldRecordMap;

	// Default Constructor
	public TriggerHandler() {
		this.newRecordList = Trigger.new;
		this.newRecordMap = Trigger.newMap;
		this.oldRecordList = Trigger.old;
		this.oldRecordMap = Trigger.oldMap;
	}

	// Constructor to filter records based on certain criteria
	public TriggerHandler(Map<Schema.SObjectField, List<Object>> filter) {
		this.useOnlyTheseRecords(filter);
	}

	/**
	 * bulkBefore
	 *
	 * This method is called prior to execution of a BEFORE trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
    public virtual void bulkBefore(){}

	/**
	 * bulkAfter
	 *
	 * This method is called prior to execution of an AFTER trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
    public virtual void bulkAfter(){}

	/**
	 * beforeInsert
	 *
	 * This method is called iteratively for each record to be inserted during a BEFORE
	 * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	 */
    public virtual void beforeInsert(SObject so){}

	/**
	 * beforeUpdate
	 *
	 * This method is called iteratively for each record to be updated during a BEFORE
	 * trigger.
	 */
    public virtual void beforeUpdate(SObject oldSo, SObject so){}

	/**
	 * beforeDelete
	 *
	 * This method is called iteratively for each record to be deleted during a BEFORE
	 * trigger.
	 */
    public virtual void beforeDelete(SObject so){}

	/**
	 * afterInsert
	 *
	 * This method is called iteratively for each record inserted during an AFTER
	 * trigger. Always put field validation in the 'After' methods in case another trigger
	 * has modified any values. The record is 'read only' by this point.
	 */
    public virtual void afterInsert(SObject so){}

	/**
	 * afterUpdate
	 *
	 * This method is called iteratively for each record updated during an AFTER
	 * trigger.
	 */
    public virtual void afterUpdate(SObject oldSo, SObject so){}

	/**
	 * afterDelete
	 *
	 * This method is called iteratively for each record deleted during an AFTER
	 * trigger.
	 */
    public virtual void afterDelete(SObject so){}

	public virtual void afterUndelete(SObject so){}

	/**
	 * andFinally
	 *
	 * This method is called once all records have been processed by the trigger. Use this
	 * method to accomplish any final operations such as creation or updates of other records.
	 */
    public virtual void andFinally(){}

	//jlu513 added common method for triggers
	public virtual boolean isFieldChanged(SObject myObj, String field) {
		if (Trigger.isDelete || Trigger.isInsert || Trigger.oldMap == null) {
			return true;
		}

		SObject oldSObj = Trigger.oldMap.get(myObj.Id);
		SObject newSObj = Trigger.newMap.get(myObj.Id);
		Object oldField = oldSObj != null ? oldSObj.get(field) : null;
		Object newField = newSObj != null ? newSObj.get(field) : null;
		if (oldField == null && newField == null) {
			return false;
		}
		if (oldField == null && newField != null) {
			return true;
		}
		return !oldField.equals(newField);
	}

	/**
	 * Description : This method is used to filter the records that are to be processed by the trigger
	 * based on the filter criteria passed.
	 * Parameters  : filter Map<Schema.SObjectField, List<Object>>
	 * Return Type : void
	 */
	public void useOnlyTheseRecords(Map<Schema.SObjectField, List<Object>> filter) {
		this.newRecordList = new List<SObject>{};
		this.oldRecordList = new List<SObject>{};
		this.newRecordMap = new Map<Id, SObject>();
		this.oldRecordMap = new Map<Id, SObject>();

		for (SObject so : Trigger.new ?? new List<SObject>{}) {
			if (filter(so, filter)) {
				this.newRecordList.add(so);
				this.newRecordMap.put(so.Id, so);
				if (Trigger.isUpdate && Trigger.oldMap.containsKey(so.Id)) {
					// includes records where the record type of the object is being updated
					SObject associatedOldRecord = Trigger.oldMap.get(so.Id);
					this.oldRecordList.add(associatedOldRecord);
					this.oldRecordMap.put(associatedOldRecord.Id, associatedOldRecord);
				}
			}
		}

		for (SObject so : Trigger.old ?? new List<SObject>{}) {
			if (filter(so, filter)) {
				this.oldRecordList.add(so);
				this.oldRecordMap.put(so.Id, so);
			}
		}
	}

	public List<SObject> getNewRecords() {
		return this.newRecordList ?? new List<SObject>{};
	}

	public List<SObject> getOldRecords() {
		return this.oldRecordList ?? new List<SObject>{};
	}

	public Map<Id, SObject> getNewRecordMap() {
		return this.newRecordMap ?? new Map<Id, SObject>();
	}

	public Map<Id, SObject> getOldRecordMap() {
		return this.oldRecordMap ?? new Map<Id, SObject>();
	}

	/**
	 * Description : This method consists of the filtering logic return true if record matches filter criteria, false otherwise
	 * Parameters  : record SObject, filter Map<Schema.SObjectField, List<Object>>
	 * Return Type : Boolean
	 */
	private static Boolean filter(SObject record, Map<Schema.SObjectField, List<Object>> filter) {
		for (Schema.SObjectField field : filter.keySet()) {
			if (filter.get(field)?.contains(record.get(field)) == false) {
				return false;
			}
		}
		return true;
	}
}