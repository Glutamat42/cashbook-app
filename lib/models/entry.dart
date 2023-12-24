class Entry {
  final int id;
  String description;
  String recipientSender;
  int amount;
  DateTime date;
  int categoryId;
  String paymentMethod;
  bool noInvoice;
  final int? userId;
  final int? userIdLastModified;
  final String? updatedAt;
  final String? createdAt;

  Entry({
    required this.id,
    required this.description,
    required this.recipientSender,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.paymentMethod,
    required this.noInvoice,
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
      date: DateTime.parse(json['date']),
      categoryId: json['category_id'],
      paymentMethod: json['payment_method'],
      noInvoice: json['no_invoice'] == 1,
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
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'payment_method': paymentMethod,
      'no_invoice': noInvoice ? 1 : 0,
      'user_id': userId,
      'user_id_last_modified': userIdLastModified,
      'updated_at': updatedAt,
      'created_at': createdAt,
    };
  }
}
