import {LightningElement, api, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { copyToClipboard } from 'c/utils';
import getFoundationCode from '@salesforce/apex/IMProgramOverviewController.getFoundationCode';
const TOAST_HEADER = 'Exception Occured - Unexpected Failure';
//Columns for the Program overview Initiatives Data
//IM-251: Added new Col for differentiating the budgeted and amendment initiatives.
const COLUMNS = [
	{
		fieldName: 'initiativeNameUrl',
		wrapText: true,
		label: '',
		type: 'url',
		typeAttributes: {
			label: {
				fieldName: 'initiativeName',
			},
			target: '_blank',
		},
		cellAttributes: {
			class: {
				fieldName: 'colorClass',
			},
		},
	},
	{
		type: 'button-icon',
		wrapText: true,
		initialWidth: 30,
		label: '',
		typeAttributes: {
			iconName: {
				fieldName: 'iconName',
			},
			size: 'large',
			variant: 'bare',
		},
		cellAttributes: {
			class: {
				fieldName: 'colorClass',
			},
		},
	},
	{
		type: 'button-icon',
		wrapText: true,
		initialWidth: 30,
		label: '',
		typeAttributes: {
			iconName: {
				fieldName: 'foriengnCurrencyIcon',
			},
			size: 'large',
			variant: 'bare'
		},
		cellAttributes: {
			class: {
				fieldName: 'colorClass',
			},
		},
	},
	{
		type: 'button-icon',
		wrapText: true,
		initialWidth: 30,
		label: '',
		typeAttributes: {
			iconName: {
				fieldName: 'notInBgiveIcon',
			},
			size: 'large',
			variant: 'bare'
		},
		cellAttributes: {
			class: {
				fieldName: 'colorClass',
			},
		},
	},
	{
		type: 'currency',
		wrapText: true,
		fieldName: 'amountValue',
		label: 'Total Committed',
		initialWidth: 210,
		typeAttributes: {
			minimumFractionDigits: 0,
			maximumFractionDigits: 0
		},
		cellAttributes: {
			class: {
				fieldName: 'styleClass',
			},
			alignment: 'right',
		},
	},
	{
		type: 'text',
		wrapText: true,
		fieldName: 'yearRange',
		label: 'Year Range',
		initialWidth: 160,
		cellAttributes: {
			class: {
				fieldName: 'styleClass',
			},
			alignment: 'right',
		},
	},
	{
		type: 'text',
		wrapText: true,
		fieldName: 'programOverviewAlert',
		label: 'Alert Message',
		initialWidth: 400,
		cellAttributes: {
			class: {
				fieldName: 'alertClass',
			},
			alignment: 'left',
		},
	},
];
export default class ImInitiativesOverview extends LightningElement {
	//Variables
	@api treeGridData;
	gridColumns = COLUMNS;
	@track currentExpanded = [];
	isResultEmpty = false;
	noDataFound = 'There are no approved budgets for this initiative';
	@api baseUrl;

	/*
	Description: connectedCallback runs when the component is loaded to the DOM.
	Jira Story : IM-211
	*/
	async connectedCallback() {
		//Adjust data
		try {
			const decoratedTrees = [];
			const expanded = [];
			for (const tree of this.treeGridData) {
				const decoratedTree = await this.decorateData(tree);
				// IM-358: If the total amount value is 0, do not render the block for parent initiative
				// There will only be one element in decoratedTree as the totals rows are removed if they are zero
				if(decoratedTree.length == 1){
					continue;
				}
				let headerName;
				let initiativeId;
				decoratedTree.forEach((row) => {
					if(row.isDetailRow){
						//Get the initiative record from each list
						const initiativeGridData = row;
						//Specify the names of the expanded Rows
						expanded.push(initiativeGridData?.name);
						headerName = initiativeGridData?.initiativeName || 'Initiative name is missing';
						initiativeId = initiativeGridData?.name;
					}
				})
				decoratedTrees.push({
					header: headerName,
					initiativeId: initiativeId,
					isLinkCopied: false,
					data: decoratedTree,	
				});
			}
			this.currentExpanded = [...expanded];
			this.treeGridData = decoratedTrees;
			this.isResultEmpty = this.treeGridData.length === 0;
		} catch (error) {
			this.showErrorToast(' connectedCallback ' + error);
		}
	}

	/*
	Description: runs when the component is rendered fully.
	Jira Story : IM-211
	*/
	async decorateData(treeGridData) {
		try {
			const decorated = await Promise.all(
				treeGridData.map(async (item) => {
					//style classes
					let styleClass = '';
					let alertClass = '';
					let colorClass = '';
					//Rows Definition
					const isTotalRow = item.isTotalRow;
					// IM-543: Excluding total amount rows if the total amount is zero
					const isTotalZero = item.isTotalRow && item.amountValue == 0;
					const isEmptyRow =
						item.initiativeName === '' &&
						(item.amountValue === '' || item.amountValue == null) &&
						item.yearRange === '' &&
						(item.programOverviewAlert === '' || item.programOverviewAlert == null);
					//IM:251 - Skip the row where the amount and yearRange is empty, means it won't be rendered on UI
					const skipRow =
						(!item.isTotalRow &&
						!(item.initiativeName === '' && (item.amountValue === '' || item.amountValue == null) && item.yearRange === '') &&
						item.amountValue == 0 &&
						item.yearRange == ' - ') || isTotalZero;
					if (skipRow) {
						return null;
					}
					//Bold and Caps for Total Amount - Top Rows
					if (isTotalRow) {
						styleClass = 'slds-text-title_bold slds-text-title_caps';
					} else if (isEmptyRow) {
						//Empty rows styling
						styleClass = 'slds-theme_shade';
						colorClass = 'slds-theme_shade';
					}
					//Top Rows End and Data Rows Start here
					//IM-291: If Program Overview Alert is populated, highlight the text in color
					if (item.programOverviewAlert) {
						alertClass = 'slds-text-color_error';
					}
					const newItem = {
						...item,
						styleClass,
						colorClass,
						alertClass,
					};
					if (Array.isArray(item.children) && item.children.length > 0) {
						// Recursively decorate grandchildren first
						const decoratedChildNodes = await this.decorateData(item.children);
						// sort childrenNode yearRange ascending
						newItem._children = this.sortChildrenByYearAscending(decoratedChildNodes);
					}
					return newItem;
				})
			);
			return decorated.filter((item) => item != null);
		} catch (error) {
			this.showErrorToast(' decorateData' + error);
		}
	}

	/*
	Description: Show Error Toast Message when error occurs
	Jira Story : IM-211
	*/
	showErrorToast(displayMessage) {
		const errorEvt = new ShowToastEvent({
			title: TOAST_HEADER,
			message: displayMessage,
			variant: 'error',
			mode: 'dismissable',
		});
		this.dispatchEvent(errorEvt);
	}

	/*
	 * Description : Extracts the "start year" from a yearRange.
	 *               Examples:
	 *                 "2019-2025" → 2019
	 *                 "2023"      → 2023
	 *                 "-" or ""   → 9999 (always sorts to the bottom)
	 * Jira Story  : IM-378
	 */
	getStartYear(record) {
		const initiativeName = record?.initiativeName || '';
		// If initiativeName contains "Misc", sort key = 9999 (goes to bottom in ASC)
		if (initiativeName.toLowerCase().includes('misc')) {
			return 9999;
		}
		const yearRangeValue = record?.yearRange;
		const normalized = (yearRangeValue || '').trim();
		if (!normalized || normalized === '-') {
			return 9999;
		}
		const startYearPresent = normalized.match(/\d{4}/);
		return startYearPresent ? Number(startYearPresent[0]) : 9999;
	}

	/*
	 * Description : Sorts an array of records by the "yearRange" field in ascending order.
	 * Jira Story  : IM-378
	 */
	sortChildrenByYearAscending(records) {
		// Spread into a new array so the original is not mutated
		return [...records].sort((a, b) => this.getStartYear(a) - this.getStartYear(b));
	}

	/*
	Description: Method to copy link to clipboard
	Jira Story : IM-556
	*/
	copyLink(event){
		let initiativeId = event.target.name;
		if(initiativeId){
			let copiedInitiative = this.treeGridData.find(tree => tree.initiativeId === initiativeId);
			if(copiedInitiative) {
				copiedInitiative.isLinkCopied = true;
			}
			this.treeGridData = [...this.treeGridData];
			setTimeout(() => {
				copiedInitiative.isLinkCopied = false;
				this.treeGridData = [...this.treeGridData];
			}, 3000);
			this.getFoundationCode(initiativeId);
		}		
	}

	/*
	Description: Method to get the Foundation code for the initiative and copy the link to clipboard
	Jira Story : IM-556
	*/
	async getFoundationCode(initiativeId) {
		try {
			if (initiativeId != null) {
				let foundationCodeId = await getFoundationCode({initiativeId: initiativeId});
				let msg;
				if(foundationCodeId){
					msg = this.baseUrl + '?c__recordId=' + foundationCodeId;
				}else{
					msg = this.baseUrl;
				}
				copyToClipboard(msg);
			} 
		} catch (error) {
			this.showSpinner = false;
			this.showErrorToast('Error' + error);
		}
	}
}