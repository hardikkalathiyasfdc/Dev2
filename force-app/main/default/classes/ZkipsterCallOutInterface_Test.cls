@isTest
private class ZkipsterCallOutInterface_Test {

    @isTest
    static void testInterface() {
        ZkipsterCallOutInterface.Links_Z link1 = new ZkipsterCallOutInterface.Links_Z();
        link1.self = 'test';
        link1.related = 'guest list';

        ZkipsterCallOutInterface.Data_Z type1 = new ZkipsterCallOutInterface.Data_Z();
        type1.type_Z = 'test type';
        type1.id = 'test id';

        ZkipsterCallOutInterface.CustomFieldInfo customInfo = new ZkipsterCallOutInterface.CustomFieldInfo();
        customInfo.links = link1;
        customInfo.data = new List<ZkipsterCallOutInterface.Data_Z>{type1};

        ZkipsterCallOutInterface.GuestList guestList = new ZkipsterCallOutInterface.GuestList();
        guestList.links = link1;
        guestList.data = type1;

        ZkipsterCallOutInterface.SelectedValues selectedValues = new ZkipsterCallOutInterface.SelectedValues();
        selectedValues.option_id = 1232;
        selectedValues.color = 'red';
        selectedValues.color_rgb = '#FFFFFF';
        selectedValues.value = 'true';

        ZkipsterCallOutInterface.CustomFieldValues customFields = new ZkipsterCallOutInterface.CustomFieldValues();
        customFields.custom_field_id = 1232;
        customFields.field_name = 'Test Field';
        customFields.value = 'yes';
        customFields.selected_values = new List<ZkipsterCallOutInterface.SelectedValues>{selectedValues};

        ZkipsterCallOutInterface.ChangedBy changedBy = new ZkipsterCallOutInterface.ChangedBy();
        changedBy.username = 'test username';
        changedBy.device_id = 'test device id';

        ZkipsterCallOutInterface.SeatingMapDetails seatingMap = new ZkipsterCallOutInterface.SeatingMapDetails();
        seatingMap.seating_color = 'red';
        seatingMap.seating_color_rgb = '23au23';
        seatingMap.table_label = 'main table';
        seatingMap.seat_label = '123';

        ZkipsterCallOutInterface.NotificationPhone notificationPhone = new ZkipsterCallOutInterface.NotificationPhone();
        notificationPhone.country_code = '1';
        notificationPhone.phone = '12343654';

        ZkipsterCallOutInterface.ContactDetails details = new ZkipsterCallOutInterface.ContactDetails();
        details.organization = 'test org';
        details.country_code = '1';
        details.phone_number = '12323212';
        details.email = 'test@test.com';

        ZkipsterCallOutInterface.Attributes attibues = new ZkipsterCallOutInterface.Attributes();
        attibues.first_name = 'firstname';
        attibues.last_name = 'lastname';
        attibues.contact_details = details;
        attibues.notification_emails = new List<String>{'test@test1.com'};
        attibues.notification_phone_numbers = new List<ZkipsterCallOutInterface.NotificationPhone>{notificationPhone};
        attibues.note = 'test notes';
        attibues.total_guests = 12;
        attibues.plus_ones_checked = 12;
        attibues.main_guest_checked = false;
        attibues.checkin_date = '2020-12-02';
        attibues.status = 'Comfirmed';
        attibues.seating_map_details = seatingMap;
        attibues.created_date_utc = '2020-12-02';
        attibues.updated_date_utc = '2020-12-02';
        attibues.changed_by = changedBy;
        attibues.custom_field_values = new List<ZkipsterCallOutInterface.CustomFieldValues>{customFields};
        attibues.qr_code_value = 'qr codes';

        ZkipsterCallOutInterface.Relationships ships = new ZkipsterCallOutInterface.Relationships();
        ships.guest_list = guestList;
        ships.custom_fields = customInfo;

        ZkipsterCallOutInterface.Links_Y links = new ZkipsterCallOutInterface.Links_Y();
        links.self = 'test self';

        ZkipsterCallOutInterface.Meta meta = new ZkipsterCallOutInterface.Meta();
        meta.total_records = 123;

        ZkipsterCallOutInterface.Data data1 = new ZkipsterCallOutInterface.Data();
        data1.type_Z = 'test type';
        data1.id = '1232';
        data1.attributes = attibues;
        data1.relationships = ships;
        data1.links = links;

        ZkipsterCallOutInterface.Links link = new ZkipsterCallOutInterface.Links();
        link.next = 'test next';
        link.last = 'test last';

        ZkipsterCallOutInterface.GetGuestResponse response = new ZkipsterCallOutInterface.GetGuestResponse();
        response.links = link;
        response.data = data1;

        ZkipsterCallOutInterface.GetGuestsResponse responses = new ZkipsterCallOutInterface.GetGuestsResponse();
        responses.links = link;
        responses.data = new List<ZkipsterCallOutInterface.Data>{data1};
        responses.meta = meta;
    }
}