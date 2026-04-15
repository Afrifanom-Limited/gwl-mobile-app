class NotificationModel {
  dynamic notificationId,
      customerId,
      notificationType,
      message,
      status,
      dateCreated;

  NotificationModel({
    this.notificationId,
    this.customerId,
    this.notificationType,
    this.message,
    this.status,
    this.dateCreated,
  });

  NotificationModel.map(dynamic obj) {
    this.notificationId = obj["notification_id"].toString();
    this.customerId = obj["customer_id"].toString();
    this.notificationType = obj["notification_type"];
    this.message = obj["message"];
    this.status = obj["status"];
    this.dateCreated = obj["date_created"];
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["notification_id"] = notificationId;
    map["customer_id"] = customerId;
    map["notification_type"] = notificationType;
    map["message"] = message;
    map["status"] = status;
    map["date_created"] = dateCreated;
    return map;
  }
}
