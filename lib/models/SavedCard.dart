class SavedCard {
  dynamic savedCardId,
      cardName,
      cardNumberFirst,
      cardNumberLast,
      expiryDate;

  SavedCard({
    this.savedCardId,
    this.cardName,
    this.cardNumberFirst,
    this.cardNumberLast,
    this.expiryDate,
  });

  SavedCard.map(dynamic obj) {
    this.savedCardId = obj["saved_card_id"].toString();
    this.cardName = obj["card_name"].toString();
    this.cardNumberFirst = obj["card_number_first"].toString();
    this.cardNumberLast = obj["card_number_last"];
    this.expiryDate = obj["expiry_date"];
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["saved_card_id"] = savedCardId;
    map["card_name"] = cardName;
    map["card_number_first"] = cardNumberFirst;
    map["card_number_last"] = cardNumberLast;
    map["expiry_date"] = expiryDate;
    return map;
  }
}
