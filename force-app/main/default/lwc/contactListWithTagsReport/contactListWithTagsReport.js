import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getAllContactListTags from '@salesforce/apex/ContactListWithTagsReportController.getAllContactListTags';
import getContactListTagData from '@salesforce/apex/ContactListWithTagsReportController.getContactListTagData';
import getUpdatedData from '@salesforce/apex/ContactListWithTagsReportController.getUpdatedData';
import getSavedSearches from '@salesforce/apex/ListTagSavedSearchController.getSavedSearches';
import deleteSearch from '@salesforce/apex/ListTagSavedSearchController.deleteSearch';

const columns = [
    { label: 'First/Preferred First Name', fieldName: 'preferredName', hideDefaultActions: 'true', sortable: false, editable: false },
    { label: 'Last Name', fieldName: 'lastNameURL', type: 'url', hideDefaultActions: 'true', sortable: false, editable: false,
      typeAttributes: {label: { fieldName: 'lastName' }, target: '_blank'}},
    { label: 'Significant Other Name(Preferred)', fieldName: 'significantOtherNamePreferred', hideDefaultActions: 'true', sortable: false, editable: false },
    { label: 'Title', fieldName: 'title', hideDefaultActions: 'true', sortable: false, editable: false },
    { label: 'Organization', fieldName: 'organization', hideDefaultActions: 'true', sortable: false, editable: false },
    { label: 'Priority Email', fieldName: 'priorityEmail', hideDefaultActions: 'true', sortable: false, editable: false },
    { label: 'Source - Generated Results', fieldName: 'source', hideDefaultActions: 'true', sortable: false, editable: false, wrapText: true, initialWidth: 280 } 
];

export default class ContactListWithTagsReport extends LightningElement {
    @track paginatedData = [];
    @track campaignDefaultIds = [];
    @track tagDefaultIds = [];
    @track contactDefaultIds = [];
    selectedTags = [];
    selectedLists = [];
    contactListTagData = [];
    columns = columns;
    contactOptions;
    tagOptions;
    selectedContactIds = [];
    selectedListIds = [];
    selectedTagIds = [];
    isLoading = false;
    isShowAddToListModal = false;
    isShowNewModal = false;
    contactIds = [];
    contactSources = [];
    listOptions = [];
    listValues = [];
    removeDuplicates = false;
    restrictedContactsCount = 0;
    showExport = false;
    doNotContactCount = 0;
    totalPages = 1;
    currentPage = 1;
    pageSize = 200;
    isDesktop = false;
    isSmallDevice = false;
    showTable = false;
    showSaveSearchModal = false;
    selectedSavedSearch;
    savedSearchOptions;
    savedSearchRecords;
    selectedSavedSearchId;
    allListOptions;
    allTagOptions;
    showDeleteModal = false;
    disableDeleteButton = true;

    campaignDisplayFields = ['Name', 'ListMemberCount__c','Event_Start_Date_Time__c'];
    campaignDisplayFieldPrefixes = ['', 'List Member Count', 'Event Start Date/Time'];
    campaignSearchFields = ['Name','Converted_List_Name__c'];
    campaignSearchConfig = JSON.stringify({
        primaryField: 'Name',
        primaryWeight: 100,
        convertedField: 'Converted_List_Name__c',
        convertedWeight: 80
    });
    tagDisplayFields = ['Name', 'Member_Count__c'];
    tagDisplayFieldPrefixes = ['', 'Count',];
    tagSearchFields = ['Name'];
    contactDisplayFields = ['Search_Display_Name__c', 'Title', 'Email_Org_Name__c'];
    contactDisplayFieldPrefixes = ['', '', ''];
    contactSearchFields = ['Search_Display_Name__c','Email'];
    disableNewRecord = false;

    get addToListdisabled() {
        return !(this.contactListTagData.length > 0);
    }

    get totalCount() {
        return 'Total Number of Records: ' + this.contactListTagData.length;
    }

    get totalDoNotContactCount() {
        return 'Total Number of Do Not Contact Records: ' + this.doNotContactCount;
    }

    get shallShowPagination() {
        return this.totalPages > 1;
    }

    get availableListsString() {
        return this.listOptions && this.listOptions.length
            ? this.listOptions.map(option => option.value).join(',')
            : '';
    }

    get listIdsString() {
        return this.selectedListIds && this.selectedListIds.length
            ? this.selectedListIds.join(',')
            : '';
    }

    get selectedListsString() {
        return this.listValues && this.listValues.length
            ? this.listValues.join(',')
            : '';
    }

    get selectedAdditionalContactsString() {
        return this.selectedContactIds && this.selectedContactIds.length ? this.selectedContactIds.join(',') : '';
    }

    get selectedTagsString() {
        return this.selectedTagIds && this.selectedTagIds.length ? this.selectedTagIds.join(',') : '';
    }

    connectedCallback() {
        this.fieldValues = this.preSelectedColumns;
        if(FORM_FACTOR === 'Large') this.isDesktop = true;
        else this.isSmallDevice = true;
        this.loadSavedSearches();
    }

    handlePageChange(event) { 
        this.currentPage = Number(event.detail.page);
        this.updatePaginatedData();
    }

    handleListChange(event) {
        this.selectedListIds = [];
        var selectedLists = event.detail;
        selectedLists.forEach(selectedList =>{
            this.selectedListIds.push(selectedList.value);
        });
    }

    handleRunReport() {
        this.getContactListTagData();
    }

    handleClear() {
        this.template.querySelector('[data-id="campaign-lookup"]').clearSelection();
        this.template.querySelector('[data-id="tag-lookup"]').clearSelection();
        this.template.querySelector('[data-id="contact-lookup"]').clearSelection();
        this.contactListTagData = [];
        this.paginatedData = [];
        this.totalPages = 1;
        this.listOptions = [];
        this.listValues = [];
        this.selectedContactIds = [];
        this.selectedListIds = [];
        this.selectedTagIds = [];
        this.removeDuplicates = false;
        this.doNotContactCount = 0;
        this.selectedSavedSearchId = null;
        this.selectedSavedSearch = null;
        this.campaignDefaultIds = [];
        this.tagDefaultIds = [];
        this.contactDefaultIds = [];
    }

    handleExportReport() {
        this.showExport = true;
    }

    handleCloseExport(event) {
        let isExport = event && event.detail && event.detail.isExport;
        this.showExport = false;
        if (isExport) {
            setTimeout(() => {
                this.handleClear();
            }, 500);
        }
    }

    handleOpenSaveSearch() {
        const popup = this.template.querySelector('[data-id="saved-search-popup"]');
        if (popup) {
            popup.showModal = true;
        }
    }

    handleSearchSaved(event) {
        this.showSaveSearchModal = false;
        if (event && event.detail && event.detail.savedSearchId) {
            const newId = event.detail.savedSearchId;

            this.selectedSavedSearchId = null;

            getSavedSearches()
                .then(data => {
                    this.savedSearchRecords = data;
                    this.savedSearchOptions = data && data.length
                            ? data.map(s => ({ label: this.formatSavedSearchLabel(s), value: s.Id }))
                            : [];
                    
                    Promise.resolve().then(() => {
                        this.selectedSavedSearchId = newId;
                        this.selectedSavedSearch = this.savedSearchRecords.find(s => s.Id === newId);
                        this.disableDeleteButton = false;
                    });
                })
                .catch(error => {
                    console.log('getSavedSearches error: ' + JSON.stringify(error));
                });
        } else {
            this.loadSavedSearches();
        }
    }

    loadSavedSearches() {
        getSavedSearches().then(data => {
            this.savedSearchRecords = data;
            this.savedSearchOptions = data && data.length
                ? data.map(s => ({ label: this.formatSavedSearchLabel(s), value: s.Id }))
                : [];
        }).catch(error => {
            console.log('getSavedSearches error: ' + JSON.stringify(error));
        });
    }

    formatSavedSearchLabel(record) {
        if (!record) return '';

        const dt = new Date(record.LastModifiedDate);

        const formattedDate = dt.toLocaleString('en-US', {
            month: 'numeric',
            day: 'numeric',
            year: 'numeric',
            hour: 'numeric',
            minute: '2-digit'
        });

        const listCount = record.List_IDs__c ? record.List_IDs__c.split(',').filter(x => x).length : 0;
        const tagCount = record.Selected_Tags__c ? record.Selected_Tags__c.split(',').filter(x => x).length : 0;
        const contactCount = record.Selected_Additional_Contacts__c ? record.Selected_Additional_Contacts__c.split(',').filter(x => x).length : 0;

        return `${record.Name} | ${formattedDate} | Lists: ${listCount} | Tags: ${tagCount} | Contacts: ${contactCount}`;
    }


    handleSavedSearchChange(event) {
        this.selectedSavedSearchId = event.detail.value;
        this.disableDeleteButton = !this.selectedSavedSearchId;
        if(this.savedSearchRecords && this.savedSearchRecords.length) {
            this.selectedSavedSearch = this.savedSearchRecords.find(s => s.Id === this.selectedSavedSearchId);
        } else {
            this.selectedSavedSearch = null;
        }

        if(this.selectedSavedSearch) {

            getAllContactListTags({
                listIdsCSV:this.selectedSavedSearch.List_IDs__c,
                tagIdsCSV:this.selectedSavedSearch.Selected_Tags__c,
                contactIdsCSV:this.selectedSavedSearch.Selected_Additional_Contacts__c
            }).then(data => {

                this.allListOptions = data.lists;
                this.allTagOptions = data.tags;
                this.contactOptions = data.contacts;

                let missingFound = false;

                const availableIds = this.selectedSavedSearch.Available_Lists__c ? this.selectedSavedSearch.Available_Lists__c.split(',').filter(x => x) : [];
                const selectedIds = this.selectedSavedSearch.Selected_Lists__c ? this.selectedSavedSearch.Selected_Lists__c.split(',').filter(x => x) : [];
                const lookupIds = this.selectedSavedSearch.List_IDs__c ? this.selectedSavedSearch.List_IDs__c.split(',').filter(x => x) : [];
                const tagIds = this.selectedSavedSearch.Selected_Tags__c ? this.selectedSavedSearch.Selected_Tags__c.split(',').filter(x => x) : [];

                let options = [];
                if(this.allListOptions && this.allListOptions.length) {
                    availableIds.forEach(id => {
                        const match = this.allListOptions.find(o => o.value === id);
                        if(match) {
                            options.push({ label: match.label, value: match.value });
                        } else {
                            missingFound = true;
                        }
                    });
                }

                this.listOptions = options;

                let filteredSelectedIds = [];
                selectedIds.forEach(id => {
                    const match = this.allListOptions ? this.allListOptions.find(o => o.value === id) : null;
                    if(match) {
                        filteredSelectedIds.push(id);
                    } else {
                        missingFound = true;
                    }
                });
                this.listValues = filteredSelectedIds;

                let filteredLookupIds = [];
                lookupIds.forEach(id => {
                    const match = this.allListOptions ? this.allListOptions.find(o => o.value === id) : null;
                    if(match) {
                        filteredLookupIds.push(id);
                    } else {
                        missingFound = true;
                    }
                });
                this.selectedListIds = filteredLookupIds;

                let filteredTagIds = [];
                tagIds.forEach(id => {
                    const match = this.allTagOptions ? this.allTagOptions.find(o => o.value === id) : null;
                    if(match) {
                        filteredTagIds.push(id);
                    } else {
                        missingFound = true;
                    }
                });
                this.selectedTagIds = filteredTagIds;

                this.campaignDefaultIds = [...filteredLookupIds];
                this.tagDefaultIds = [...filteredTagIds];

                if (this.selectedSavedSearch.Selected_Additional_Contacts__c) {
                    const addContactIds = this.selectedSavedSearch.Selected_Additional_Contacts__c
                        .split(',')
                        .filter(x => x);

                    let filteredAddIds = [];

                    if (this.contactOptions && this.contactOptions.length) {
                        addContactIds.forEach(id => {
                            const match = this.contactOptions.find(o => o.value === id);
                            if (match) {
                                filteredAddIds.push(id);
                            } else {
                                missingFound = true;
                            }
                        });
                    }

                    this.selectedContactIds = filteredAddIds;
                    this.contactDefaultIds = [...filteredAddIds];
                }

                if(missingFound) {
                    this.showToast(
                        'One or more search criteria no longer exist in BRM.',
                        'Please review.',
                        'warning',
                        'sticky'
                    );
                }

            }).catch(error => {
                console.log('getAllContactListTags error: ' + JSON.stringify(error));
            });
        }
    }

    getAllContactListTags() {
        getAllContactListTags(
        ).then((data) => { 
            if (data) {
                this.contactOptions = data.contacts;
                this.listOptions = data.lists;
                this.tagOptions = data.tags;
            }
        }).catch((error) => {    
            console.log('getAllContactListTags error: ' + JSON.stringify(error));
        });
    }

    async getContactListTagData() {
        this.contactListTagData = [];
        this.isLoading = true;
        this.doNotContactCount = 0;
        this.contactIds = [];
        this.contactSources = [];
        const allListIds = this.selectedListIds || [];
        const listChunks = [];
        for(let i = 0; i < allListIds.length; i += 1) {
            listChunks.push(allListIds.slice(i, i + 1));
        }
        let existingDataWrapperMap = new Map();
        let allData = [];
        if(listChunks.length > 0) {
            for(let chunk of listChunks) {
                try {
                    const data = await getContactListTagData({
                        contactIds: this.selectedContactIds,
                        listIds: chunk,
                        tagIds: this.selectedTagIds
                    });
                    data.forEach(record => {
                        if(existingDataWrapperMap[record.id]) {
                            this.deepMerge(existingDataWrapperMap[record.id], record);
                        } else {
                            existingDataWrapperMap[record.id] = record; 
                        }
                    });
                } catch(error) {
                    this.isLoading = false;
                    if(error.body && error.body.message && error.body.message.includes('size too large')) {
                        this.showToast('Your search returned too many records.', 
                                    'Please narrow your search criteria and try again.', 
                                    'error',
                                    'dismissible'
                        );
                    }
                    console.error('getContactListTagData error:', error);
                    return;
                }
                await this.sleep(2000);
            }
        } else {
            const data = await getContactListTagData({
                contactIds: this.selectedContactIds,
                listIds: this.selectedListIds,
                tagIds: this.selectedTagIds
            });
            data.forEach(record => {
                if(existingDataWrapperMap[record.id]) {
                    this.deepMerge(existingDataWrapperMap[record.id], record);
                } else {
                    existingDataWrapperMap[record.id] = record; 
                }
            });
        }
        let tempConList = []; 
        let tempContactIds = [];
        let tempContactSources = [];
        let tempRestrictedCount=0;
        let tempDoNotCount = 0;
        for(const key in existingDataWrapperMap) {
            let parts = [];
            if(existingDataWrapperMap[key].listSource && 
               Object.keys(existingDataWrapperMap[key].listSource).length > 0) {

                let listSourceList = Object.values(existingDataWrapperMap[key].listSource).sort();
                parts.push('List(s): ' + listSourceList.join('; '));
            }
            if(existingDataWrapperMap[key].tagSource && existingDataWrapperMap[key].tagSource.trim() !== '') {
                parts.push('Tag(s): ' + existingDataWrapperMap[key].tagSource);
            }
            if(existingDataWrapperMap[key].contactSource) {
                parts.push('Contact: ' + existingDataWrapperMap[key].contactSource);
            }
            let finalSource = parts.join('\n');
            existingDataWrapperMap[key].source = finalSource;
            allData.push(existingDataWrapperMap[key]);
        }	
        allData.forEach((record) => {
            let tempConRec = Object.assign({}, record);  
            tempConRec.lastNameURL = '/' + tempConRec.id;
            tempConList.push(tempConRec);
            tempContactIds.push(tempConRec.id);
            tempContactSources.push({'key':tempConRec.id, 'value':record.source});
            if(record.doNotContact) tempDoNotCount++;
            if(record.restrictedContact) tempRestrictedCount++;
        });                        
        this.contactListTagData = tempConList;
        this.contactIds = tempContactIds;
        this.contactSources = tempContactSources;
        this.restrictedContactsCount = tempRestrictedCount;
        this.doNotContactCount = tempDoNotCount;
        this.totalPages = Math.ceil(this.contactListTagData.length / this.pageSize);
        this.currentPage = 1;
        this.contactListTagData.sort((a, b) => {
            if(a.lastName > b.lastName) return 1;
            if(a.lastName < b.lastName) return -1;
            return 0;
        });
        this.updatePaginatedData();
        this.isLoading = false;
        if(this.restrictedContactsCount > 0) {
            let title = 'Your results contain ' + 
						this.restrictedContactsCount + ' Private Contact(s).';
            let warningMessage = 
				'';
            this.showToast(title, warningMessage, 'warning','dismissible');
        }
    }

    deepMerge(target, source) {
        for (const key in source) {
            if(source.hasOwnProperty(key) && typeof source[key] === 'object' && 
               source[key] !== null && !Array.isArray(source[key])) {
                if(!target[key]) target[key] = {};
                this.deepMerge(target[key], source[key]);
            } else {
                target[key] = source[key];
            }
        }
        return target;
    }

    sleep(DELAY) {
        return new Promise(resolve => setTimeout(resolve, DELAY));
    }

    contactSelected(event) {
        this.selectedContactIds = event.detail.selectedIds || [];
        if(this.selectedContactIds.length === 0 && this.selectedTagIds.length === 0) {
            this.contactListTagData = [];
        }
    }

    listSelected(event) {
        const selectedRecords = event.detail.selectedRecords || [];
        this.selectedListIds = event.detail.selectedIds || [];
        this.listOptions = [];
        this.listValues = [];
        selectedRecords.forEach(record => {
            const id = record.Id;
            const name = record.fields && record.fields.Name ? record.fields.Name : '';
            this.listValues.push(id);
            this.listOptions.push({ label: name, value: id });
        });
        if(this.selectedListIds.length === 0 && this.selectedTagIds.length === 0) {
            this.contactListTagData = [];
        }
    }

    tagSelected(event) {
        this.selectedTagIds = event.detail.selectedIds || [];
    }

    handleAddToList() {
        this.isShowAddToListModal = true;
    }

    handleCloseModal() {
        this.isShowAddToListModal = false;
        setTimeout(() => {
            this.handleClear();
        }, 500);
    }

    handleCloseNewModal() {
        this.isShowNewModal = false;
        setTimeout(() => {
            this.handleClear();
        }, 500);
    }

    handleShowNewModal() {
        this.isShowNewModal = true;
        this.isShowAddToListModal = false;
    }

    handleOrderedListChange(event) {
        var tempSelectedLists = event.detail.value;
        this.listValues = tempSelectedLists;   
        this.getUpdatedData();
    }

    handleRemoveDuplicates(event) {
        this.removeDuplicates = event.target.checked;
        this.getUpdatedData();
    }

    getUpdatedData() {
        this.isLoading = true;
        getUpdatedData({
            dataWrapperJSON : JSON.stringify(this.contactListTagData), 
            orderedList : this.listValues, 
            isRemoveDuplicates : this.removeDuplicates
        }).then((data) => {
            let tempConList = []; 
            let tempContactIds = [];
            data.forEach((record) => {
                let tempConRec = Object.assign({}, record);  
                tempConRec.lastNameURL = '/' + tempConRec.id;
                tempConList.push(tempConRec);
                tempContactIds.push(tempConRec.id)
            });                        
            this.contactListTagData = tempConList;
            this.contactIds = tempContactIds;
            this.contactListTagData.sort((a, b) => {
                if(a.lastName > b.lastName) return 1;
                if(a.lastName < b.lastName) return -1;
                return 0;
            });
            this.updatePaginatedData();
            this.isLoading = false;
        }).catch((error) => {
            this.isLoading = false;
            console.log('getUpdatedData error: ' + JSON.stringify(error));
        });
    }

    showToast(title, message, variant, mode) {

        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }

    updatePaginatedData() {
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = this.currentPage * this.pageSize;
        this.showTable = false;
        this.paginatedData = this.contactListTagData.slice(startIndex, endIndex);
        setTimeout(() => { this.showTable = true; }, 0);
    }

    handleDeleteSavedSearch() {
        if (!this.selectedSavedSearchId) {
            return;
        }
        this.showDeleteModal = true;
    }

    cancelDelete() {
        this.showDeleteModal = false;
    }

    confirmDelete() {
        this.showDeleteModal = false;
        this.isLoading = true;

        deleteSearch({ searchId: this.selectedSavedSearchId })
            .then(() => {
                this.selectedSavedSearchId = null;
                this.selectedSavedSearch = null;
                this.disableDeleteButton = true;
                this.loadSavedSearches();
                this.showToast('Saved Search Deleted', 'The saved search was successfully deleted.', 'success', 'dismissible');
            })
            .catch(error => {
                this.showToast('Error Deleting Saved Search', error.body.message, 'error', 'sticky');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}