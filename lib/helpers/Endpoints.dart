class Endpoints {
  static const String baseUrl = 'https://gwcl.afrifanom.com';
  //static const String baseUrl = 'http://192.168.0.134/8090';
  // if you are android studio emulator, change localhost to 10.0.2.2
  // http://192.168.100.4/gwcl
  // https://gwcl.afrifanom.com https://gwclmaster.afrifanom.com

  static const String public = baseUrl + '/';

  static const String api = baseUrl + '/api/';

  static const String login = api + 'auth/login';
  static const String register = api + 'auth/register';
  static const String send_otp_code = api + 'auth/send_otp_code';
  static const String verify_phone_number = api + 'auth/verify_phone_number';
  // App Info
  static const String app_info_view = api + 'app_info/view/{id}';
  // App Downloads
  static const String app_downloads_add = api + 'app_downloads/add';
  // Meters
  static const String meters = api + 'meters/index';
  static const String meters_edit = api + 'meters/edit/{id}';
  static const String meters_edit_email_address = api + 'meters/edit_email_address/{id}';
  static const String meters_edit_secondary_phone_number = api + 'meters/edit_secondary_phone_number/{id}';
  static const String meters_edit_meter_alias = api + 'meters/edit_meter_alias/{id}';
  static const String meters_view = api + 'meters/view/{id}';
  static const String meters_refresh = api + 'meters/refresh/{id}';
  static const String meters_add = api + 'meters/add';
  static const String meters_verify_customer = api + 'meters/verify_customer';
  static const String meters_delete = api + 'meters/delete/{id}';
  static const String meters_get_customer_info = api + 'meters/get_customer_info';
  //static const String meters_get_current_bill = api + 'meters/get_current_bill/{id}';
  static const String meters_current_bill = api + 'meters/current_bill/{id}';
  // Report Request
  static const String report_requests = api + 'report_requests';
  static const String report_requests_view = api + 'report_requests/view/{id}';
  static const String report_requests_add = api + 'report_requests/add';
  static const String report_requests_delete = api + 'report_requests/delete/{id}';
  // Vendors
  static const String vendors = api + 'vendors/index';
  static const String vendors_view = api + 'vendors/view/{id}';
  static const String vendors_refresh = api + 'vendors/refresh/{id}';
  static const String vendors_add = api + 'vendors/add';
  static const String vendors_verify = api + 'vendors/verify';
  static const String vendors_delete = api + 'vendors/delete/{id}';
  // Chats
  static const String chats = api + 'chats';
  static const String chats_index = api + 'chats/index/{fieldName}/{fieldValue}';
  static const String chats_add = api + 'chats/add';
  static const String chats_edit = api + 'chats/edit/{id}';
  static const String chats_read = api + 'chats/read/{id}';
  // Complaints
  static const String complaints = api + 'complaints';
  static const String complaints_add = api + 'complaints/add';
  static const String complaints_edit = api + 'complaints/edit/{id}';
  static const String complaints_rating = api + 'complaints/rating/{id}';
  // Customer
  static const String customers_view = api + 'customers/view/{id}';
  static const String customers_edit = api + 'customers/edit/{id}';
  static const String customers_editemail = api + 'customers/editemail';
  static const String customers_editphonenumber = api + 'customers/editphonenumber';
  static const String customers_editgpgps = api + 'customers/editgpgps';
  // Account
  static const String account = api + 'account';
  static const String account_edit = api + 'account/edit';
  static const String account_change_password = api + 'account/change_password';
  static const String account_forgot_password = api + 'account/forgot_password';
  static const String account_reset_password = api + 'account/reset_password';
  // Notification
  static const String notifications = api + 'notifications';
  static const String notifications_add = api + 'notifications/add';
  static const String notifications_edit = api + 'notifications/edit/{id}';
  static const String notifications_read = api + 'notifications/read';
  static const String notifications_check_numbers = api + 'notifications/check_numbers';
  // Announcements
  static const String announcements = api + 'announcements';
  // Payment History
  static const String payment_history = api + 'payment_history';
  static const String payment_history_index = api + 'payment_history/index/{fieldName}/{fieldValue}';
  static const String payment_history_index_v2 = api + 'payment_history/index_v2/{fieldName}/{fieldValue}';
  static const String payment_history_view = api + 'payment_history/view/{id}';
  static const String payment_history_add = api + 'payment_history/add';
  static const String payment_history_add_others = api + 'payment_history/add_others';
  static const String payment_history_edit = api + 'payment_history/edit/{id}';
  static const String payment_history_add_debit_card = api + 'payment_history/add_debit_card_v2';
  static const String payment_history_verify_debit_card = api + 'payment_history/verify_debit_card';
  static const String payment_history_reset_debit_card_otp = api + 'payment_history/reset_debit_card_otp';
  static const String payment_history_vendor_topup = api + 'payment_history/vendor_topup';
  static const String payment_history_vendor_topup_debit_card = api + 'payment_history/vendor_topup_debit_card';

  // Gps Address
  static const String gps_get_digital_address = api + 'gps_address/get_digital_address';
  // Debit Cards
  static const String debit_cards_view = api + 'debit_cards/view/{id}';
  // Feedbacks
  static const String feedbacks = api + 'feedbacks';
  static const String feedbacks_add = api + 'feedbacks/add';
  // Feedbacks
  static const String feeds = api + 'feeds';
  static const String feeds_seen = api + 'feeds/seen';
  static const String feeds_check_numbers = api + 'feeds/check_numbers';
   // v3 Feedbacks
  static const String feeds_v3_bills = api + 'feeds/v3?type=bills';
  static const String feeds_v3_payments = api + 'feeds/v3?type=payments';
  // Auto Payments
  static const String auto_payments = api + 'auto_payments';
  static const String auto_payments_view = api + 'auto_payments/view/{id}';
  static const String auto_payments_add = api + 'auto_payments/add';
  static const String auto_payments_delete = api + 'auto_payments/delete/{valOne}/{valTwo}';
}
