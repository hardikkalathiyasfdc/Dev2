import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

import saveListMemberAttachment from '@salesforce/apex/listMemberAttachmentAuraCtrl.saveListMemberAttachment';
import checkUserCreationPermission from '@salesforce/apex/listMemberAttachmentAuraCtrl.checkUserCreationPermission';
import getConfidentialFiles from '@salesforce/apex/listMemberAttachmentAuraCtrl.getConfidentialFiles';
import deleteConfidentialFile from '@salesforce/apex/listMemberAttachmentAuraCtrl.deleteConfidentialFile';
import getListId from '@salesforce/apex/listMemberAttachmentAuraCtrl.getListId';

const actions = [
    { label: 'Delete', name: 'delete' },
];

const columns = [{ label: 'File Name', fieldName: 'Name' },
			    { label: '', fieldName: 'viewurl', type: 'url',typeAttributes: {label: { fieldName: 'ViewFile' }, target: '_blank'} },
			    {
			        type: 'action',
			        typeAttributes: { rowActions: actions },
			    }
			    ];
export default class listMemberAttachment extends LightningElement {
	@api recordId;
	noAccess = true;
	disableShowUpload = true;
	showSpinner = false;
	showViewAll = false;
	file;
	fileName;
	title = 'Files';
	message;
	variant;
	err;
	confidentialAttachments;
	attchements;
	url;
	columns = columns;
	size;
	showExistedAttachmentSection = false;
	listId;

	@wire(checkUserCreationPermission, { parentId: '$recordId' }) 
	checkCreationPermission(result){
		if( result.data ) {
			this.noAccess = result.data === 'true'?false:true;
		}

		if(result.error) {
			this.err = result.error;
		}
	}

	@wire(getListId, { listMemberId: '$recordId' }) 
	wireGetListId(result){
		if( result.data ) {
			let listInfo = JSON.parse(result.data);
			if( listInfo.length > 0 ) {
				this.listId = listInfo[0].CampaignId;
			}
		}

		if(result.error) {
			this.err = result.error;
		}
	}

	@wire(getConfidentialFiles, { parentId: '$recordId' }) 
	getConfidentailAttachments(result){
		this.confidentialAttachments = result;
		if( result.data ) {
			let attchements = JSON.parse(result.data);
			console.log(attchements);
			attchements.forEach(item => {
				item.viewurl = '/lightning/r/ContentDocument/'+item.Attachment__c+'/view';
				item.ViewFile='View File';
			});

			this.title = 'List Attachments (' +attchements.length+')';
			this.showViewAll = false;
		
			if( attchements.length > 0 ) {
				this.showExistedAttachmentSection = true;
			} else {
				this.showExistedAttachmentSection = false;
			}

			this.attchements = attchements;
			this.err = undefined;
		}

		if(result.error) {
			this.err = result.error;
			this.attchements = undefined;
		}
	}


	handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        let documentId = uploadedFiles[0].documentId;

        saveListMemberAttachment({
        	listMemberId: this.recordId,
        	documentId: documentId,
        	listId: this.listId
        })
        .then(result => {
        	if( result === 'success' ) {
        		refreshApex(this.confidentialAttachments);
        	}
        })
        .catch(err => {
        	this.err = err;
        });

    }

    handleRowAction(event) {
    	this.showSpinner = true;
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if( actionName === 'delete' ) {
        	this.deleteRow(row);
        }
    }

    deleteRow(row) {
        deleteConfidentialFile({
        	parentId: row.Id
        })
        .then(result => {
        	if( result === 'success' ) {
        		refreshApex(this.confidentialAttachments);
        		this.showSpinner = false;
        	}
        })
        .catch(err => {
        	this.showSpinner = false;
        	this.err = err;
        });
    }
}