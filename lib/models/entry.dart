class Entry {
  final int id;
  final String description;
  final String recipientSender;
  final int amount;
  final DateTime date;

  Entry({
    required this.id,
    required this.description,
    required this.recipientSender,
    required this.amount,
    required this.date,
  });
  // todo add missing fields
  factory Entry.fromJson(Map<String, dynamic> json) {
    try {
      return Entry(
        id: json['id'],
        description: json['description'],
        recipientSender: json['recipient_sender'], // Adjust the field name as needed
        amount: json['amount'],
        date: DateTime.parse(json['date']),
      );
    } catch (e) {
      throw FormatException('Error parsing entry data: ${e.toString()}');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'recipient_sender': recipientSender,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }
}
