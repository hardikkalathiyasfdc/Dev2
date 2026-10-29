public with sharing class ZkipsterCallOutInterface {

    public class GetGuestsResponse {
    	public Links links {get;set;}
    	public List<Data> data {get;set;}
    	public Meta meta {get;set;}
    }

    public class GetGuestResponse {
    	public Links links {get;set;}
    	public Data data {get;set;}
    }

    public class Links {
		public String next {get;set;}
		public String last {get;set;}
	}

	public class Data {
		public String type_Z {get;set;} // in json: type
		public String id {get;set;}
		public Attributes attributes {get;set;}
		public Relationships relationships {get;set;}
		public Links_Y links {get;set;}
	}

	public class Meta {
		public Integer total_records {get;set;} // in json: total-records
	}

	public class Links_Y {
		public String self {get;set;}
	}

	public class Relationships {
		public GuestList guest_list {get;set;} // in json: guest-list
		public CustomFieldInfo custom_fields {get;set;} // in json: custom-fields
	}

	public class ContactDetails {
		public String organization {get;set;}
		public String country_code {get;set;} // in json: country-code
		public String phone_number {get;set;} // in json: phone-number
		public String email {get;set;}
		public String salutation {get;set;}
	}

	public class Attributes {
		public String first_name {get;set;} // in json: first-name
		public String last_name {get;set;} // in json: last-name
		public ContactDetails contact_details {get;set;} // in json: contact-details
		public List<String> notification_emails {get;set;} // in json: notification-emails
		public List<NotificationPhone> notification_phone_numbers {get;set;} // in json: notification-phone-numbers
		public String note {get;set;}
		public Integer total_guests {get;set;} // in json: total-guests
		public Integer plus_ones_checked {get;set;} // in json: plus-ones-checked
		public Boolean main_guest_checked {get;set;} // in json: main-guest-checked
		public String checkin_date {get;set;} // in json: checkin-date
		public String status {get;set;}
		public SeatingMapDetails seating_map_details {get;set;} // in json: seating-map-details
		public String created_date_utc {get;set;} // in json: created-date-utc
		public String updated_date_utc {get;set;} // in json: updated-date-utc
		public ChangedBy changed_by {get;set;} // in json: changed-by
		public List<CustomFieldValues> custom_field_values {get;set;} // in json: custom-field-values
		public String qr_code_value {get;set;} // in json: qr-code-value
	}

	public class NotificationPhone {
		public String country_code {get;set;}
		public String phone {get;set;}
	}

	public class SeatingMapDetails {
		public String seating_color {get;set;} // in json: seating-color
		public String seating_color_rgb {get;set;} // in json: seating-color-rgb"
		public String table_label {get;set;} // in json: table-label
		public String seat_label {get;set;} // in json: seat-label
	}
	public class ChangedBy {
		public String username {get;set;}
		public String device_id {get;set;} // in json: device-id
	}

	public class CustomFieldValues {
		public Integer custom_field_id {get;set;} // in json: custom-field-id
		public String field_name {get;set;} // in json: field-name
		public String value {get;set;}
		public List<SelectedValues> selected_values {get;set;} // in json: selected-values
	}

	public class SelectedValues {
		public Integer option_id {get;set;} // in json: option-id
		public String color {get;set;}
		public String color_rgb {get;set;}
		public String value {get;set;}

	}

	public class GuestList {
		public Links_Z links {get;set;}
		public Data_Z data {get;set;}
	}

	public class CustomFieldInfo {
		public Links_Z links {get;set;}
		public List<Data_Z> data {get;set;}
	}

	public class Data_Z {
		public String type_Z {get;set;}
		public String id {get;set;}
	}

	public class Links_Z {
		public String self {get;set;}
		public String related {get;set;}
	}
}