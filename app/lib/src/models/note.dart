class Note {
  final String id;

  String title;
  String? content;

  final DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    this.content,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(
    Map<String, dynamic> map,
  ) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String?,
      createdAt: DateTime.parse(
        map['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] as String,
      ),
    );
  }
}
