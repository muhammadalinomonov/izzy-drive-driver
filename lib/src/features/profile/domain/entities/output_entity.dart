import 'package:equatable/equatable.dart';

class OutPutEntity extends Equatable {
  final int id;
  final int driver;
  final String title;
  final String amount;
  final String date;
  final String createdAt;

  const OutPutEntity({
    this.id = -1,
    this.driver = -1,
    this.title = '',
    this.amount = '',
    this.date = '',
    this.createdAt = '',
  });

  @override
  List<Object?> get props => [id, driver, title, amount, date, createdAt];
}
