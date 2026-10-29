import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveConfidentialAttachment from '@salesforce/apex/ConfidentialItemUploadController.saveConfidentialAttachment';
import checkUserCreationPermission from '@salesforce/apex/ConfidentialItemUploadController.checkUserCreationPermission';

export default class interactionConfidentialFile extends NavigationMixin(LightningElement) {
	@api recordId;
	@api navigateToList;
	showUpload = false;
	showSpinner = false;
	file;
	fileName;
	title;
	message;
	variant;
	err;
	noAccess;

	@wire(checkUserCreationPermission, { parentId: '$recordId' }) 
	getOrganizations(result){
		if( result.data ) {
			this.noAccess = result.data === 'true'?false:true;
			this.showUpload = result.data === 'true'?false:true;
		}

		if(result.error) {
			this.err = result.error;
		}
	}

	handleFilesChange(event) {
		this.showUpload = false;
		let file = event.target.files;
	
		this.file = file[0];
		this.fileName = file[0].name;

	}

	handleUpload(event) {
		this.showSpinner = true;
		let fileReader = new FileReader();
		fileReader.onload = (() => {
			let fileContents = fileReader.result;
            let base64 = 'base64,';
            let content = fileContents.indexOf(base64) + base64.length;
            fileContents = fileContents.substring(content);
            
            saveConfidentialAttachment({
            	parentId: this.recordId,
            	fileName: this.fileName,
            	base64Data: fileContents,
            	contentType: this.file.type
            })
            .then(result => {
            	this.showSpinner = false;
            	this.returnToParentPage();
            	this.err = undefined;
            })
            .catch(err => {
            	this.showSpinner = false;
            	this.fileName = err.body.message;
            	this.err = err;
            	this.result = undefined;
            });
		});
		fileReader.readAsDataURL(this.file);
	}

	handleCancel(event) {
		event.preventDefault();
		this.returnToParentPage();
	}

	returnToParentPage() {
		this.navigateToList('/'+this.recordId);
	}

}