import {LightningElement, api, wire} from 'lwc';
import {refreshApex} from '@salesforce/apex';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {NavigationMixin} from 'lightning/navigation';
import {generateUrl} from 'lightning/fileDownload';
import userId from '@salesforce/user/Id';
import checkFileEditPermission from '@salesforce/apex/FileGroupController.getPermissions';
import getFileGroup from '@salesforce/apex/FileGroupController.getFileGroup';
import uploadFileLink from '@salesforce/apex/FileGroupController.uploadFileLink';
import getAllFiles from '@salesforce/apex/FileGroupController.getAllFiles';
import deleteFile from '@salesforce/apex/FileGroupController.deleteFile';
import {getErrorMessages} from 'c/utils';

const COLUMNS = [
	{
		type: 'button-icon',
		typeAttributes: {
			name: {fieldName: 'iconName'},
			variant: 'bare',
			iconName: {fieldName: 'icon'},
		},
		fixedWidth: 40,
	},
	{
		label: 'Title',
		fieldName: 'titleLink',
		type: 'url',
		sortable: true,
		typeAttributes: {
			label: {fieldName: 'titleName'},
			target: '_blank',
			tooltip: {fieldName: 'titleName'},
		},
	},
	{label: 'Type', fieldName: 'fileType'},
	{
		label: 'Last Modified By',
		fieldName: 'lastModifiedBy',
		type: 'url',
		typeAttributes: {
			label: {fieldName: 'lastModifiedByName'},
			target: '_blank',
			tooltip: {fieldName: 'lastModifiedByName'},
		},
	},
	{
		label: 'Last Modified Date',
		fieldName: 'lastModified',
		type: 'date',
		sortable: true,
		typeAttributes: {
			year: 'numeric',
			month: 'numeric',
			day: 'numeric',
			hour: '2-digit',
			minute: '2-digit',
		},
	},
];

const COLUMNSREADONLY = [
	{
		type: 'button-icon',
		typeAttributes: {
			name: {fieldName: 'iconName'},
			variant: 'bare',
			iconName: {fieldName: 'icon'},
		},
		fixedWidth: 40,
	},
	{label: 'Title', fieldName: 'titleLink', type: 'text', sortable: true},
	{label: 'Type', fieldName: 'fileType'},
	{
		label: 'Last Modified By',
		fieldName: 'lastModifiedBy',
		type: 'url',
		typeAttributes: {
			label: {fieldName: 'lastModifiedByName'},
			target: '_blank',
			tooltip: {fieldName: 'lastModifiedByName'},
		},
	},
	{
		label: 'Last Modified Date',
		fieldName: 'lastModified',
		type: 'date',
		sortable: true,
		typeAttributes: {
			year: 'numeric',
			month: 'numeric',
			day: 'numeric',
			hour: '2-digit',
			minute: '2-digit',
		},
	},
];

const INSUFFICIENT_ACCESS = 'INSUFFICIENT_ACCESS_OR_READONLY';
const INSUFFICIENT_ACCESS_ERROR_MESSAGE = 'You do not have access to delete this file.';

export default class FileGroup extends NavigationMixin(LightningElement) {
	//Variables

	// rowId stores the Id of the document in a particular row of table
	rowId;
	// rowType stores the type of document i.e. txt, link, etc
	rowType;
	columns = COLUMNS;
	@api category;
	@api showAddFiles;
	@api showAddLinks;
	@api showDeleteButton;
	@api customPermission;
	@api objectApiName;
	@api recordId;
	@api header = 'Files';
	userId = userId;
	wiredAllFiles;
	fileGroupId;
	records;
	fileName;
	fileLink;
	files;
	links;
	url;
	displayReadMode = true;
	sortBy = 'lastModified';
	sortDirection;
	numberOfFiles = 0;
	isFileUpload = false;
	isFileLinkUpload = false;
	isFileDelete = false;
	isFinalDocsFileDelete = false;

	/*
    Description: wire method to determine the user access level
    Jira Story : IM-41
    */
	/*@wire(checkFileEditPermission, {
		customPermission: '$customPermission',
		category: '$category',
		recordId: '$recordId',
	})
	wirePermissions(result) {
		console.log('##########checkFileEditPermission-result: ' + JSON.stringify(result));
		this.displayReadMode = result.data;
		console.log('##########checkFileEditPermission-this.displayReadMode: ' + this.displayReadMode);
		if(this.displayReadMode === undefined) {
			this.displayReadMode = true;
		}
		if (this.displayReadMode) {
			this.columns = COLUMNSREADONLY;
		} else if (this.showDeleteButton) {
			let deleteColumn = {
				type: 'button-icon',
				typeAttributes: {
					title: 'Delete',
					name: 'delete',
					variant: 'bare',
					iconName: 'utility:delete',
				},
				fixedWidth: 40,
			};
			this.columns = [...this.columns, deleteColumn];
		}
	}*/

	connectedCallback() {
		console.log('##########connectedCallback-this.customPermission: ' + this.customPermission);
		console.log('##########connectedCallback-this.recordId: ' + this.recordId);
		console.log('##########connectedCallback-this.category: ' + this.category);
		if(!this.recordId || !this.category) {
			return;
		}
		checkFileEditPermission({
			customPermission: this.customPermission ?? '',
			category: this.category,
			recordId: this.recordId,
		}).then((result) => {
			this.applyPermission(result);
		}).catch((error) => {
			console.error('Error in checkFileEditPermission: ', error);
		});
	}

	applyPermission(result) {
		console.log('##########applyPermission-result: ' + JSON.stringify(result));
		this.displayReadMode = result;
		console.log('##########applyPermission-this.displayReadMode: ' + this.displayReadMode);
		if (this.displayReadMode) {
			this.columns = COLUMNSREADONLY;
		} else if (this.showDeleteButton) {
			let deleteColumn = {
				type: 'button-icon',
				typeAttributes: {
					title: 'Delete',
					name: 'delete',
					variant: 'bare',
					iconName: 'utility:delete',
				},
				fixedWidth: 40,
			};
			this.columns = [...this.columns, deleteColumn];
		}
	}

	/*
    Description: get the fileGroupId using category, recordId and objectApiName
    Jira Story : IM-41
    */
	@wire(getFileGroup, {
		recordId: '$recordId',
		category: '$category',
		objectApiName: '$objectApiName',
	})
	wireFileGroup(result) {
		this.fileGroupId = result.data;
		//console.log('##########getFileGroup-result: ' + JSON.stringify(result));
		//console.log('##########getFileGroup-fileGroupId: ' + this.fileGroupId);
	}

	/*
    Description: Wire method to get all the Files based on the fileGroupId
    Jira Story : IM-41
    */
	@wire(getAllFiles, {fileGroupId: '$fileGroupId'})
	wireAllFiles(result) {
		const {data, error} = result;
		this.wiredAllFiles = result;
		console.log('##########getallfiles-result: ' + JSON.stringify(result));
		if (data) {
			this.files = JSON.parse(JSON.stringify(data.Files));
			this.links = JSON.parse(JSON.stringify(data.Links));
			this.files.forEach((file) => {
				file.lastModified = file.ContentDocument.ContentModifiedDate;
				file.titleName = file.ContentDocument.Title;
				file.lastModifiedBy = '/' + file.ContentDocument.LatestPublishedVersion.ContentModifiedById;
				file.lastModifiedByName = file.ContentDocument.LatestPublishedVersion.ContentModifiedBy.Name;
				file.fileType = file.ContentDocument.FileExtension;
				if (this.displayReadMode) {
					file.titleLink = file.ContentDocument.Title;
				} else {
					file.titleLink = '/lightning/page/filePreview?selectedRecordId=' + file.ContentDocumentId;
				}
				file.contentSize = this.getFileSize(file.ContentDocument.ContentSize);
				file.icon = 'utility:download';
				file.iconName = 'download';
			});
			this.links.forEach((link) => {
				link.lastModified = link.LastModifiedDate;
				link.titleName = link.Name;
				link.lastModifiedBy = '/' + link.LastModifiedById;
				link.lastModifiedByName = link.LastModifiedBy.Name;
				link.fileType = 'Link';
				if (this.displayReadMode) {
					link.titleLink = link.Name;
				} else {
					link.titleLink = link.Link_URL__c;
				}
				link.icon = 'utility:new_window';
				link.iconName = 'open_link';
			});
			this.records = [...this.files, ...this.links];
			this.numberOfFiles = this.records.length;
			this.sortData('lastModified', 'desc');
		} else if (error) {
			console.log(error);
		}
	}

	/*
    Description: handle file upload, on finish displays a success toast
    Jira Story : IM-41
    */
	handleUploadFinished(event) {
		const uploadedFiles = event.detail.files;
		this.dispatchEvent(
			new ShowToastEvent({
				title: 'Success',
				message: uploadedFiles.length + ' Files uploaded Successfully',
				variant: 'success',
			})
		);
		this.isFileUpload = false;
		refreshApex(this.wiredAllFiles);
	}

	/*
    Description: handle file upload and makes the respective boolean true
    Jira Story : IM-41
    */
	handleFileUpload(event) {
		this.isFileUpload = true;
	}

	/*
    Description: handle file link upload and makes the respective boolean true
    Jira Story : IM-41
    */
	handleFileLinkUpload(event) {
		this.isFileLinkUpload = true;
	}

	/*
    Description: handles the close operation
    Jira Story : IM-41
    */
	handleClose() {
		this.isFileUpload = false;
		this.isFileLinkUpload = false;
		this.isFileDelete = false;
	}

	/*
    Description: handles row level actions for delete, download or open link
    Jira Story : IM-41
    */
	handleRowAction(event) {
		const actionName = event.detail.action.name;
		const row = event.detail.row;
		switch (actionName) {
			case 'delete':
				if (row.fileType == 'Link') {
					this.rowId = row.Id;
				} else {
					this.rowId = row.ContentDocumentId;
				}
				this.rowType = row.fileType;
				this.isFileDelete = true;
				break;
			default:
				switch (row.iconName) {
					case 'download':
						this.url = generateUrl(row.ContentDocumentId);
						window.open(this.url);
						break;
					case 'open_link':
						this.navigateToFileLink(row.Link_URL__c);
						break;
					default:
						break;
				}
		}
	}

	/*
    Description:  handles file Name Change operation
    Jira Story : IM-41
    */
	handleFileNameChange(event) {
		this.fileName = event.detail.value;
		let inputName = this.template.querySelector('.inputName');
		inputName.setCustomValidity('');
		inputName.reportValidity();
	}

	/*
    Description: handles fileLinkChange operation
    Jira Story : IM-41
    */
	handleFileLinkChange(event) {
		this.fileLink = event.detail.value;
		let inputURL = this.template.querySelector('.inputURL');
		inputURL.setCustomValidity('');
		inputURL.reportValidity();
	}

	/*
    Description: triggered on submnit operation for fileGroup or FileLink
    Jira Story : IM-41
    */
	handleSubmit(event) {
		event.preventDefault();
		if (!this.fileName) {
			let inputName = this.template.querySelector('.inputName');
			inputName.setCustomValidity('Please Enter File Name');
			inputName.reportValidity();
		} else if (!this.fileLink) {
			let inputURL = this.template.querySelector('.inputURL');
			inputURL.setCustomValidity('Please Enter File URL');
			inputURL.reportValidity();
		} else {
			this.uploadFileLink();
		}
	}

	/*
    Description: triggerd on the click of delete row level action
    Jira Story : IM-41
    */
	handleDelete() {
		this.deleteFile();
	}

	/*
    Description: handles the fileLink upload
    Jira Story : IM-41
    */
	async uploadFileLink() {
		uploadFileLink({
			fileGroupId: this.fileGroupId,
			fileName: this.fileName,
			fileLink: this.fileLink,
		})
			.then((result) => {
				this.showSuccessToast('Files uploaded Successfully');
				this.isFileLinkUpload = false;
				refreshApex(this.wiredAllFiles);
			})
			.catch((error) => {
				this.showErrorToast('Error: ' + JSON.stringify(error));
			});
	}

	/*
    Description: triggerd on the click of row level delete action, handles the file delete.
    Jira Story : IM-41
    */
	async deleteFile() {
		deleteFile({recordId: this.rowId, fileType: this.rowType})
			.then(() => {
				this.showSuccessToast('File deleted Successfully');
				this.isFileDelete = false;
				refreshApex(this.wiredAllFiles);
			})
			.catch((error) => {
				let errorMessages = getErrorMessages(error);
				let errorMessage = errorMessages[0];
				if(errorMessage.includes(INSUFFICIENT_ACCESS)) {
					this.showErrorToast(INSUFFICIENT_ACCESS_ERROR_MESSAGE);
				} else {
					this.showErrorToast('Error: ' + errorMessage);
				}
			});
	}

	/*
    Description: initiates the download of the file
    Jira Story : IM-41
    */
	downloadFile(file) {
		this[NavigationMixin.Navigate](
			{
				type: 'standard__webPage',
				attributes: {
					url: file.downloadUrl,
				},
			},
			false
		);
	}

	/*
    Description: navigates the page to the fileLink url
    Jira Story : IM-41
    */
	navigateToFileLink(fileLink) {
		if (!fileLink.includes('https://') && !fileLink.includes('http://')) {
			fileLink = 'https://' + fileLink;
		}
		window.open(fileLink, '_blank');
	}

	/*
    Description: returns the file Size in B, KB, MB etc.,
    Jira Story : IM-41
    */
	getFileSize(bytes) {
		bytes = parseFloat(bytes);
		if (bytes == 0) return '0B';
		var k = 1024;
		var sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
		var i = Math.floor(Math.log(bytes) / Math.log(k));
		return parseFloat((bytes / Math.pow(k, i)).toFixed(0)) + sizes[i];
	}

	/*
    Description: handles the sort logic for dataTable
    Jira Story : IM-41
    */
	doSorting(event) {
		this.sortBy = event.detail.fieldName;
		this.sortDirection = event.detail.sortDirection;
		let orderBy = event.detail.fieldName == 'titleLink' ? 'titleName' : event.detail.fieldName;
		this.sortData(orderBy, this.sortDirection);
	}

	/*
    Description: handles the data sort on the dataTable
    Jira Story : IM-41
    */
	sortData(fieldname, direction) {
		let parseData = JSON.parse(JSON.stringify(this.records));
		let keyValue = (a) => {
			return a[fieldname];
		};
		let isReverse = direction === 'asc' ? 1 : -1;
		parseData.sort((x, y) => {
			x = keyValue(x) ? keyValue(x) : '';
			y = keyValue(y) ? keyValue(y) : '';
			return isReverse * ((x > y) - (y > x));
		});
		this.records = parseData;
	}

	/*
    Description: shows an error toast message 
    Jira Story : IM-41
    */
	showErrorToast(displayMessage) {
		const errorEvt = new ShowToastEvent({
			title: 'Error',
			message: displayMessage,
			variant: 'error',
			mode: 'dismissable',
		});
		this.dispatchEvent(errorEvt);
	}

	/*
    Description: shows a successful toast message 
    Jira Story : IM-41
    */
	showSuccessToast(displayMessage) {
		const errorEvt = new ShowToastEvent({
			title: 'Success',
			message: displayMessage,
			variant: 'success',
			mode: 'dismissable',
		});
		this.dispatchEvent(errorEvt);
	}
}