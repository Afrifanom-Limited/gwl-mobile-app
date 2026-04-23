class Feed {
  dynamic feedId,
      feedType,
      author,
      title,
      message,
      media,
      targetRegion,
      targetDistrict,
      dateCreated,
      isLikedByMe,
      reactions,
          billData,
      paymentData;

  Feed({
    this.feedId,
    this.feedType,
    this.author,
    this.title,
    this.message,
    this.media,
    this.targetRegion,
    this.targetDistrict,
    this.dateCreated,
    this.isLikedByMe,
    this.reactions,
    this.billData,
    this.paymentData,
  });

  Feed.map(dynamic obj) {
    this.feedId = obj["feed_id"].toString();
    this.title = obj["title"].toString();
    this.feedType = obj["feed_type"].toString();
    this.author = obj["author"].toString();
    this.message = obj["message"].toString();
    this.media = obj["media"];
    this.targetRegion = obj["target_region"];
    this.targetDistrict = obj["target_district"];
    this.dateCreated = obj["date_created"];
    this.isLikedByMe = obj["is_liked_by_me"];
    this.reactions = obj["reactions"];
    this.billData = obj["billData"];
    this.paymentData = obj["paymentData"];
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["feed_id"] = feedId;
    map["feed_type"] = feedType;
    map["author"] = author;
    map["title"] = title;
    map["message"] = message;
    map["media"] = media;
    map["target_region"] = targetRegion;
    map["target_district"] = targetDistrict;
    map["date_created"] = dateCreated;
    map["is_liked_by_me"] = isLikedByMe;
    map["reactions"] = reactions;
    map["billData"] = billData;
    map["paymentData"] = paymentData;
    return map;
  }

  bool isLiked(dynamic liked) {
    if (liked.toString() != '0') {
      return true;
    } else {
      return false;
    }
  }
}
