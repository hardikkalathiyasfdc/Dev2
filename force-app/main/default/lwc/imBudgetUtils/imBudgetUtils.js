import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {NavigationMixin} from 'lightning/navigation';
import {CloseActionScreenEvent} from 'lightning/actions';
export const CONSTANTS = {
    PARTNER: 'Partner__c',
    UNIQUE_IDENTIFIER: 'Unique_Identifier__c',
    BUDGET_PARAM_TAB: 'Budget Parameters',
    BUDGET_TAB: 'Budget',
    SYSTEM_TAB: 'System',
    RELATIONSHIP_FIELD: '__r',
    REDIRECT_OBJECT: 'IM_Budget__c',
    IS_LOCKED: 'Is_Locked__c',
    BIM_ROW_ID: 'Id'
};

// Error messages
export const ERROR_MESSAGES = {
    NO_DATA: 'No Data Returned from Apex',
    LOAD_TEMP_ERROR: 'Error while loading the template fetched from static resource : ',
    NOT_FOUND: ' Worksheet not found in Template',
    HIDE_COLS_ERROR: 'Error while performing data manipulation in hiding columns for ',
    WRITE_ROWS_ERROR: 'Error while performing data manipulation in writing rows for ',
    EXCEL_BUFFER_ERROR: 'Failed to generate Excel File Buffer',
    DOWNLOAD_ERROR: 'Error processing the download of Budget : ',
    UPDATE_FAILED_ERROR: 'Updating Budget Checkout fields failed',
    CHECKOUT_BUDGET_ERROR: 'Budget has been already checked out by ',
    NOT_ALLOWED: 'You do not have the permission to perform this action.'
};


export const TOAST_HEADERS = {
    CHECKOUT_FAIL_HEADER: 'Checkout Failed!',
    DOWNLOAD_FAIL_HEADER: 'Download Failed!'
};

/*Generic mehod called on connectedcallback after excel.js is loaded*/
export function initializeExcelLibrary(component, onExcelLoaded) {
    component.showSpinner = true;
    component.excelStaticResourceLoaded = true;
    if (component.excelStaticResourceLoaded && component.apexDataReceived) {
        onExcelLoaded();
    }
}

/*Method to call Budget Template after Budget data is loaded*/
export function checkReadyState(component, onReady) {
    if (component.excelStaticResourceLoaded && component.apexDataReceived) {
        onReady();
    }
}

/*Set Budget data properties*/
function setBudgetDataProperties(component, budgetWrapperData) {
    component.budgetTerm = budgetWrapperData.budgetRec.Budget_Term_Years__c;
    component.initiativeId = budgetWrapperData.budgetRec.Initiative__c;
    component.fileName = budgetWrapperData.budgetRec.Name + '.xlsx';
    component.isPostApprovalCheckout = budgetWrapperData.isBudgetApproved;
    component.apexDataReceived = true;
    component.budgetWrapperData = budgetWrapperData;
}

/*Get Budget data*/
export async function getBudgetDataUtil(component, recordId, getBudgetDataApex, onSuccess, onError) {
    try {
        const budgetWrapperData = await getBudgetDataApex({ budgetId: recordId });
        if (budgetWrapperData) {
            setBudgetDataProperties(component, budgetWrapperData);
            onSuccess();
        } else {
            component.showSpinner = false;
            onError(ERROR_MESSAGES.NO_DATA);
        }
    } catch (error) {
        component.showSpinner = false;
        onError(ERROR_MESSAGES.NO_DATA);
    }
}

/*Get Budget data and checkout validation*/
export async function getBudgetDataWithCheckout(component, recordId, getBudgetDataApex, getCheckoutInfoApex, onSuccess, onError, onCheckoutError) {
    try {
        const checkoutBy = await getCheckoutInfoApex({ budgetId: recordId });
        if (checkoutBy !== '') {
            onCheckoutError(ERROR_MESSAGES.CHECKOUT_BUDGET_ERROR + checkoutBy);
            component.showSpinner = false;
        } else {
            const budgetWrapperData = await getBudgetDataApex({ budgetId: recordId });
            if (budgetWrapperData) {
                setBudgetDataProperties(component, budgetWrapperData);
                onSuccess();
            } else {
                component.showSpinner = false;
                onError(ERROR_MESSAGES.NO_DATA);
            }
        }
    } catch (error) {
        component.showSpinner = false;
        onError(ERROR_MESSAGES.NO_DATA);
    }
}

/**
 * Description: Decode Budget Template recieved from Apex and convert it to Blob
 * Jira Story : IM-50
 */
export function getTemplateContent(budgetTemplate) {
    const templateMetadata = JSON.parse(budgetTemplate.metadata);
    const base64Data = budgetTemplate.template;
    const binaryData = atob(base64Data);
    const byteArray = new Uint8Array(binaryData.length);
    
    for (let i = 0; i < binaryData.length; i++) {
        byteArray[i] = binaryData.charCodeAt(i);
    }
    
    const blob = new Blob([byteArray], { 
        type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' 
    });
    
    return {
        templateMetadata,
        blob
    };
}

/**
 * Description: Load the template file fetched from Files into excelJS workbook instance
 * Jira Story : IM-50
 */
export async function loadTemplate(response, onLoadCallback) {
    try {
        const reader = new FileReader();
        reader.onload = async () => {
            const arrayBuffer = reader.result;
            const ExcelJS = window.ExcelJS;
            const workbook = new ExcelJS.Workbook();
            await workbook.xlsx.load(arrayBuffer);
            onLoadCallback(workbook);
        };
        reader.readAsArrayBuffer(response);
    } catch (error) {
        throw new Error(ERROR_MESSAGES.LOAD_TEMP_ERROR + error);
    }
}

/**
 * Description: Once the template is loaded, this function performs the Budget Parameters excel data manipulations.
 * Jira Story : IM-50
 */
export function setSystemSheet(workbook, recordId) {
    try {
        let systemSheet = workbook.getWorksheet(CONSTANTS.SYSTEM_TAB);
        systemSheet.state = 'veryHidden';
        let dataRow = systemSheet.getRow(1);
        dataRow.getCell(2).value = 'BP' + recordId;
        const lockCellFill = systemSheet.getRow(2).getCell(2).style.fill;
        return lockCellFill;
    } catch (error) {
        throw new Error(CONSTANTS.SYSTEM_TAB + ' : ' + error);
    }
}

/**
 * Description: Performs hidecolumns logic for budget parameters tab.
 * Jira Story : IM-50
 */
export function hideBudgetParamCols(budgetParamsWksht, paramColumnMapping, budgetRec) {
    try {
        Object.keys(paramColumnMapping).forEach((columnKey) => {
            let columnMetadata = paramColumnMapping[columnKey];
            if (columnMetadata) {
                let dataColumnIndex = columnMetadata.dataColumnIndex;
                let dataColumn = budgetParamsWksht.getColumn(dataColumnIndex);
                dataColumn.hidden = !budgetRec[columnKey];
                
                let totalColumnIndex = columnMetadata.totalColumnIndex;
                let totalColumn = budgetParamsWksht.getColumn(totalColumnIndex);
                totalColumn.hidden = !budgetRec[columnKey];
            }
        });
    } catch (error) {
        throw new Error(ERROR_MESSAGES.HIDE_COLS_ERROR + CONSTANTS.BUDGET_PARAM_TAB + ' : ' + error);
    }
}

/**
 * Description: Once the template is loaded, this function performs the Budget Parameters excel data manipulations-write rows.
 * Jira Story : IM-50
 */
export function setBudgetParamsData(budgetParamsWksht, budgetParamData, paramColumnMapping, templateMetadata) {
    try {
        if (budgetParamData) {
            let dataRowStartIndex = templateMetadata.BudgetParameters.DataRowStartIndex;
            let paramDataRowIndex = templateMetadata.BudgetParameters.DataRowStartIndex + 1;
            
            Object.keys(budgetParamData).forEach((key) => {
                if (budgetParamData[key]) {
                    let paramData = budgetParamData[key].filter((record, index, self) =>
                        index === self.findIndex((t) => (t.Name === record.Name))
                    );
                    let columnMetadata = paramColumnMapping[key];
                    let columnIndex = columnMetadata.dataColumnIndex;
                    let firstRow = budgetParamsWksht.getRow(dataRowStartIndex);
                    let firstColumnValue = firstRow.getCell(columnIndex).value;
                    
                    if (firstColumnValue) {
                        paramData = paramData.filter((record) => 
                            record.Name != firstColumnValue && record?.Organization__r?.Name != firstColumnValue
                        );
                    }

                    paramData.forEach((record, index) => {
                        const rowIndex = index + paramDataRowIndex;
                        const row = budgetParamsWksht.getRow(rowIndex);
                        let cell = row.getCell(columnIndex);
                        let isPartnerColumn = ['Partner__c', 'Sub_Partner__c', 'Payee_Fiscal_Sponsor__c'].includes(key);
                        
                        if (isPartnerColumn && record?.Organization__r?.Name != firstColumnValue) {
                            cell.value = record?.Organization__r?.Name || '';
                        } else if (!isPartnerColumn && record.Name != firstColumnValue) {
                            cell.value = record.Name || '';
                        }
                    });
                }
            });
        }
    } catch (error) {
        throw new Error(ERROR_MESSAGES.WRITE_ROWS_ERROR + CONSTANTS.BUDGET_PARAM_TAB + ' : ' + error);
    }
}

/**
 * Description: Performs worksheet protection.
 * Jira Story : IM-50
 */
export function protect(worksheet, initiativeId) {
    worksheet.protect(initiativeId, {
        selectLockedCells: true,
        selectUnlockedCells: true,
        formatCells: false,
        formatColumns: false,
        formatRows: false,
        insertColumns: false,
        insertRows: false,
        deleteColumns: false,
        deleteRows: false,
        sort: true,
        insertHyperlinks: false,
        autoFilter: true,
        pivotTables: false,
        spinCount: 100000,
    });
}

/**
 * Description: Performs hide columns logic for budget tab.
 * Jira Story : IM-50
 */
export function hideBudgetCols(budgetWorksheet, budgetColumnMapping, periodColumnMapping, budgetRec, budgetTerm) {
    try {
        // Hide other columns
        Object.keys(budgetColumnMapping).forEach((columnKey) => {
            if (budgetColumnMapping[columnKey]) {
                let columnIndex = budgetColumnMapping[columnKey]?.columnIndex;
                let col = budgetWorksheet.getColumn(columnIndex);
                if (columnKey in budgetRec) {
                    col.hidden = !budgetRec[columnKey];
                }
            }
            // Always hide Is Locked row column as it is only for internal use and should not be shown in excel
            if (columnKey === CONSTANTS.IS_LOCKED || columnKey === CONSTANTS.BIM_ROW_ID) {
                let columnIndex = budgetColumnMapping[columnKey]?.columnIndex;
                let col = budgetWorksheet.getColumn(columnIndex);
                col.hidden = true;
            }
        });
        
        // Hide year columns
        Object.keys(periodColumnMapping).forEach((columnKey) => {
            let columnIndex = periodColumnMapping[columnKey]?.columnIndex;
            let col = budgetWorksheet.getColumn(columnIndex);
            if (columnKey.includes('Period_')) {
                let periodNumber = parseInt(columnKey.split('_')[1]);
                if (periodNumber > budgetTerm) {
                    col.hidden = true;
                }
            }
        });
    } catch (error) {
        throw new Error(ERROR_MESSAGES.HIDE_COLS_ERROR + CONSTANTS.BUDGET_TAB + ' : ' + error);
    }
}

/*
Description: Handles setting the year column labels
Jira Story : IM-50
*/
export function setYearColumnLabels(budgetWorksheet, periods, periodColumnMapping, templateMetadata) {
    let headerIndex = templateMetadata.Budget.SecondaryHeaderRowIndex;
    const row = budgetWorksheet.getRow(headerIndex);
    periods.forEach((record, index) => {
        let key = 'Period_' + record.Period__c + '_Amount__c';
        let columnIndex = periodColumnMapping[key]?.columnIndex;
        row.getCell(columnIndex).value = record.Period_Label__c || '';
    });
}

/**
 * Description: Once the template is loaded, this function performs the Budget excel data manipulations-Write Rows.
 * Jira Story : IM-50
 */
export function setBudgetData(budgetWorksheet, budgetRowList, budgetColumnMapping, periodColumnMapping, skipObj, templateMetadata, isPostApprovalCheckout, lockCellFill) {
    try {
        budgetRowList.forEach((record, index) => {
            const rowIndex = index + templateMetadata.Budget.DataRowStartIndex;
            let row = budgetWorksheet.getRow(rowIndex);

            Object.keys(budgetColumnMapping).forEach((columnKey) => {

                // IM-545: Moved this condition out of loop since cells will be locked for partner and unique identifier after approval for existing rows
                let columnIndex = budgetColumnMapping[columnKey]?.columnIndex;
                let cell = row.getCell(columnIndex);
                
                // Lock cells if it is a post approval checkout
                if (isPostApprovalCheckout) {
                    if (columnKey === CONSTANTS.UNIQUE_IDENTIFIER || 
                        columnKey === CONSTANTS.PARTNER) {
                            applyCellLock(cell, lockCellFill);
                    }
                }

                if(!isPostApprovalCheckout && columnKey === CONSTANTS.IS_LOCKED) {
                    let isLockedRow = record[CONSTANTS.IS_LOCKED];
                    if(isLockedRow) {
                        let identifierIndex = budgetColumnMapping[CONSTANTS.UNIQUE_IDENTIFIER]?.columnIndex;
                        let identifierCell = row.getCell(identifierIndex);
                        applyCellLock(identifierCell, lockCellFill);
                        let partnerIndex = budgetColumnMapping[CONSTANTS.PARTNER]?.columnIndex;
                        let partnerCell = row.getCell(partnerIndex);
                        applyCellLock(partnerCell, lockCellFill);
                    }
                }

                if (columnKey in record && !(columnKey in skipObj)) {
                    let relationKey = columnKey.slice(0, -3) + CONSTANTS.RELATIONSHIP_FIELD;
                    if (record[relationKey]) {
                        if (['Partner__c', 'Payee_Fiscal_Sponsor__c', 'Sub_Partner__c'].includes(columnKey)) {
                            cell.value = record[relationKey]?.Organization__r?.Name || '';
                        } else {
                            cell.value = record[relationKey].Name || '';
                        }
                    } else {
                        cell.value = record[columnKey] || '';
                    }
                }
            });
            
            Object.keys(periodColumnMapping).forEach((columnKey) => {
                if ((columnKey in record) && !(columnKey in skipObj)) {
                    let columnIndex = periodColumnMapping[columnKey]?.columnIndex;
                    row.getCell(columnIndex).value = record[columnKey] || 0;
                }
            });
        });
    } catch (error) {
        throw new Error(ERROR_MESSAGES.WRITE_ROWS_ERROR + CONSTANTS.BUDGET_TAB + ' : ' + error);
    }
}

/**
 * Description: applies cell level validation to lock
 * Jira Story : IM-50
 */
export function applyCellLock(cell, lockCellFill) {
    // shallow-clone the style, break references
    cell.style = Object.create(cell.style);
    cell.style.fill = lockCellFill;
    cell.style.protection = {locked: true};
}

export async function downloadWorkbook(workbook, fileName) {
    try {
        const buffer = await workbook.xlsx.writeBuffer();
        if (!buffer || buffer.bytelength === 0) {
            throw new Error(ERROR_MESSAGES.EXCEL_BUFFER_ERROR);
        }
        
        const blobFile = new Blob([buffer], { type: 'application/octet-stream' });
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blobFile);
        link.download = fileName;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        
        return true;
    } catch (error) {
        throw new Error(ERROR_MESSAGES.DOWNLOAD_ERROR + error);
    }
}

/*
Description: Show Error Toast Message when error occurs
Jira Story : IM-50
*/
export function showErrorToast(component, title, message) {
    const errorEvt = new ShowToastEvent({
        title: title,
        message: message,
        variant: 'error',
        mode: 'dismissable'
    });
    component.dispatchEvent(errorEvt);
}

/*
Description: handles the close action screen event
Jira Story : IM-50
*/
export function closeModal(component) {
    component.dispatchEvent(new CloseActionScreenEvent());
}

/*
Description: Navigates to the BudgetRecord Page once the file is downloaded successfully.
Jira Story : IM-50
*/
export function navigateToRecordPage(component, recordId) {
    component[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: recordId,
            objectApiName: CONSTANTS.REDIRECT_OBJECT,
            actionName: 'view'
        },
    });
}

/**
* Returns a new array of budget rows sorted by Partner, then UniqueId
*/
export function sortBudgetRowsByPartnerUniqueId(budgetRows) {
    if(!budgetRows || budgetRows.length === 0) {
        return budgetRows;
    }
    const rows = [...budgetRows];
    rows.sort((a, b) => {
        const pa = partnerDisplayForSort(a).toLowerCase();
        const pb = partnerDisplayForSort(b).toLowerCase();
        const partnerCompare = pa.localeCompare(pb);
        if(partnerCompare !== 0) {
            return partnerCompare;
        }
        const ua = (a?.Unique_Identifier__c != null && String(a.Unique_Identifier__c).trim()) || '';
        const ub = (b?.Unique_Identifier__c != null && String(b.Unique_Identifier__c).trim()) || '';
        return ua.toLowerCase().localeCompare(ub.toLowerCase());
    });
    return rows;
}

/**
* Partner string for sorting i.e. Org Name when present
*/
function partnerDisplayForSort(record) {
    const partnerRecord = record?.Partner__r;
    if(partnerRecord) {
        if(partnerRecord.Organization__r?.Name) {
            return String(partnerRecord.Organization__r.Name);
        }
        if(partnerRecord.Name) {
            return String(partnerRecord.Name);
        }
    }
    return '';
}