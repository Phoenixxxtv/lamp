/// Interest model for admin-defined interests
class Interest {
  final String id;
  final String name;
  final DateTime createdAt;

  const Interest({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
