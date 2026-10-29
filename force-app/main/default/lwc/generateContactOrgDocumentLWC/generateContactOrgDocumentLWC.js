import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRestrictedContactForGenerateBio from '@salesforce/apex/GenerateBioReportAuraCtrl.getRestrictedContactForGenerateBio';
import getRestrictedContactCountFromLists from '@salesforce/apex/GenerateBioReportAuraCtrl.getRestrictedContactCountFromLists';
import getRestrictedOrgCount from '@salesforce/apex/GenerateBioReportAuraCtrl.getRestrictedOrgCount';
import hasPrivateNameFieldsAccess from '@salesforce/customPermission/Private_Name_Fields';

export default class GenerateContactOrgDocumentLWC extends NavigationMixin(LightningElement) {
	startDate;
	endDate;
	minAmount = 10000;
	showFocusArea = false;
	showProject = false;
	showDonor = true;
	selectedFilter = 'Donor';
	fullUrl;
	error;
	sortBy = 'Donor';
	includeCoverPage = false;
	coverPage = 'true';
	activeDonors = false;
	getActiveDonors = 'false';
	selectedDonorListObj = [];
	endDate;
	restrictedContactCount;
	contactDisplayFields = ['Search_Display_Name__c', 'Title', 'Email_Org_Name__c', 'MailingCity', 'MailingState'];
	contactSearchFields = ['Search_Display_Name__c', 'Converted_Full_Name__c'];
	contactFilterClause = `Id IN (SELECT Contact__c FROM Donor__c WHERE Credit_Type__c = 'Donor - Primary' AND Pledge__r.Exclude_FROM_Donor_memo__c = false AND Pledge__r.Status__c = 'Pledged' AND Pledge__r.Report_Amount_USD__c != null)`;

	orgDisplayFields = ['Search_Display_Name__c', 'AKA__c', 'Legal_Name__c'];
	orgSearchFields = ['Search_Display_Name__c', 'Converted_Org_Name__c'];
	orgFilterClause = `Id IN (SELECT Organization__c FROM Donor__c WHERE Credit_Type__c = 'Donor - Primary' AND Pledge__r.Exclude_FROM_Donor_memo__c = false AND Pledge__r.Status__c = 'Pledged' AND Pledge__r.Report_Amount_USD__c != null)`;

	projectDisplayFields = ['Name'];
	projectSearchConfig = JSON.stringify({
		primaryField: 'Name',
		primaryWeight: 100
	});

	listDisplayFields = ['Name', 'ListMemberCount__c', 'Event_Start_Date_Time__c'];
	listDisplayFieldPrefixes = ['', 'List Member Count', 'Event Start Date/Time'];
	listFilterClause = `Id != null`;
	listSearchConfig = JSON.stringify({
		primaryField: 'Name',
		primaryWeight: 100,
		convertedField: 'Converted_List_Name__c',
		convertedWeight: 80
	});

	showRecentlyViewed = false;
	allowNewRecord = false;
	listDefaultFilterClause = 'Id != null';
	listDefaultOrderByClause = 'Name ASC';
	projectDefaultFilterClause = 'Id != null';
	projectDefaultOrderByClause = 'Name ASC';

	@track options = [
		{ label: 'Arts', value: 'Arts' },
		{ label: 'Education', value: 'Education' },
		{ label: 'Environment', value: 'Environment' },
		{ label: `Founder's Projects`, value: `Founders Projects` },
		{ label: 'Government Innovation', value: 'Government Innovation' },
		{ label: 'Public Health', value: 'Public Health' }
	];

	selectFilterOptions = [
		{ label: 'Focus Area', value: 'Focus Area' },
		{ label: 'Project', value: 'Project' },
		{ label: 'Donor', value: 'Donor' }
	];

	selectedOptions = [];
	url;



	@track selectedProjects = [];
	@track selectedProjectsObj = [];







	@track selectedDonorContacts = [];
	@track selectedDonorContactsObj = [];







	@track selectedDonorOrgs = [];
	@track selectedDonorOrgsObj = [];



	@track selectedDonorLists = [];

































	get todayIso() {
		const d = new Date();
		d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
		return d.toISOString().slice(0, 10);
	}

	get shallDisableDateCheckbox() {
		return this.activeDonors;
	}






















	connectedCallback() {
		if (!this.endDate) {
			this.endDate = this.todayIso;
		}

		if (!this.startDate) {
			this.startDate = '1980-01-01';
		}
	}





















	handleOptionsChange(event) {
		this.selectedOptions = event.target.value;
	}

	handleIncludeCoverPageChange(event) {
		this.includeCoverPage = event.detail.checked;
		this.coverPage = this.includeCoverPage ? 'true' : 'false';
	}

	handleDateSelection(event) {
		this.error = undefined;
		const field = event.target.name;
		if (field === 'startDate') {
			this.startDate = event.target.value;
		} else if (field === 'endDate') {
			this.endDate = event.target.value;
		}
		if (this.startDate !== undefined && this.endDate !== undefined && this.endDate < this.startDate) {
			this.error = '*Please select To Date greater than From Date';
		}
	}

	handleActiveDonorCheckbox(event) {
		this.error = undefined;
		this.activeDonors = event.detail.checked;
		this.getActiveDonors = this.activeDonors ? 'true' : 'false';
	}

	async handleGenerateReport() {

		await this.getrestrictedContactCount();
		if ((!this.startDate || !this.endDate) && !this.activeDonors) {












			this.error = '*Please select both Pledge Start and End Dates';
		} else if (this.minAmount < 1 && this.minAmount != undefined && this.minAmount != '') {
			this.error = '*Amount cannot be less than 1';
		} else if (this.selectedFilter === undefined || this.selectedFilter === '') {
			this.error = '*Please select a filter';
		} else if ((this.selectedFilter === 'Focus Area' && this.selectedOptions.length === 0) ||
			(this.selectedFilter === 'Project' && this.selectedProjects.length === 0) ||
			(this.selectedFilter === 'Donor' && this.selectedDonorOrgs.length === 0 &&
				this.selectedDonorContacts.length === 0 && this.selectedDonorLists.length === 0)) {

			this.error = '*Please select atleast one filter by value(Focus Area/Project/Donor)';
		} else {
			this.error = undefined;
			if (this.minAmount == undefined || this.minAmount == '') this.minAmount = 1;
			this.fullUrl = `/apex/DocGeneration?docGenerateType=ContactOrgBioDoc&minAmount=${this.minAmount}
							&startDate=${this.startDate}&endDate=${this.endDate}&selectedOptions=${this.selectedOptions}
							&selectedOrganizations=${this.selectedDonorOrgs}&selectedContacts=${this.selectedDonorContacts}
							&selectedLists=${this.selectedDonorLists}
							&selectedProjects=${this.selectedProjects}&sortBy=${this.sortBy}&coverPage=${this.includeCoverPage}
							&getActiveDonors=${this.getActiveDonors}&retURL=/apex/GenerateContactOrgDocument`;
			window.open(this.fullUrl, "_self");
		}
	}

	handleAmountChange(e) {
		this.minAmount = e.detail.value;
	}

	handleSelectFilterChange(e) {
		this.showFocusArea = false;
		this.showProject = false;
		this.showDonor = false;
		this.selectedFilter = e.detail.value;
		if (this.selectedFilter === 'Focus Area') {
			this.showFocusArea = true;
		} else if (this.selectedFilter === 'Project') {
			this.showProject = true;
		} else if (this.selectedFilter === 'Donor') {
			this.showDonor = true;
		}
	}

	handleSortByChange(event) {
		this.sortBy = event.detail.value;
	}












	navigateToWebPage() {
		this[NavigationMixin.GenerateUrl]({
			type: 'standard__webPage',
			attributes: {
				url: this.fullUrl
			},
		}).then(generatedURL => {
			window.open(generatedURL, "_self");
		});













	}





























	handleDonorContactSelected(event) {
		const selectedRecords = event.detail.selectedRecords || [];
		this.selectedDonorContactsObj = selectedRecords.map(r => ({ Id: r.Id, label: r.fields['Search_Display_Name__c'] || r.Id }));
		this.selectedDonorContacts = selectedRecords.map(r => r.Id);




	}

	handleDonorOrgsSelected(event) {
		const selectedRecords = event.detail.selectedRecords || [];
		this.selectedDonorOrgsObj = selectedRecords.map(r => ({ Id: r.Id, label: r.fields['Search_Display_Name__c'] || r.Id }));
		this.selectedDonorOrgs = selectedRecords.map(r => r.Id);


















	}

	handleProjectSelected(event) {
		const selectedRecords = event.detail.selectedRecords || [];
		this.selectedProjectsObj = selectedRecords.map(r => ({ Id: r.Id, label: r.fields['Name'] || r.Id }));
		this.selectedProjects = selectedRecords.map(r => r.Id);





































	}

	handleListSelected(event) {
		const selectedRecords = event.detail.selectedRecords || [];
		this.selectedDonorListObj = selectedRecords.map(r => ({ name: r.Id, label: r.fields['Name'] || r.Id }));
		this.selectedDonorLists = selectedRecords.map(r => r.Id);














	}

	async getrestrictedContactCount() {
		debugger;
		let restrictedContactCount = 0;
		let restrictedOrgCount = 0;

		try {
			if (this.selectedDonorContacts?.length) {
				const contactData = await getRestrictedContactForGenerateBio({ contactIds: this.selectedDonorContacts });
				restrictedContactCount += contactData;
			}















			if (this.selectedDonorLists?.length) {
				const listData = await getRestrictedContactCountFromLists({
					listIds: this.selectedDonorLists
				});












				restrictedContactCount += listData;
			}






















			if (this.selectedDonorOrgs?.length) {
				const orgData = await getRestrictedOrgCount({ orgIds: this.selectedDonorOrgs });
				restrictedOrgCount += orgData;






			}




			const totalRestricted = restrictedContactCount + restrictedOrgCount;

			if (totalRestricted > 0) {
				this.restrictedContactCount = totalRestricted;

				// With Private_Name_Fields access: informational "results contain" message.
				// Without access: "records are not exporting" + contact brmpartnerships.
				let alertMessage = 'Your results contain ' + totalRestricted + ' Private record(s).';

				if (!hasPrivateNameFieldsAccess) {
					alertMessage +=
						'\n\n' +
						`You've encountered a problem with some of the records you selected ` +
						`(${totalRestricted} records are not exporting). ` +
						`Please contact brmpartnerships@bloomberg.org for further assistance.`;
				}

				window.alert(alertMessage);

			}
		} catch (error) {
			console.log('Error Message - ' + error.message);
		}
	}

}