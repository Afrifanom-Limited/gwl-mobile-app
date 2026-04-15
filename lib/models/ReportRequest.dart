class ReportRequest {
  dynamic reportRequestId,
      customerId,
      meterId,
      reportType,
      startDate,
      endDate,
      status,
      reportFileLink,
      reportFileType,
      dateCreated;

  ReportRequest({
    this.reportRequestId,
    this.customerId,
    this.meterId,
    this.reportType,
    this.startDate,
    this.endDate,
    this.status,
    this.reportFileLink,
    this.reportFileType,
    this.dateCreated,
  });

  ReportRequest.map(dynamic obj) {
    this.reportRequestId = obj["report_request_id"].toString();
    this.customerId = obj["customer_id"].toString();
    this.meterId = obj["meter_id"].toString();
    this.reportType = obj["report_type"];
    this.startDate = obj["start_date"];
    this.endDate = obj["end_date"];
    this.status = obj["status"];
    this.reportFileLink = obj["report_file_link"];
    this.reportFileType = obj["report_file_type"];
    this.dateCreated = obj["date_created"];
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["report_request_id"] = reportRequestId;
    map["customer_id"] = customerId;
    map["meter_id"] = meterId;
    map["report_type"] = reportType;
    map["start_date"] = startDate;
    map["end_date"] = endDate;
    map["status"] = status;
    map["report_file_link"] = reportFileLink;
    map["report_file_type"] = reportFileType;
    map["date_created"] = dateCreated;
    return map;
  }
}
