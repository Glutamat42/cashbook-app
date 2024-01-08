class Entry {
  int? id;  // only allowed to be null for new entries
  String description;
  String recipientSender;
  int? amount;
  bool isIncome;
  DateTime date;
  int? categoryId;
  String paymentMethod;
  bool noInvoice;
  int? userId;
  int? userIdLastModified;
  String? updatedAt;
  String? createdAt;

  Entry({
    this.id,
    this.description = "",
    this.recipientSender = "",
    this.amount,
    this.isIncome = false,
    required this.date,
    this.categoryId,
    this.paymentMethod = "not_payed",
    this.noInvoice = false,
    this.userId,
    this.userIdLastModified,
    this.updatedAt,
    this.createdAt,
  });

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      id: json['id'],
      description: json['description'],
      recipientSender: json['recipient_sender'],
      amount: json['amount'],
      isIncome: json['is_income'],
      date: DateTime.parse(json['date']),
      categoryId: json['category_id'],
      paymentMethod: json['payment_method'],
      noInvoice: json['no_invoice'],
      userId: json['user_id'],
      userIdLastModified: json['user_id_last_modified'],
      updatedAt: json['updated_at'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'recipient_sender': recipientSender,
      'amount': amount,
      'is_income': isIncome,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'payment_method': paymentMethod,
      'no_invoice': noInvoice,
      'user_id': userId,
      'user_id_last_modified': userIdLastModified,
      'updated_at': updatedAt,
      'created_at': createdAt,
    };
  }

  void updateFrom(Entry other) {
    id = other.id;
    userIdLastModified = other.userIdLastModified;
    userId = other.userId;
    updatedAt = other.updatedAt;
    createdAt = other.createdAt;
    description = other.description;
    recipientSender = other.recipientSender;
    amount = other.amount;
    date = other.date;
    categoryId = other.categoryId;
    paymentMethod = other.paymentMethod;
    noInvoice = other.noInvoice;
  }
}
