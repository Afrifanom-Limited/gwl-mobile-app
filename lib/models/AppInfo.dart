class AppInfo {
  dynamic appVersion,
      minAndroidVersion,
      minIosVersion,
      byForceUpdate,
      maintenanceBreak,
      paymentPercentageCharge;

  AppInfo({
    this.appVersion,
    this.minAndroidVersion,
    this.minIosVersion,
    this.byForceUpdate,
    this.maintenanceBreak,
    this.paymentPercentageCharge,
  });

  AppInfo.map(dynamic obj) {
    this.appVersion = obj["app_version"].toString();
    this.minAndroidVersion = obj["min_android_version"].toString();
    this.minIosVersion = obj["min_ios_version"].toString();
    this.byForceUpdate = obj["byforce_update"];
    this.maintenanceBreak = obj["maintenance_break"];
    this.paymentPercentageCharge = obj["payment_percentage_charge"];
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["app_version"] = appVersion;
    map["min_android_version"] = minAndroidVersion;
    map["min_ios_version"] = minIosVersion;
    map["byforce_update"] = byForceUpdate;
    map["maintenance_break"] = maintenanceBreak;
    map["payment_percentage_charge"] = paymentPercentageCharge;
    return map;
  }
}
