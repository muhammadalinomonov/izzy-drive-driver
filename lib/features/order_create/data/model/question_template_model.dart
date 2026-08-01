enum QuestionType {
  textOrAudio,
  photos,
  price,
  text,
  unknown,
}

QuestionType _parseType(String? raw) {
  switch (raw) {
    case 'text_or_audio':
      return QuestionType.textOrAudio;
    case 'photos':
      return QuestionType.photos;
    case 'price':
      return QuestionType.price;
    case 'text':
      return QuestionType.text;
    default:
      return QuestionType.unknown;
  }
}

class QuestionTemplate {
  const QuestionTemplate({
    required this.id,
    required this.key,
    required this.title,
    required this.body,
    required this.type,
    required this.order,
    required this.isActive,
  });

  final int id;
  final String key;
  final String title;
  final String body;
  final QuestionType type;
  final int order;
  final bool isActive;

  factory QuestionTemplate.fromJson(Map<String, dynamic> json) {
    return QuestionTemplate(
      id: (json['id'] as num?)?.toInt() ?? 0,
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: _parseType(json['type']?.toString()),
      order: (json['order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
