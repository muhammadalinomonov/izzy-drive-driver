import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/profile/presentation/blocs/profile_bloc.dart';

class ChartWidget extends StatefulWidget {
  const ChartWidget({super.key});

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (_tabController.indexIsChanging) {
          String filter;
          String period;
          switch (_tabController.index) {
            case 0:
              filter = 'days';
              final now = DateTime.now();
              period = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
              break;
            case 1:
              filter = 'months';
              final now = DateTime.now();
              period = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
              break;
            case 2:
              filter = 'years';
              final now = DateTime.now();
              period = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
              break;
            default:
              filter = 'days';
              final now = DateTime.now();
              period = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          }
          context.read<ProfileBloc>().add(GetUserStatisticsEvent(filter: filter, period: period));

        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state.getUserStatisticsStatus.isSuccess) {
          final allTimeIsZero = state.statistics.every((stat) => stat.totalSum == 0);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 34,
                margin: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: solitude,
                ),
                child: TabBar(
                  indicatorPadding: EdgeInsets.all(2),
                  indicator: BoxDecoration(color: white, borderRadius: BorderRadius.circular(50)),
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Days'),
                    Tab(text: 'Months'),
                    Tab(text: 'Years'),
                  ],
                ),
              ),
              Text(
                '\$${state.selectedStatistic.totalSum}',
                style: context.textTheme.headlineLarge!.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: black,
                ),
              ),
              SizedBox(height: 4),
              Text(
                state.selectedStatistic.dateStr,
                style: context.textTheme.bodyMedium!.copyWith(
                  color: gray4,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              /*onTapDown: (details) {
                    // Chart o'lchamlarini hisoblash
                    final RenderBox renderBox = context.findRenderObject() as RenderBox;
                    final localPosition = renderBox.globalToLocal(details.globalPosition);

                    // Bar indexini hisoblash (taxminiy)
                    final chartWidth = renderBox.size.width - 32; // padding hisobga olish
                    final barWidth = chartWidth / state.statistics.length;
                    final tappedIndex = (localPosition.dx / barWidth).floor();

                    if (tappedIndex >= 0 && tappedIndex < state.statistics.length) {
                      print('Tapped on bar: 222 $tappedIndex');
                      context
                          .read<ProfileBloc>()
                          .add(SelectStatistic(statistic: state.statistics[tappedIndex]));
                    }
                  },*/
              Expanded(
                child: LayoutBuilder(
        builder: (context, constraints)=> GestureDetector(
                  
                    onTapDown: (TapDownDetails details) {
                      // Chart containerning local pozitsiyasini olish
                      final RenderBox renderBox = context.findRenderObject() as RenderBox;
                      final localPosition = renderBox.globalToLocal(details.globalPosition);
                  
                      // Chart o'lchamlari
                      final chartWidth = constraints.maxWidth;
                      final chartHeight = constraints.maxHeight;
                  
                      // Bottom title uchun reserved space
                      final bottomTitleHeight = 30.0;
                      final actualChartHeight = chartHeight - bottomTitleHeight;
                  
                      // Padding va margin hisobga olish (fl_chart default margins)
                      final leftPadding = 10.0;
                      final rightPadding = 10.0;
                      final actualChartWidth = chartWidth - leftPadding - rightPadding;
                  
                      // Har bir bar uchun joy hisobi
                      final barCount = state.statistics.length;
                      final barSpacing = actualChartWidth / barCount;
                  
                      // Bosilgan pozitsiyani bar indexiga aylantirish
                      final adjustedX = localPosition.dx - leftPadding;
                  
                      if (adjustedX >= 0 && adjustedX <= actualChartWidth &&
                          localPosition.dy >= 0 && localPosition.dy <= actualChartHeight) {
                  
                        int tappedIndex = (adjustedX / barSpacing).floor();
                  
                        // Index chegaralarini tekshirish
                        if (tappedIndex >= 0 && tappedIndex < barCount) {
                          print('Tapped on bar index: $tappedIndex');
                  
                          context
                              .read<ProfileBloc>()
                              .add(SelectStatistic(statistic: state.statistics[tappedIndex]));
                        }
                      }
                    },
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 100,
                        minY: 0,
                    
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) => Colors.transparent,
                            tooltipBorder: BorderSide.none,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) => null, // tooltip ko'rsatmaslik
                          ),
                          handleBuiltInTouches: false,
                          touchCallback: (event, barTouchResponse) {
                            if (event is FlTapUpEvent && barTouchResponse != null) {
                              final spot = barTouchResponse.spot;
                              print('Tapped on bar: ${spot?.touchedBarGroupIndex}');
                              if (spot != null) {
                                context
                                    .read<ProfileBloc>()
                                    .add(SelectStatistic(statistic: state.statistics[spot.touchedBarGroupIndex]));
                              }
                            }
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                return Expanded(
                                  child: Text(
                                    state.statistics[value.toInt()].dateStr.substring(0, 6),
                                    style: context.textTheme.bodyMedium!.copyWith(
                                      color: gray4,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        barGroups: [
                          ...List.generate(
                            state.statistics.length,
                            (index) => BarChartGroupData(
                              x: index,
                              showingTooltipIndicators: [],
                              barRods: [
                                BarChartRodData(
                                  toY: !allTimeIsZero ? state.statistics[index].percentage.toDouble() : .1,
                                  color: state.selectedStatistic == state.statistics[index] ? mainColor : Color(0xffC6D6E6),
                                  width: 26,
                                  borderRadius: BorderRadius.circular(8),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          return Center(child: CircularProgressIndicator.adaptive());
        }
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
