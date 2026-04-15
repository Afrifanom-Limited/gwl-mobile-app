import 'dart:async';
import 'dart:io' as io;
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/models/Chat.dart';
import 'package:gwcl/models/Complaint.dart';
import 'package:gwcl/models/Customer.dart';
import 'package:gwcl/models/Meter.dart';
import 'package:gwcl/models/Vendor.dart';
import 'package:gwcl/models/Notification.dart';
import 'package:gwcl/models/Payment.dart';
import 'package:gwcl/models/ReportRequest.dart';
import 'package:gwcl/models/SavedCard.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static final LocalDatabase _instance = new LocalDatabase.internal();
  factory LocalDatabase() => _instance;
  Database? _db;

  String _dbName = Constants.gwclDbName,
      _customer = "customer",
      _notifications = "notifications",
      _meters = "meters",
      _vendors = "vendors",
      _complaints = "complaints",
      _chats = "chats",
      _paymentHistory = "payment_history",
      _reportRequests = "report_requests",
      _savedCards = "saved_cards";

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }
    _db = await initDb();
    return _db!;
  }

  LocalDatabase.internal();

  initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);
    var theDb = await openDatabase(
      path,
      version: 11,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: onDatabaseDowngradeDelete,
    );
    return theDb;
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      // db.execute("ALTER TABLE $_meters ADD COLUMN newCol TEXT;");
      var batch = db.batch();
      _createTableCustomer(batch);
      _createTableComplaints(batch);
      _createTableMeters(batch);
      _createTableVendors(batch);
      _createTableChats(batch);
      _createTableNotifications(batch);
      _createTablePaymentHistory(batch);
      _createTableReportRequests(batch);
      _createTableSavedCards(batch);
      await batch.commit();
    }
  }

  void _onCreate(Database db, int version) async {
    var batch = db.batch();
    _createTableCustomer(batch);
    _createTableComplaints(batch);
    _createTableMeters(batch);
    _createTableVendors(batch);
    _createTableChats(batch);
    _createTableNotifications(batch);
    _createTablePaymentHistory(batch);
    _createTableReportRequests(batch);
    _createTableSavedCards(batch);
    await batch.commit();
  }

  // void _clearAndDeleteDatabase() async {
  //   io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
  //   String path = join(documentsDirectory.path, Constants.gwclDbName);
  //   await deleteDatabase(path);
  //   print('_______________database delete');
  // }

  // CUSTOMER CONTROLLERS
  Future<bool> isLoggedIn() async {
    var dbClient = await db;
    var res = await dbClient.query(this._customer);
    return res.length > 0 ? true : false;
  }

  Future<int> saveCustomer(Customer customer) async {
    int res;
    var dbClient = await db;
    var checkCustomer = await dbClient.query(this._customer);
    if (checkCustomer.length > 0) {
      res = await dbClient.update(this._customer, customer.toMap(),
          where: "customer_id=?", whereArgs: [customer.customerId]);
    } else {
      res = await dbClient.insert(this._customer, customer.toMap());
    }
    return res;
  }

  Future getCustomer() async {
    var dbClient = await db;
    var res = await dbClient.query(this._customer);
    return res.length > 0 ? res.first : Map<String, dynamic>();
  }

  Future<int> updateCustomer(Customer customer) async {
    var dbClient = await db;
    int res = await dbClient.update(this._customer, customer.toMap(),
        where: "customer_id=?", whereArgs: [customer.customerId]);
    return res;
  }

  Future<int> deleteCustomer() async {
    var dbClient = await db;
    int res = await dbClient.delete(this._customer);
    return res;
  }

  // COMPLAINT CONTROLLER
  Future<int> addComplaint(Complaint complaint) async {
    int res;
    var dbClient = await db;
    var checkComplaint = await dbClient.query(this._complaints,
        where: "complaint_id=?", whereArgs: [complaint.complaintId]);
    if (checkComplaint.length > 0) {
      res = await dbClient.update(this._complaints, complaint.toMap(),
          where: "complaint_id=?", whereArgs: [complaint.complaintId]);
    } else {
      res = await dbClient.insert(this._complaints, complaint.toMap());
    }
    return res;
  }

  Future<int> updateComplaint(Complaint complaint) async {
    var dbClient = await db;
    int res = await dbClient.update(this._complaints, complaint.toMap(),
        where: "complaint_id=?", whereArgs: [complaint.complaintId]);
    return res;
  }

  Future getComplaint(Complaint complaint) async {
    var dbClient = await db;
    var res = await dbClient.query(this._complaints,
        where: "complaint_id=?", whereArgs: [complaint.complaintId]);
    return res;
  }

  Future getComplaints() async {
    var dbClient = await db;
    var res =
        await dbClient.query(this._complaints, orderBy: "complaint_id DESC");
    return res.length > 0 ? res : List<dynamic>.empty(growable: true);
  }

  Future deleteComplaint(String complaintId) async {
    var dbClient = await db;
    int res = await dbClient.delete(this._complaints,
        where: "complaint_id=?", whereArgs: [complaintId]);
    return res;
  }

  Future<int> deleteComplaints() async {
    var dbClient = await db;
    int res = await dbClient.delete(this._complaints);
    return res;
  }

  // METER CONTROLLER
  Future<int> addMeter(Meter meter) async {
    int res;
    var dbClient = await db;
    var checkMeter = await dbClient
        .query(this._meters, where: "meter_id=?", whereArgs: [meter.meterId]);
    if (checkMeter.length > 0) {
      res = await dbClient.update(this._meters, meter.toMap(),
          where: "meter_id=?", whereArgs: [meter.meterId]);
    } else {
      res = await dbClient.insert(this._meters, meter.toMap());
    }
    return res;
  }

  Future<int> updateMeter(Meter meter) async {
    var dbClient = await db;
    int res = await dbClient.update(this._meters, meter.toMap(),
        where: "meter_id=?", whereArgs: [meter.meterId]);
    return res;
  }

  Future getMetersLimited() async {
    var dbClient = await db;
    var res = await dbClient.query(this._meters, orderBy: "meter_id DESC", limit: 10);
    return res.length > 0 ? res : List<dynamic>.empty(growable: true);
  }

  Future getMeters() async {
    var dbClient = await db;
    var res = await dbClient.query(this._meters, orderBy: "meter_id DESC");
    return res.length > 0 ? res : List<dynamic>.empty(growable: true);
  }

  Future viewMeter(String meterId) async {
    var dbClient = await db;
    var res = await dbClient
        .query(this._meters, where: "meter_id=?", whereArgs: [meterId]);
    return res.length > 0 ? res : null;
  }

  Future removeMeter(String meterId) async {
    var dbClient = await db;
    int res = await dbClient
        .delete(this._meters, where: "meter_id=?", whereArgs: [meterId]);
    return res;
  }

  Future<int> deleteAllMeter() async {
    var dbClient = await db;
    int res = await dbClient.delete(this._meters);
    return res;
  }

  // VENDOR CONTROLLER
  Future<int> addVendor(Vendor vendor) async {
    int res;
    var dbClient = await db;
    var checkVendor = await dbClient.query(this._vendors,
        where: "vendor_id=?", whereArgs: [vendor.vendorId]);
    if (checkVendor.length > 0) {
      res = await dbClient.update(this._vendors, vendor.toMap(),
          where: "vendor_id=?", whereArgs: [vendor.vendorId]);
    } else {
      res = await dbClient.insert(this._vendors, vendor.toMap());
    }
    return res;
  }

  Future<int> updateVendor(Vendor vendor) async {
    var dbClient = await db;
    int res = await dbClient.update(this._vendors, vendor.toMap(),
        where: "vendor_id=?", whereArgs: [vendor.vendorId]);
    return res;
  }

  Future getVendors() async {
    var dbClient = await db;
    var res = await dbClient.query(this._vendors, orderBy: "vendor_id DESC");
    return res.length > 0 ? res : List<dynamic>.empty(growable: true);
  }

  Future viewVendor(String vendorId) async {
    var dbClient = await db;
    var res = await dbClient
        .query(this._vendors, where: "vendor_id=?", whereArgs: [vendorId]);
    return res.length > 0 ? res : null;
  }

  Future removeVendor(String vendorId) async {
    var dbClient = await db;
    int res = await dbClient
        .delete(this._vendors, where: "vendor_id=?", whereArgs: [vendorId]);
    return res;
  }

  Future<int> deleteAllVendors() async {
    var dbClient = await db;
    int res = await dbClient.delete(this._vendors);
    return res;
  }

  // CHAT CONTROLLERS
  Future<bool> chatExists(Chat chat) async {
    if (null == chat.chatId) return false;
    var dbClient = await db;
    var res = await dbClient
        .query(this._chats, where: "chat_id=?", whereArgs: [chat.chatId]);
    return res.length > 0 ? true : false;
  }

  Future updateChat(Chat chat) async {
    var dbClient = await db;
    int res = await dbClient.update(this._chats, chat.toMap(),
        where: "chat_sync_id=?", whereArgs: [chat.chatSyncId]);
    return res;
  }

  Future getChats(complaintId, orderBy) async {
    var dbClient = await db;
    var res = await dbClient.query(this._chats,
        where: "complaint_id=?", whereArgs: [complaintId], orderBy: orderBy);
    return res.length > 0 ? res : List<dynamic>.empty(growable: true);
  }

  Future<int> addChat(Chat chat) async {
    if (await chatExists(chat) == true) return await updateChat(chat);
    var dbClient = await db;
    int res = await dbClient.insert(this._chats, chat.toMap());
    return res;
  }

  Future updateChatSync(Chat chat, id) async {
    var dbClient = await db;
    int res = await dbClient
        .update(this._chats, chat.toMap(), where: "chat_id=?", whereArgs: [id]);
    return res;
  }

  Future<int> deleteChat(id) async {
    var dbClient = await db;
    int res = await dbClient
        .delete(this._chats, where: "complaint_id=?", whereArgs: [id]);
    return res;
  }

  // NOTIFICATION CONTROLLER
  Future<int> addNotification(NotificationModel notification) async {
    int res;
    var dbClient = await db;
    var checkNotification = await dbClient.query(this._notifications,
        where: "notification_id=?", whereArgs: [notification.notificationId]);
    if (checkNotification.length > 0) {
      res = await dbClient.update(this._notifications, notification.toMap(),
          where: "notification_id=?", whereArgs: [notification.notificationId]);
    } else {
      res = await dbClient.insert(this._notifications, notification.toMap());
    }
    return res;
  }

  Future getNotifications() async {
    var dbClient = await db;
    var res = await dbClient.query(this._notifications,
        orderBy: "notification_id DESC");
    return res.length > 0 ? res : List<dynamic>.empty(growable: true);
  }

  Future deleteNotification(NotificationModel notification) async {
    var dbClient = await db;
    int res = await dbClient.delete(this._notifications,
        where: "notification_id=?", whereArgs: [notification.notificationId]);
    return res;
  }

  Future<int> deleteAllNotifications() async {
    var dbClient = await db;
    int res = await dbClient.delete(this._notifications);
    return res;
  }

  // REPORT REQUESTS CONTROLLER
  Future<int> addReportRequest(ReportRequest reportRequest) async {
    int res;
    var dbClient = await db;
    var checkReportRequest = await dbClient.query(this._reportRequests,
        where: "report_request_id=?",
        whereArgs: [reportRequest.reportRequestId]);
    if (checkReportRequest.length > 0) {
      res = await dbClient.update(this._reportRequests, reportRequest.toMap(),
          where: "report_request_id=?",
          whereArgs: [reportRequest.reportRequestId]);
    } else {
      res = await dbClient.insert(this._reportRequests, reportRequest.toMap());
    }
    return res;
  }

  Future getReportRequests() async {
    var dbClient = await db;
    var res = await dbClient.query(this._reportRequests,
        orderBy: "report_request_id DESC");
    return res.length > 0 ? res : List<dynamic>.empty(growable: true);
  }

  Future deleteReportRequest(String reportRequestId) async {
    var dbClient = await db;
    int res = await dbClient.delete(this._reportRequests,
        where: "report_request_id=?", whereArgs: [reportRequestId]);
    return res;
  }

  Future<int> deleteAllReportRequest() async {
    var dbClient = await db;
    int res = await dbClient.delete(this._reportRequests);
    return res;
  }

  // PAYMENT HISTORY CONTROLLER
  Future<int> addPaymentHistory(Payment payment) async {
    int res;
    var dbClient = await db;
    var checkReportRequest = await dbClient.query(this._paymentHistory,
        where: "payment_history_id=?", whereArgs: [payment.paymentHistoryId]);
    if (checkReportRequest.length > 0) {
      res = await dbClient.update(this._paymentHistory, payment.toMap(),
          where: "payment_history_id=?", whereArgs: [payment.paymentHistoryId]);
    } else {
      res = await dbClient.insert(this._paymentHistory, payment.toMap());
    }
    return res;
  }

  Future<int> updatePaymentHistory(Payment payment) async {
    var dbClient = await db;
    int res = await dbClient.update(this._paymentHistory, payment.toMap(),
        where: "payment_history_id=?", whereArgs: [payment.paymentHistoryId]);
    return res;
  }

  Future getPaymentHistory() async {
    var dbClient = await db;
    var res = await dbClient.query(this._paymentHistory,
        orderBy: "payment_history_id DESC");
    return res.length > 0 ? res : List<dynamic>.empty(growable: true);
  }

  // SAVED CARDS CONTROLLER
  Future<bool> hasSavedCards() async {
    var dbClient = await db;
    var res = await dbClient.query(this._savedCards);
    return res.length > 0 ? true : false;
  }

  Future<int> addCard(SavedCard savedCard) async {
    int res;
    var dbClient = await db;
    var checkSavedCard = await dbClient.query(this._savedCards,
        where: "saved_card_id=?", whereArgs: [savedCard.savedCardId]);
    if (checkSavedCard.length > 0) {
      res = await dbClient.update(this._savedCards, savedCard.toMap(),
          where: "saved_card_id=?", whereArgs: [savedCard.savedCardId]);
    } else {
      res = await dbClient.insert(this._savedCards, savedCard.toMap());
    }
    return res;
  }

  Future getCards() async {
    var dbClient = await db;
    var res = await dbClient.query(this._savedCards, orderBy: "id DESC");
    return res.length > 0 ? res : List<dynamic>.empty(growable: true);
  }

  Future deleteCard(String savedCardId) async {
    var dbClient = await db;
    int res = await dbClient.delete(this._savedCards,
        where: "saved_card_id=?", whereArgs: [savedCardId]);
    return res;
  }

  // When User Logs Out
  Future deleteAllOtherTables() async {
    var dbClient = await db;
    await dbClient.delete(this._customer);
    await dbClient.delete(this._meters);
    await dbClient.delete(this._notifications);
    await dbClient.delete(this._chats);
    await dbClient.delete(this._vendors);
    await dbClient.delete(this._complaints);
    await dbClient.delete(this._paymentHistory);
    await dbClient.delete(this._reportRequests);
    await dbClient.delete(this._savedCards);
    return;
  }

  /// CREATING TABLES
  /// Create customer table
  void _createTableCustomer(Batch batch) {
    batch.execute('DROP TABLE IF EXISTS $_customer');
    batch.execute('''CREATE TABLE $_customer(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_id INTEGER,
      name TEXT,
      phone_number TEXT,
      email TEXT,
      device_id TEXT,
      allow_push TEXT,
      allow_email TEXT,
      allow_sms TEXT,
      digital_address TEXT,
      is_phone_verified TEXT,
      column_1 INTEGER,
      column_2 INTEGER,
      column_3 TEXT,
      column_4 TEXT,
      column_5 TEXT
      )''');
  }

  /// Create notifications table
  void _createTableNotifications(Batch batch) {
    batch.execute('DROP TABLE IF EXISTS $_notifications');
    batch.execute('''CREATE TABLE $_notifications(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      notification_id INTEGER,
      customer_id INTEGER,
      notification_type TEXT,
      message TEXT,
      status TEXT,
      date_created TEXT,
      column_1 INTEGER,
      column_2 INTEGER,
      column_3 TEXT,
      column_4 TEXT,
      column_5 TEXT
      )''');
  }

  /// Create meters table
  void _createTableMeters(Batch batch) {
    batch.execute('DROP TABLE IF EXISTS $_meters');
    batch.execute('''CREATE TABLE $_meters(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      meter_id INTEGER,
      customer_id INTEGER,
      account_name TEXT,
      digital_address TEXT,
      meter_number TEXT,
      account_number TEXT,
      primary_phone_number TEXT,
      meter_alias TEXT,
      meter_type TEXT,
      secondary_phone_number TEXT,
      email_address TEXT,
      balance TEXT,
      district_name TEXT,
      region_name TEXT,
      last_reading TEXT,
      service_category_name TEXT,
      last_read_date TEXT,
      last_bill_amount TEXT,
      last_bill_date TEXT,
      active TEXT,
      current_bill TEXT,
      column_1 INTEGER,
      column_2 INTEGER,
      column_3 TEXT,
      column_4 TEXT,
      column_5 TEXT
      )''');
  }

  /// Create vendors table
  void _createTableVendors(Batch batch) {
    batch.execute('DROP TABLE IF EXISTS $_vendors');
    batch.execute('''CREATE TABLE $_vendors(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      vendor_id INTEGER,
      customer_id INTEGER,
      account_name TEXT,
      account_number TEXT,
      email TEXT,
      telephone TEXT,
      structure_level_id TEXT,
      structure_level_name TEXT,
      structure_id TEXT,
      structure_name TEXT,
      balance TEXT,
      is_prepaid TEXT,
      is_private TEXT,
      active TEXT,
      last_paid_date TEXT,
      last_customer_payment_date TEXT,
      is_owner TEXT,
      column_1 INTEGER,
      column_2 INTEGER,
      column_3 TEXT,
      column_4 TEXT,
      column_5 TEXT
      )''');
  }

  /// Create complaints table
  void _createTableComplaints(Batch batch) {
    batch.execute('DROP TABLE IF EXISTS $_complaints');
    batch.execute('''CREATE TABLE $_complaints(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      complaint_id INTEGER,
      customer_id INTEGER,
      complaint_type TEXT,
      ticket_id TEXT,
      message TEXT,
      attached_files TEXT,
      status TEXT,
      comments TEXT,
      rating TEXT,
      unread_chat_count INTEGER,
      date_created TEXT,
      column_1 INTEGER,
      column_2 INTEGER,
      column_3 TEXT,
      column_4 TEXT,
      column_5 TEXT
      )''');
  }

  /// Create chats table
  void _createTableChats(Batch batch) {
    batch.execute('DROP TABLE IF EXISTS $_chats');
    batch.execute('''CREATE TABLE $_chats(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      chat_id INTEGER,
      chat_sync_id INTEGER,
      complaint_id INTEGER,
      participant_id INTEGER,
      participant_type TEXT,
      message TEXT,
      status TEXT,
      date_created TEXT,
      column_1 INTEGER,
      column_2 INTEGER,
      column_3 TEXT,
      column_4 TEXT,
      column_5 TEXT
      )''');
  }

  /// Create paymentHistory table
  void _createTablePaymentHistory(Batch batch) {
    batch.execute('DROP TABLE IF EXISTS $_paymentHistory');
    batch.execute('''CREATE TABLE $_paymentHistory(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      payment_history_id INTEGER,
      customer_id INTEGER,
      meter_id INTEGER,
      meter_balance TEXT,
      gwcl_customer_number TEXT,
      payer_name TEXT,
      meter_last_reading TEXT,
      payment_method TEXT,
      payment_status TEXT,
      amount TEXT,
      actual_amount TEXT,
      transaction_charge TEXT,
      msisdn TEXT,
      network TEXT,
      reference_key TEXT,
      response_code TEXT,
      transaction_id TEXT,
      response_message TEXT,
      old_balance TEXT,
      new_balance TEXT,
      meter_last_read_date TEXT,
      meter_last_bill_amount TEXT,
      meter_last_bill_date TEXT,
      meter_avg_consume TEXT,
      meter_account_number TEXT,
      meter_meter_alias TEXT,
      date_created TEXT,
      column_1 INTEGER,
      column_2 INTEGER,
      column_3 TEXT,
      column_4 TEXT,
      column_5 TEXT
      )''');
  }

  /// Create reportRequests table
  void _createTableReportRequests(Batch batch) {
    batch.execute('DROP TABLE IF EXISTS $_reportRequests');
    batch.execute('''CREATE TABLE $_reportRequests(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      report_request_id INTEGER,
      customer_id INTEGER,
      meter_id INTEGER,
      report_type TEXT,
      report_file_type TEXT,
      status TEXT,
      start_date TEXT,
      end_date TEXT,
      report_file_link TEXT,
      date_created TEXT,
      column_1 INTEGER,
      column_2 INTEGER,
      column_3 TEXT,
      column_4 TEXT,
      column_5 TEXT
      )''');
  }

  /// Create savedCards table
  void _createTableSavedCards(Batch batch) {
    batch.execute('DROP TABLE IF EXISTS $_savedCards');
    batch.execute('''CREATE TABLE $_savedCards(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      saved_card_id INTEGER,
      card_name TEXT,
      card_number_first TEXT,
      card_number_last TEXT,
      expiry_date TEXT,
      column_1 INTEGER,
      column_2 INTEGER,
      column_3 TEXT,
      column_4 TEXT,
      column_5 TEXT
      )''');
  }
}
