class AutoPayment {
  dynamic autoPaymentId,
      accountNumber,
      customerName,
      lastBillAmount,
      lastBillDate,
      msisdn,
      network,
      transactionId;

  AutoPayment({
    this.autoPaymentId,
    this.accountNumber,
    this.customerName,
    this.lastBillAmount,
    this.lastBillDate,
    this.msisdn,
    this.network,
    this.transactionId,
  });

  AutoPayment.map(dynamic obj) {
    this.autoPaymentId = obj["auto_payment_id"].toString();
    this.accountNumber = obj["account_number"].toString();
    this.customerName = obj["customer_name"].toString();
    this.lastBillAmount = obj["last_bill_amount"].toString();
    this.lastBillDate = obj["last_bill_date"];
    this.msisdn = obj["msisdn"];
    this.network = obj["network"];
    this.transactionId = obj["transaction_id"];
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["auto_payment_id"] = autoPaymentId;
    map["account_number"] = accountNumber;
    map["customer_name"] = customerName;
    map["last_bill_amount"] = lastBillAmount;
    map["last_bill_date"] = lastBillDate;
    map["msisdn"] = msisdn;
    map["network"] = network;
    map["transaction_id"] = transactionId;
    return map;
  }
}
