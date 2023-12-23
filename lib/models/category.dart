class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    try {
      return Category(
        id: json['id'],
        name: json['name'],
      );
    } catch (e) {
      throw FormatException('Error parsing category data: ${e.toString()}');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
