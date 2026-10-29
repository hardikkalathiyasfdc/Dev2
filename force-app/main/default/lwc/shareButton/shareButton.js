import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import shareRecord from '@salesforce/apex/ShareRecordController.shareRecord';
import getAllSharedRecords from "@salesforce/apex/ShareRecordController.getAllSharedRecords";
import deleteRecord from '@salesforce/apex/ShareRecordController.deleteRecord';
import updateRecord from '@salesforce/apex/ShareRecordController.updateRecord';
import hasGeneralSharingHierarchyPermission from "@salesforce/apex/ShareRecordController.hasGeneralSharingHierarchyPermission";

const typeColumn = {
    label: "Type",
    fieldName: 'Type',
    editable: false,
};

const datatableColumns = [
{
    label: "Name",
    fieldName: 'Name',
    editable: false,
    wrapText: true,
    cellAttributes: {fontsize: 100},
},
{ 
    label: "Access Level", 
    fieldName: 'AccessLevel', 
    editable: false, 
    type: 'CustomOptionsType',
    typeAttributes: {
        options: [
            { label: 'Read Only', value: 'Read Only' },
            { label: 'Read/Write', value: 'Read/Write'},
        ],
        value: {fieldName: 'AccessLevel'},
        disabled: { fieldName: 'accessLevelDisabled' },
        placeholder: {fieldName: 'AccessLevel'},
        context: { fieldName: 'Id' }
        }
},
{
    type: 'button',
    fieldName: 'closeIconDisabled',
    typeAttributes: {
        iconName: 'utility:close',
        name: 'close',
        variant: 'base',
        disabled: { fieldName: 'closeIconDisabled' },
        class: 'slds-button slds-button_icon '
    },
    fixedWidth:40,
},
];

export default class ShareButton extends NavigationMixin(LightningElement) {

    @api recordId;
    @api recLength = 0;
    shareOptionSelectedValue = '';
    userOrDeptListToShare = [];
    accessLevelValue = '';
    userSearch = false;
    groupSearch = false;
    typeColumn=typeColumn;
    columns=datatableColumns;
    showSharedUsersTable = false;
    sharedDataList;
    sobjectSharedList = [];
    sobjectSharedListAll=[];
    searchRecordsShared = '';
    deleteShareRecList = [];
    updateShareRecList = [];
    displaySharedRecHierarchy = false;
    filterData;
    isPhone;
    isDesktop;

    accessLevelOptions = [
        { label: 'Read Only', value: 'Read Only' },
        { label: 'Read/Write', value: 'Read/Write' },
    ];

    shareOptions = [
        { label: 'Colleague(s)', value: 'Users' },
        { label: 'Team(s)', value: 'Groups' }
    ];

    get shareAccessCSS() {
        return this.isPhone ? 'slds-size_12-of-12 slds-m-bottom_small lightningItem' : 'slds-size_3-of-12 slds-m-top_small';
    }

    get userSearchCSS() {
        return this.isPhone ? 'slds-size_12-of-12 slds-m-bottom_small' : 'slds-size_9-of-12 slds-m-top_small slds-var-p-left_large';
    }

    get hideSharedUsersTable() {
        return !this.showSharedUsersTable;
    }

    connectedCallback() {
        if(FORM_FACTOR == 'Small') {
            this.isPhone = true;
            this.isDesktop = false;
        } else {
            this.isPhone = false;
            this.isDesktop = true;
            //Adding type data column for only desktop. Removed from mobile due to space constraints
            if(this.columns.length < 4) {
                this.columns.splice(1, 0, this.typeColumn);
            }
        }
        this.shareOptionSelectedValue = 'Users';
        this.accessLevelValue = 'Read/Write';
        this.filterData = 'isActive = true';
        this.handleLoad();  
    }

    handleLoad() {
        getAllSharedRecords({ 
            recId: this.recordId 
        }).then((result) => {
            this.sharedDataList = result;
            let shareRecIds = '';
            this.filterData = this.filterData + ' and Id Not IN (';
            this.sharedDataList.forEach(item => {
                shareRecIds = shareRecIds + '\'' + item.UserOrGroupId + '\',';
            });
            shareRecIds = shareRecIds.slice(0, shareRecIds.lastIndexOf(","));
            shareRecIds = shareRecIds + ')';
            this.filterData = this.filterData + shareRecIds;
            this.userSearch = true;
            this.recLength = this.sharedDataList.length - 1;
        }).catch(() => {
            this.userSearch = true;
            this.showToast('', 'Error in retrieving the shared records', 'error');
        });
    }

    selectShareOptions(event) {
        this.userSearch = false;
        this.groupSearch = false;
        this.departmentDisplay = false;
        this.userOrDeptListToShare = [];
        this.accessLevelValue = '';
        this.shareOptionSelectedValue = event.detail.value;
        if(this.shareOptionSelectedValue === 'Users') {
            this.userSearch = true;
            this.filterData = 'isActive = true';
            this.accessLevelValue = 'Read/Write';
        } else if(this.shareOptionSelectedValue === 'Groups') {
            this.groupSearch = true;
            this.filterData = `DeveloperName LIKE \'%DeptTeam_%\'`;
            this.accessLevelValue = 'Read/Write';
        } 
    }

    selectAccessLevelOptions(event) {
        this.accessLevelValue = event.detail.value;
    }

    handleUserSelection(event) {
        this.userOrDeptListToShare=[];
        var selectedData = event.detail;
        selectedData.forEach(item =>{            
            this.userOrDeptListToShare.push(item.Id);
        }); 
    }

    handleSave() {
        //Below if is for Inserting the shared Records
        if (this.userOrDeptListToShare.length !== 0) {
            this.shareRecord();
        }

        //Below if is for deleting the selected shared Records
        if(this.deleteShareRecList.length > 0) {
            this.deleteShareRecord();
        }

        //Below if is for updating the shared Records
        if (this.updateShareRecList.length > 0) {
            let finalUpdateShareList = [];
            this.updateShareRecList.forEach(updateShareRecItem => {
                this.sobjectSharedList.forEach(allShareRecItem => {
                    if(updateShareRecItem.recId === allShareRecItem.Id && 
                       updateShareRecItem.accessLevel !== allShareRecItem.AccessLevel) {
                        
                        finalUpdateShareList.push(updateShareRecItem);
                    }
                });
            });
            this.updateShareRecList = finalUpdateShareList;
            if(finalUpdateShareList.length > 0) {
                this.updateShareRecord();
            }
        }
    }

    shareRecord() {
        shareRecord({ 
            recordId: this.recordId, 
            userOrGroupList: this.userOrDeptListToShare, 
            shareOptionValue: this.shareOptionSelectedValue, 
            accessLevel: this.accessLevelValue
        }).then(result => {
            this.showToast('', result, 'success');
            refreshApex(this.sharedDataList);
        }).then(() => {
            this.closePopup();
        }).catch(error => {
            this.showToast('', 
                'Error while sharing the record  : ' + JSON.stringify(error), 
                'error');
        });
    }

    deleteShareRecord() {
        deleteRecord({ 
            recordId: this.recordId, 
            shareRecDeletionIds: this.deleteShareRecList
        }).then(result => {
            this.showToast('', result, 'success');
            refreshApex(this.sharedDataList);
        }).then(() => {
            this.closePopup();
        }).catch(error => {
            this.showToast('', 
                'Error deleting the shared records : ' + JSON.stringify(error), 
                'error');
        });
    }

    updateShareRecord() {
        updateRecord({ 
            recordId: this.recordId, 
            shareRecUpdateList: JSON.stringify(this.updateShareRecList)
        }).then(result => {
            this.showToast('', result, 'success');
            refreshApex(this.sharedDataList);
        }).then(() => {
            this.closePopup();
        }).catch(error => {
            this.showToast('', 
                'Error updating the shared records : ' + JSON.stringify(error), 
                'error');
        });
    }  

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event); 
    }

    closePopup() {
        this.dispatchEvent(new CustomEvent('popupclose'));
    }

    handleEditButton() {
        if(this.sharedDataList.length > 0) {
            let options = [];
            this.sharedDataList.forEach(item => {
                let shareRec = {};
                shareRec.Id = item.Id;
                let parentId = item?.ParentId;
                if(parentId === undefined) {
                    for(let key in item) {
                        if(key !== 'Id' && key.endsWith('Id') && item[key] !== undefined) {
                            parentId = item[key];
                        }
                    }
                }
                shareRec.ParentId = parentId;
                shareRec.UserOrGroupId = item.UserOrGroupId;
                shareRec.Name = item.UserOrGroup.Name;   
                shareRec.Type = item.UserOrGroup.Type === 'Queue' ? 'Team' : item.UserOrGroup.Type; 
                let accessLevel = item?.AccessLevel;
                if(accessLevel === undefined) {
                    for(let key in item) {
                        if(key.endsWith('AccessLevel') && item[key] !== undefined) accessLevel = item[key];
                    }
                }
                shareRec.AccessLevel = (accessLevel === 'Read') ? 'Read Only' : (accessLevel === 'Edit') ? 'Read/Write' : 'All';
                shareRec.closeIconDisabled = (shareRec.AccessLevel === 'All') ? true : false;
                shareRec.accessLevelDisabled = (shareRec.AccessLevel === 'All') ? true : false;
                options.push(shareRec);
            });
            this.sobjectSharedList  = options;
            this.sobjectSharedListAll = options;
            this.showSharedUsersTable = true;
        } else {
            this.showSharedUsersTable = false;
        }
        this.recLength = this.sobjectSharedList.length-1;

        hasGeneralSharingHierarchyPermission()
        .then(result => {
            this.displaySharedRecHierarchy = result;
        });
    }

    handleSelectionHierarchy() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: this.objectApiName,
                actionName: 'recordShareHierarchy'
            }
        });
    }

    searchSharedRecord(event) {
        const searchString = event.target.value;
        this.searchRecordsShared = searchString.toLowerCase();
        let options = [];
        if(this.searchRecordsShared) {
            this.sobjectSharedListAll.forEach(item => {
                const name = item.Name;
                if(name !== undefined && name !== null && name.toLowerCase().includes(this.searchRecordsShared)) {
                    options.push(item);
                }
            });
            this.sobjectSharedList = options;
        } else {           
            this.sobjectSharedList = this.sobjectSharedListAll;
        }
    }

    handleDeleteAction(event) {
        const row = event.detail.row;
        this.sobjectSharedList = this.sobjectSharedList.filter(item => item.Id !== row.Id);
        if(this.updateShareRecList.length > 0) {
            this.updateShareRecList = this.updateShareRecList.filter(item => item.recId !== row.Id);
        }
        this.recLength = this.sobjectSharedList.length;
        this.deleteShareRecList = [...this.deleteShareRecList, row.Id];    
    }

    updatePicklist(event) {
        let shareRecId = event.detail.data.context;
        let shareRecAccessLevel = event.detail.data.value;
        if(this.updateShareRecList.length > 0) {
            let copyUpdateShareData = [...this.updateShareRecList];
            let existingIdFlag = false;
            copyUpdateShareData.forEach(item => {
                if (item.recId === shareRecId) {
                    item['accessLevel'] = shareRecAccessLevel;
                    existingIdFlag = true;
                }
            });

            if(existingIdFlag) {
                this.updateShareRecList = [...copyUpdateShareData];
            } else {
                let options = {};
                options.recId = shareRecId;
                options.accessLevel = shareRecAccessLevel;
                this.updateShareRecList.push(options);
            }
        } else {
            let options = {};
            options.recId = shareRecId;
            options.accessLevel = shareRecAccessLevel;
            this.updateShareRecList.push(options);
        }   
    }
}