import LightningDatatable from "lightning/datatable";
import DatatablePicklistTemplate from "./inlineDataTable.html";
import htmlTemplate from "./inlineDataTableHtml.html";
import lookupTemplate from "./inlineDataTableLookup.html";
import dateTemplate from "./inlineDataTableDate.html";
import checkboxTemplate from "./inlineDataTableCheckbox.html";
import iconTemplate from "./inlineDataTableIcon.html";
import emailStatusTemplate from "./inlineDataTableEmailStatus.html";
import additionalEmailLookupTemplate from "./inlineDataTableAdditionalEmailLookup.html";

export default class InlineDataTable extends LightningDatatable {
	static customTypes = {
		picklist: {
			template: DatatablePicklistTemplate,
			typeAttributes: [
				"label",
				"placeholder",
				"options",
				"value",
				"context",
				"field",
				"showNone"
			]
		},
		html: {
			template: htmlTemplate,
			typeAttributes: ["value"]
		},
		lookup: {
			template: lookupTemplate,
			typeAttributes: [
				"value", 
				"objectName", 
				"fieldName", 
				"context", 
				"isHide"
			]
		},
		date: {
			template: dateTemplate,
			typeAttributes: [
				"value",
				"objectName",
				"fieldName",
				"context",
				"fieldType"
			]
		},
		datetime: {
			template: dateTemplate,
			typeAttributes: [
				"value",
				"objectName",
				"fieldName",
				"context",
				"fieldType"
			]
		},
		checkbox: {
			template: checkboxTemplate,
			typeAttributes: ["value", "context", "fieldName","editable"]
		},
		customIcon: {
			template: iconTemplate,
			typeAttributes: ["value", "emailMap"]
		},
		emailStatus: {
			template: emailStatusTemplate,
			typeAttributes: ["value"]
		},
		additionalEmailLookup: {
			template: additionalEmailLookupTemplate,
			typeAttributes: [
				"value",
				"context",
				"fieldName"
			]
		}
	};
}