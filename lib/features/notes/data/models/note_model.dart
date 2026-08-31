class NoteModel {
  final String id;
  final String title;
  final String content;
  final String category; // 'General', 'Todo', 'Supplier', 'Customer', 'Idea'
  final int colorIndex; // 0: Purple/Primary, 1: Teal, 2: Yellow/Amber, 3: Red/Pink, 4: Slate/Grey
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.colorIndex,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  });

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    int? colorIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'colorIndex': colorIndex,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
    };
  }

  factory NoteModel.fromMap(Map<dynamic, dynamic> map) {
    return NoteModel(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      colorIndex: map['colorIndex'] as int? ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      isPinned: map['isPinned'] as bool? ?? false,
    );
  }
}
