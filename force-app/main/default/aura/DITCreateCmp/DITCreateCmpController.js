({
    init: function (component, event, helper) {
        helper.columnMap = {
            First_Name__c: "FirstName",
            Last_Name__c: "LastName",
            Organization_Id__c: "AccountId",
            Title__c: "Title",
            Salutation__c: "Salutation",
            Middle_Name__c: "MiddleName",
            Suffix__c: "Suffix",
            Preferred_First_Name__c: "Preferred_First_Name__c",
            Business_Email__c: "Email",
            Personal_Email__c: "Alternate_Email__c",
            Additional_Email__c: "Business_Email_2__c",
            Personal_Email_2__c:"Personal_Email_2__c",
            Personal_Email_2__c: "Personal_Email_2__c",
            HomePhoneCountryCode__c: "HomePhoneCountryCode__c",
            HomePhone__c: "HomePhone",
            Mobile_Phone_Country_Code__c: "Mobile_Phone_Country_Code__c",
            Cell__c: "MobilePhone",
            AdditionalPhoneCountryCode__c: "AdditionalPhoneCountryCode__c",
            AdditionalPhone__c: "AdditionalPhone__c",
            Business_Phone__c: "Phone",
            Business_Phone_Country_Code__c: "Office_Phone_Country_Code__c",
            Business_Street_1__c: "MailingStreet",
            Business_City__c: "MailingCity",
            Business_State__c: "MailingState",
            Business_Postal_Code__c: "MailingPostalCode",
            Business_Country__c: "MailingCountry",
            Home_Street_1__c: "OtherStreet",
            Home_City__c: "OtherCity",
            Home_State__c: "OtherState",
            Home_Postal_Code__c: "OtherPostalCode",
            Home_Country__c: "OtherCountry",
            Dietary__c:"Dietary__c",
            UUID__c:"UUID__c",
            Preferred_Last_Name__c:"Preferred_Last_Name__c"
        };

        // Declare the array for columns
        helper.columns = [
            {label: 'Salutation', fieldName:'Salutation' , initialWidth: 150 },
            {label: 'First Name', fieldName:'FirstName' , initialWidth: 150 },
            {label: 'Middle Name', fieldName:'MiddleName' , initialWidth: 150 },
            {label: 'Last Name', fieldName:'LastName' , initialWidth: 150 },
            {label: 'Suffix', fieldName:'Suffix' , initialWidth: 150 },
            {label: 'Preferred First Name', fieldName:'Preferred_First_Name__c' , initialWidth: 150 },
            {label: 'Title', fieldName:'Title' , initialWidth: 150 },
            {label: 'Organization', fieldName:'Advance_Field_Notes__c' , initialWidth: 150 },
            {label: 'Business Email', fieldName:'Email' , initialWidth: 150 },
            {label: 'Personal Email', fieldName:'Alternate_Email__c' , initialWidth: 150 },
            {label: 'Additional Email', fieldName:'Business_Email_2__c' , initialWidth: 150 },
            {label: 'Confidential Email', fieldName:'Personal_Email_2__c' , initialWidth: 150 },
            {label: 'Business Phone (Country Code)', fieldName:'Office_Phone_Country_Code__c' , initialWidth: 150 },
            {label: 'Business Phone', fieldName:'Phone' , initialWidth: 150 },
            {label: 'Mobile Phone (Country Code)', fieldName:'Mobile_Phone_Country_Code__c' , initialWidth: 150 },
            {label: 'Mobile Phone', fieldName:'MobilePhone' , initialWidth: 150 },
            {label: 'Home Phone (Country Code)', fieldName:'HomePhoneCountryCode__c' , initialWidth: 150 },
            {label: 'Home Phone', fieldName:'HomePhone' , initialWidth: 150 },
            {label: 'Additional Phone (Country Code)', fieldName:'AdditionalPhoneCountryCode__c' , initialWidth: 150 },
            {label: 'Additional Phone', fieldName:'AdditionalPhone__c' , initialWidth: 150 },
            {label: 'Business Street', fieldName:'MailingStreet' , initialWidth: 150 },
            {label: 'Business City', fieldName:'MailingCity' , initialWidth: 150 },
            {label: 'Business State/Province', fieldName:'MailingState' , initialWidth: 150 },
            {label: 'Business Zip/Postal Code', fieldName:'MailingPostalCode' , initialWidth: 150 },
            {label: 'Business Country', fieldName:'MailingCountry' , initialWidth: 150 },
            {label: 'Home Street', fieldName:'OtherStreet' , initialWidth: 150 },
            {label: 'Home City', fieldName:'OtherCity' , initialWidth: 150 },
            {label: 'Home State/Province', fieldName:'OtherState' , initialWidth: 150 },
            {label: 'Home Zip/Postal Code', fieldName:'OtherPostalCode' , initialWidth: 150 },
            {label: 'Home Country', fieldName:'OtherCountry' , initialWidth: 150 },
            {label: 'UUID', fieldName:'UUID__c' , initialWidth: 150 },
            {label: 'Preferred Last Name', fieldName:'Preferred_Last_Name__c' , initialWidth: 150 }
        ];

        // Continue with fetching the data
        helper.filterColumns(component,helper)
        helper.contactFetchData(component,event,helper);
    },
    handleSectionToggle: function (cmp, event) {
        var openSections = event.getParam('openSections');

        if (openSections.length === 0) {
            cmp.set('v.activeSectionsMessage', "All sections are closed");
        } else {
            cmp.set('v.activeSectionsMessage', "Open sections: " + openSections.join(', '));
        }
    },
    handleSectionToggle2: function (cmp, event) {
        var openSections = event.getParam('openSections');

        if (openSections.length === 0) {
            cmp.set('v.activeSectionsMessage2', "All sections are closed");
        } else {
            cmp.set('v.activeSectionsMessage2', "Open sections: " + openSections.join(', '));
        }
    },
    handleLookupChange : function(component, event) {
        var detail = JSON.parse(JSON.stringify(event.getParams()));
        var selectedRecords = detail.selectedRecords || [];
        var lists = selectedRecords.map(function(r) { return { Id: r.Id }; });
        component.set('v.selectedRecord', lists[0]);
    }
});