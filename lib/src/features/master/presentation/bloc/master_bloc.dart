import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/model/master_model.dart';
import '../../data/repository/master_repository_impl.dart';

enum MasterStatus { initial, loading, success, failure }

class MasterState {
  final MasterStatus status;
  final List<MasterModel> masters;
  final String? error;

  MasterState({
    this.status = MasterStatus.initial,
    this.masters = const [],
    this.error,
  });

  MasterState copyWith({
    MasterStatus? status,
    List<MasterModel>? masters,
    String? error,
  }) {
    return MasterState(
      status: status ?? this.status,
      masters: masters ?? this.masters,
      error: error,
    );
  }
}

abstract class MasterEvent {}

class MasterFetch extends MasterEvent {
  final double lat;
  final double long;
  final int pageSize;
  MasterFetch({required this.lat, required this.long, this.pageSize = 5});
}

class MasterBloc extends Bloc<MasterEvent, MasterState> {
  final MasterRepositoryImpl repository;
  MasterBloc(this.repository) : super(MasterState()) {
    on<MasterFetch>((event, emit) async {
      print('Master fetch function worked');
      emit(state.copyWith(status: MasterStatus.loading));
      final result = await repository.fetchMasters(
        lat: event.lat,
        long: event.long,
        pageSize: event.pageSize,
      );
      if (result.errorText.isEmpty) {
        emit(
          state.copyWith(status: MasterStatus.success, masters: result.data),
        );
      } else {
        emit(
          state.copyWith(status: MasterStatus.failure, error: result.errorText),
        );
      }
    });
  }
}
