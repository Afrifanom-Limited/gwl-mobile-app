class Vendor {
  dynamic vendorId,
      customerId,
      accountName,
      accountNumber,
      email,
      telephone,
      structureLevelId,
      structureLevelName,
      structureId,
      structureName,
      balance,
      isPrivate,
      isPrepaid,
      active,
      lastPaidDate,
      lastCustomerPaymentDate,
      isOwner;

  Vendor({
    this.vendorId,
    this.customerId,
    this.accountName,
    this.accountNumber,
    this.email,
    this.telephone,
    this.structureLevelId,
    this.structureLevelName,
    this.structureId,
    this.structureName,
    this.balance,
    this.isPrepaid,
    this.isPrivate,
    this.active,
    this.lastPaidDate,
    this.lastCustomerPaymentDate,
    this.isOwner,
  });

  Vendor.map(dynamic obj) {
    this.vendorId = obj["vendor_id"].toString();
    this.customerId = obj["customer_id"].toString();
    this.accountName = obj["account_name"];
    this.accountNumber = obj["account_number"];
    this.email = obj["email"];
    this.telephone = obj["telephone"].toString();
    this.structureLevelId = obj["structure_level_id"].toString();
    this.structureLevelName = obj["structure_level_name"];
    this.structureId = obj["structure_id"].toString();
    this.structureName = obj["structure_name"].toString();
    this.balance = obj["balance"].toString();
    this.isPrivate = obj["is_private"].toString();
    this.isPrepaid = obj["is_prepaid"].toString();
    this.active = obj["active"].toString();
    this.lastPaidDate = obj["last_paid_date"];
    this.lastCustomerPaymentDate = obj["last_customer_payment_date"].toString();
    this.isOwner = obj["is_owner"].toString();
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["vendor_id"] = vendorId;
    map["customer_id"] = customerId;
    map["account_name"] = accountName;
    map["account_number"] = accountNumber;
    map["email"] = email;
    map["telephone"] = telephone;
    map["structure_level_id"] = structureLevelId;
    map["structure_level_name"] = structureLevelName;
    map["structure_id"] = structureId;
    map["structure_name"] = structureName;
    map["balance"] = balance;
    map["is_private"] = isPrivate;
    map["is_prepaid"] = isPrepaid;
    map["active"] = active;
    map["last_paid_date"] = lastPaidDate;
    map["last_customer_payment_date"] = lastCustomerPaymentDate;
    map["is_owner"] = isOwner;
    return map;
  }
}
