class QuestionTemplate {
  bool status;
  String message;
  List<QuestionData> questions;

  QuestionTemplate({
    required this.status,
    required this.message,
    required this.questions,
  });

  factory QuestionTemplate.fromJson(Map<String, dynamic> json) {
    return QuestionTemplate(
      status: json['status'] as bool,
      message: json['message'] as String,
      questions: (json['data'] as List<dynamic>)
          .map((item) => QuestionData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': questions.map((item) => item.toJson()).toList(),
    };
  }
}

class QuestionData {
  int id; 
  String key;
  String title;
  DateTime createdAt;
  DateTime updatedAt;

  QuestionData({
    required this.id,
    required this.key,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuestionData.fromJson(Map<String, dynamic> json) {
    return QuestionData(
      id: json['id'] as int,
      key: json['key'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
