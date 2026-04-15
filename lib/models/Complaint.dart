class Complaint {
  dynamic complaintId,
      customerId,
      complaintType,
      ticketId,
      message,
      status,
      rating,
      attachedFiles,
      unreadChatCount,
      dateCreated;

  Complaint({
    this.complaintId,
    this.customerId,
    this.complaintType,
    this.ticketId,
    this.message,
    this.attachedFiles,
    this.unreadChatCount,
    this.status,
    this.rating,
    this.dateCreated,
  });

  Complaint.map(dynamic obj) {
    this.complaintId = obj["complaint_id"].toString();
    this.customerId = obj["customer_id"].toString();
    this.complaintType = obj["complaint_type"];
    this.ticketId = obj["ticket_id"];
    this.message = obj["message"];
    this.attachedFiles = obj["attached_files"];
    this.status = obj["status"];
    this.unreadChatCount = obj["unread_chat_count"].toString();
    this.rating = obj["rating"].toString();
    this.dateCreated = obj["date_created"];
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["complaint_id"] = complaintId;
    map["customer_id"] = customerId;
    map["complaint_type"] = complaintType;
    map["ticket_id"] = ticketId;
    map["message"] = message;
    map["attached_files"] = attachedFiles;
    map["status"] = status;
    map["unread_chat_count"] = unreadChatCount;
    map["rating"] = rating;
    map["date_created"] = dateCreated;
    return map;
  }
}
