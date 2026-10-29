import { LightningElement, api, track, wire } from 'lwc';
import hasRequiredPermission from '@salesforce/apex/ChildObjectChangeLogController.hasRequiredPermission';
import getFeedItems from '@salesforce/apex/ChildObjectChangeLogController.getFeedForParent';

//Column Config example format - [   { "field": "Restricted_Name__c", "label": "Private Name", "showIf": "hasPermission"}  ]

export default class CustomChildObjectChangeLog extends LightningElement {
    @api recordId;
    @api sobjectApiName;
    @api tableName;          
    @api fieldsToFetch;
    @api nameField = 'Name'; 
    @api columnsConfig = [];
    @api permissionSet;
    @api checkForRecordAccess = false;
    @track logs = [];
    columns = [];
    shallShowRestrictedColumn = false;
    hasRequiredPermission = false;

    @wire(hasRequiredPermission, {
        permissionSet: '$permissionSet'
    }) wiredPermission({ error, data }) {
        if(data !== undefined) {
            this.hasRequiredPermission = data;
        } else if(error) {
            console.error('### Permission check error:' + JSON.stringify(error.body));
        }
    }

    @wire(getFeedItems, {
        parentId: '$recordId',
        objectApiName: '$sobjectApiName',
        fieldsToFetch: '$fieldsToFetch',
        nameField: '$nameField',
        checkForRecordAccess: '$checkForRecordAccess'
    }) wiredFeed({ error, data }) {
        if(data) {
            const columnConfig = Array.isArray(JSON.parse(this.columnsConfig)) ? 
                                 JSON.parse(this.columnsConfig) : [];
            const configByField = new Map();
            const finalFields = [];
            columnConfig.forEach(c => {
                if(c?.field) {
                    const normalized = {
                        field: String(c.field),
                        label: c.label ? String(c.label) : null,
                        showIf: (c.showIf || 'always')
                    };
                    configByField.set(normalized.field, normalized);
                    finalFields.push(normalized.field);
                }
            });
            const fieldsToRender = finalFields.filter(f => {
                const cfg = configByField.get(f);
                if(cfg?.showIf === 'hasPermission' && !this.hasRequiredPermission) return false;
                return true;
            });
            this.columns = [
                { label: 'Date', fieldName: 'timestamp' },
                { label: this.tableName, fieldName: 'recordUrl' },
                ...fieldsToRender.map(f => ({ label: (configByField.get(f)?.label) || f, fieldName: f })),
                { label: 'User', fieldName: 'actionBy' },
                { label: 'Change', fieldName: 'action' }
            ];
            this.logs = data.map(item => {
                const rowClass = item.action.includes('Added') ? 'row-added'  :
                                 item.action.includes('Removed') ? 'row-removed' : '';
                const recordUrl = item.relatedRecordId ? '/' + item.relatedRecordId : '';
                const values = [
                    { value: item.timestamp, tableHeader: 'Date' },
                    { isUrl: true, value: recordUrl, label: item.name || '', tableHeader: this.tableName },
                    ...fieldsToRender.map(f => ({ value: item.fieldValues ? (item.fieldValues[f] || '') : '', tableHeader: (configByField.get(f)?.label) || f })),
                    { value: item.actionBy, tableHeader: 'User' },
                    { value: item.action, tableHeader: 'Change' }
                ];
                return { id: item.relatedRecordId, rowClass, values };
            });
        } else if(error) {
            console.error('### Error in change log table: ' + JSON.stringify(error.body));
        }
    }
}