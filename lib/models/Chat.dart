class Chat {
  dynamic chatId,
      complaintId,
      participantId,
      participantType,
      message,
      status,
      chatSyncId,
      dateCreated;

  Chat({
    this.chatId,
    this.complaintId,
    this.participantId,
    this.participantType,
    this.message,
    this.status,
    this.chatSyncId,
    this.dateCreated,
  });

  Chat.map(dynamic obj) {
    this.chatId = obj["chat_id"].toString();
    this.complaintId = obj["complaint_id"].toString();
    this.participantId = obj["participant_id"].toString();
    this.participantType = obj["participant_type"];
    this.message = obj["message"];
    this.status = obj["status"];
    this.chatSyncId = obj["chat_sync_id"].toString();
    this.dateCreated = obj["date_created"];
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["chat_id"] = chatId;
    map["complaint_id"] = complaintId;
    map["participant_id"] = participantId;
    map["participant_type"] = participantType;
    map["message"] = message;
    map["status"] = status;
    map["chat_sync_id"] = chatSyncId;
    map["date_created"] = dateCreated;
    return map;
  }
}
