import {LightningElement, api, track} from 'lwc';
const COLUMNS = [
	{
		label: 'Announcement',
		fieldName: 'announcementNameUrl',
		type: 'url',
		typeAttributes: {
			label: {
				fieldName: 'announcementName',
			},
			target: '_blank',
		},
		sortable: true,
		hideDefaultActions: true,
	},
	{
		label: 'Date',
		fieldName: 'announcementDate',
		type: 'date',
		sortable: true,
		initialWidth: 150,
		hideDefaultActions: true,
	},
	{
		label: 'Initiative Name',
		fieldName: 'nameUrl',
		type: 'url',
		typeAttributes: {
			label: {
				fieldName: 'initiativeName',
			},
			target: '_blank',
		},
		sortable: true,
		hideDefaultActions: true,
	},
	{
		label: 'Notes',
		fieldName: 'notes',
		wrapText: true,
		type: 'text',
		sortable: true,
		hideDefaultActions: true,
	},
];
export default class ImCommsOverview extends LightningElement {
	//Variables
	sortBy;
	sortDirection;
	//Columns in DataTable
	@track columns = COLUMNS;
	//Data in Datatable
	@api announcementRows;

	/*
    Description: runs when the DOM Loads
    Jira Story : IM-242 
    */
	connectedCallback() {
		this.makeInitiativeHyperlink();
	}

	/*
    Description: makes the initiative name hyperlink
    Jira Story : IM-242
    */
	makeInitiativeHyperlink() {
		try {
			if (this.announcementRows) {
				this.announcementRows = this.announcementRows.map((record) => {
					return {
						...record,
						announcementNameUrl: `/${record.id}`,
						announcementName: record.announcementName || null,
						nameUrl: `/${record.initiativeId}`,
						initiativeName: record.initiativeName || null,
					};
				});
			}
		} catch (error) {
			console.log('Error occured in the makeInitiativeHyperlink function ' + error);
		}
	}

	/*
    Description: handles the sorting of data onSort event
    Jira Story : IM-211
    */
	handleSort(event) {
		this.sortBy = event.detail.fieldName;
		this.sortDirection = event.detail.sortDirection;
		this.sortData(this.sortBy, this.sortDirection);
	}

	/*
    Description: Helper function to sort data
    Jira Story : IM-211
    */
	sortData(fieldname, direction) {
		let parseData = JSON.parse(JSON.stringify(this.data));
		let keyValue = (a) => {
			return a[fieldname];
		};
		let isReverse = direction === 'asc' ? 1 : -1;
		// sorting data
		parseData.sort((x, y) => {
			x = keyValue(x) ? keyValue(x) : '';
			y = keyValue(y) ? keyValue(y) : '';
			return isReverse * ((x > y) - (y > x));
		});
		this.data = parseData;
	}
}