import 'package:equatable/equatable.dart';

class StatisticEntity extends Equatable {
  final String date;
  final String dateStr;
  final int ordersCount;
  final int totalSum;
  final int percentage;
  final bool selected;

  const StatisticEntity({
    this.date = '',
    this.dateStr = '',
    this.ordersCount = 0,
    this.totalSum = 0,
    this.percentage = 0,
    this.selected = false,
  });

  @override
  List<Object?> get props => [date, dateStr, ordersCount, totalSum, percentage, selected];
}
