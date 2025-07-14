import 'dart:convert';
class Question {
  final int id;
  final String key;
  final String title;

  Question({required this.id, required this.key, required this.title});

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'],
    key: json['key'],
    title: json['title'],
  );

}