class Payment {
  dynamic paymentHistoryId,
      customerId,
      meterId,
      paymentMethod,
      paymentStatus,
      amount,
      actualAmount,
      transactionCharge,
      msisdn,
      network,
      responseCode,
      responseMessage,
      transactionId,
      dateCreated,
      referenceKey,
      oldBalance,
      newBalance,
      meterBalance,
      meterLastReadDate,
      meterLastBillAmount,
      meterLastBillDate,
      meterAvgConsume,
      meterLastReading,
      meterAlias,
      gwclCustomerNumber,
      payerName,
      meterAccountNumber;

  Payment({
    this.paymentHistoryId,
    this.customerId,
    this.meterId,
    this.paymentMethod,
    this.paymentStatus,
    this.amount,
    this.actualAmount,
    this.transactionCharge,
    this.msisdn,
    this.network,
    this.responseCode,
    this.responseMessage,
    this.transactionId,
    this.dateCreated,
    this.referenceKey,
    this.oldBalance,
    this.newBalance,
    this.meterBalance,
    this.meterLastReadDate,
    this.meterLastBillAmount,
    this.meterLastBillDate,
    this.meterAvgConsume,
    this.meterLastReading,
    this.meterAlias,
    this.gwclCustomerNumber,
    this.payerName,
    this.meterAccountNumber,
  });

  Payment.map(dynamic obj) {
    this.paymentHistoryId = obj["payment_history_id"].toString();
    this.customerId = obj["customer_id"].toString();
    this.meterId = obj["meter_id"].toString();
    this.paymentMethod = obj["payment_method"];
    this.paymentStatus = obj["payment_status"];
    this.amount = obj["amount"];
    this.actualAmount = obj["actual_amount"];
    this.transactionCharge = obj["transaction_charge"];
    this.msisdn = obj["msisdn"];
    this.network = obj["network"];
    this.referenceKey = obj["reference_key"];
    this.responseCode = obj["response_code"].toString();
    this.responseMessage = obj["response_message"];
    this.transactionId = obj["transaction_id"];
    this.oldBalance = obj["old_balance"];
    this.newBalance = obj["new_balance"];
    this.dateCreated = obj["date_created"];
    this.meterBalance = obj["meter_balance"];
    this.meterLastReadDate = obj["meter_last_read_date"];
    this.meterLastBillAmount = obj["meter_last_bill_amount"];
    this.meterLastBillDate = obj["meter_last_bill_date"];
    this.meterAvgConsume = obj["meter_avg_consume"];
    this.meterLastReading = obj["meter_last_reading"];
    this.meterAccountNumber = obj["meter_account_number"];
    this.meterAlias = obj["meter_meter_alias"];
    this.gwclCustomerNumber = obj["gwcl_customer_number"];
    this.payerName = obj["payer_name"];
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["payment_history_id"] = paymentHistoryId;
    map["customer_id"] = customerId;
    map["meter_id"] = meterId;
    map["payment_method"] = paymentMethod;
    map["payment_status"] = paymentStatus;
    map["amount"] = amount;
    map["actual_amount"] = actualAmount;
    map["transaction_charge"] = transactionCharge;
    map["msisdn"] = msisdn;
    map["network"] = network;
    map["reference_key"] = referenceKey;
    map["response_code"] = responseCode;
    map["response_message"] = responseMessage;
    map["transaction_id"] = transactionId;
    map["old_balance"] = oldBalance;
    map["new_balance"] = newBalance;
    map["date_created"] = dateCreated;
    map["meter_balance"] = meterBalance;
    map["meter_last_read_date"] = meterLastReadDate;
    map["meter_last_bill_amount"] = meterLastBillAmount;
    map["meter_last_bill_date"] = meterLastBillDate;
    map["meter_avg_consume"] = meterAvgConsume;
    map["meter_last_reading"] = meterLastReading;
    map["meter_meter_alias"] = meterAlias;
    map["meter_account_number"] = meterAccountNumber;
    map["gwcl_customer_number"] = gwclCustomerNumber;
    map["payer_name"] = payerName;
    return map;
  }
}
