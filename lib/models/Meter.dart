class Meter {
  dynamic meterId,
      customerId,
      meterNumber,
      accountNumber,
      meterType,
      serviceCategoryName,
      balance,
      accountName,
      digitalAddress,
      secondaryNumber,
      primaryNumber,
      meterAlias,
      districtName,
      lastReadDate,
      lastBillAmount,
      lastBillDate,
      active,
      lastReading,
      currentBill,
      emailAddress;

  Meter({
    this.meterId,
    this.customerId,
    this.accountNumber,
    this.digitalAddress,
    this.meterType,
    this.balance,
    this.meterNumber,
    this.secondaryNumber,
    this.primaryNumber,
    this.accountName,
    this.meterAlias,
    this.serviceCategoryName,
    this.districtName,
    this.emailAddress,
    this.active,
    this.lastBillAmount,
    this.lastBillDate,
    this.lastReadDate,
    this.currentBill,
    this.lastReading,
  });

  Meter.map(dynamic obj) {
    this.meterId = obj["meter_id"].toString();
    this.customerId = obj["customer_id"].toString();
    this.meterType = obj["meter_type"];
    this.digitalAddress = obj["digital_address"];
    this.meterNumber = obj["meter_number"];
    this.accountNumber = obj["account_number"];
    this.primaryNumber = obj["primary_phone_number"];
    this.secondaryNumber = obj["secondary_phone_number"];
    this.accountName = obj["account_name"];
    this.balance = obj["balance"].toString();
    this.serviceCategoryName = obj["service_category_name"];
    this.districtName = obj["district_name"];
    this.meterAlias = obj["meter_alias"];
    this.emailAddress = obj["email_address"];
    this.lastReadDate = obj["last_read_date"];
    this.active = obj["active"].toString();
    this.lastBillDate = obj["last_bill_date"];
    this.lastBillAmount = obj["last_bill_amount"].toString();
    this.lastReading = obj["last_reading"].toString();
    this.currentBill = obj["current_bill"].toString();
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["meter_id"] = meterId;
    map["customer_id"] = customerId;
    map["meter_type"] = meterType;
    map["digital_address"] = digitalAddress;
    map["meter_number"] = meterNumber;
    map["account_number"] = accountNumber;
    map["account_name"] = accountName;
    map["primary_phone_number"] = primaryNumber;
    map["secondary_phone_number"] = secondaryNumber;
    map["balance"] = balance;
    map["district_name"] = districtName;
    map["service_category_name"] = serviceCategoryName;
    map["meter_alias"] = meterAlias;
    map["email_address"] = emailAddress;
    map["last_read_date"] = lastReadDate;
    map["active"] = active;
    map["last_bill_date"] = lastBillDate;
    map["last_bill_amount"] = lastBillAmount;
    map["last_reading"] = lastReading;
    map["current_bill"] = currentBill;
    return map;
  }
}
