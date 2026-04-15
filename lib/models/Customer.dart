class Customer {
  dynamic customerId,
      name,
      phoneNumber,
      email,
      deviceId,
      devicePlatform,
      allowPush,
      allowSms,
      allowEmail,
      allowBiometrics,
      digitalAddress,
      isPhoneVerified;

  Customer({
    this.customerId,
    this.name,
    this.phoneNumber,
    this.email,
    this.deviceId,
    this.devicePlatform,
    this.allowPush,
    this.allowSms,
    this.allowEmail,
    this.allowBiometrics,
    this.digitalAddress,
    this.isPhoneVerified,
  });

  Customer.map(dynamic obj) {
    this.customerId = obj["customer_id"];
    this.name = obj["name"];
    this.phoneNumber = obj["phone_number"];
    this.email = obj["email"];
    this.deviceId = obj["device_id"];
    this.allowPush = obj["allow_push"].toString();
    this.allowSms = obj["allow_sms"].toString();
    this.allowEmail = obj["allow_email"].toString();
    this.digitalAddress = obj["digital_address"];
    this.isPhoneVerified = obj["is_phone_verified"].toString();
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["customer_id"] = customerId;
    map["name"] = name;
    map["email"] = email;
    map["phone_number"] = phoneNumber;
    map["device_id"] = deviceId;
    map["allow_push"] = allowPush;
    map["allow_sms"] = allowSms;
    map["allow_email"] = allowEmail;
    map["digital_address"] = digitalAddress;
    map["is_phone_verified"] = isPhoneVerified;
    return map;
  }
}
