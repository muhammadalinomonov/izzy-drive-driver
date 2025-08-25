part of 'profile_bloc.dart';

@immutable
class ProfileState extends Equatable {
  final FormzSubmissionStatus updateStatusStatus;
  final String? errorMessage;
  final FormzSubmissionStatus getProfileStatus;
  final UserEntity user;
  final String status;
  final FormzSubmissionStatus updateCurrentLocationStatus;
  final FormzSubmissionStatus getUserStatisticsStatus;
  final List<StatisticEntity> statistics;
  final String selectedFilter;
  final String selectedPeriod;
  final StatisticEntity selectedStatistic;

  const ProfileState({
    this.updateStatusStatus = FormzSubmissionStatus.initial,
    this.errorMessage,
    this.getProfileStatus = FormzSubmissionStatus.initial,
    this.user = const UserEntity(),
    this.status = '',
    this.updateCurrentLocationStatus = FormzSubmissionStatus.initial,
    this.getUserStatisticsStatus = FormzSubmissionStatus.initial,
    this.statistics = const [],
    this.selectedFilter = 'days',
    this.selectedPeriod = '',
    this.selectedStatistic = const StatisticEntity(),
  });

  ProfileState copyWith({
    FormzSubmissionStatus? updateStatusStatus,
    String? errorMessage,
    FormzSubmissionStatus? getProfileStatus,
    UserEntity? user,
    String? status,
    FormzSubmissionStatus? updateCurrentLocationStatus,
    FormzSubmissionStatus? getUserStatisticsStatus,
    List<StatisticEntity>? statistics,
    String? selectedFilter,
    String? selectedPeriod,
    StatisticEntity? selectedStatistic,
  }) {
    return ProfileState(
      updateStatusStatus: updateStatusStatus ?? this.updateStatusStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      getProfileStatus: getProfileStatus ?? this.getProfileStatus,
      user: user ?? this.user,
      status: status ?? this.status,
      updateCurrentLocationStatus: updateCurrentLocationStatus ?? this.updateCurrentLocationStatus,
      getUserStatisticsStatus: getUserStatisticsStatus ?? this.getUserStatisticsStatus,
      statistics: statistics ?? this.statistics,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      selectedStatistic: selectedStatistic ?? this.selectedStatistic,
    );
  }

  @override
  List<Object?> get props => [
        updateStatusStatus,
        errorMessage,
        getProfileStatus,
        user,
        status,
        updateCurrentLocationStatus,
        getUserStatisticsStatus,
        statistics,
        selectedFilter,
        selectedPeriod,
        selectedStatistic,
      ];
}
