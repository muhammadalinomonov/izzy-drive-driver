import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:taxi_app/src/core/location_service.dart';
import 'package:taxi_app/src/features/master/data/model/review_model.dart';

import '../../data/model/master_model.dart';
import '../../data/repository/master_repository_impl.dart';

enum MasterStatus { initial, loading, success, failure }

class MasterState {
  final MasterStatus status;
  final List<MasterModel> masters;
  final String? error;
  final String? currentAddress;
  final FormzSubmissionStatus getMasterDetailStatus;
  final MasterModel masterDetail;
  final FormzSubmissionStatus masterReviewStatus;
  final List<ReviewModel> masterReviews;

  MasterState({
    this.status = MasterStatus.initial,
    this.masters = const [],
    this.error,
    this.currentAddress,
    this.getMasterDetailStatus = FormzSubmissionStatus.initial,
    this.masterDetail = const MasterModel(),
    this.masterReviewStatus = FormzSubmissionStatus.initial,
    this.masterReviews = const [],
  });

  MasterState copyWith({
    MasterStatus? status,
    List<MasterModel>? masters,
    String? error,
    String? currentAddress,
    MasterModel? masterDetail,
    FormzSubmissionStatus? getMasterDetailStatus,
    FormzSubmissionStatus? masterReviewStatus,
    List<ReviewModel>? masterReviews,
  }) {
    return MasterState(
      status: status ?? this.status,
      masters: masters ?? this.masters,
      error: error,
      currentAddress: currentAddress ?? this.currentAddress,
      getMasterDetailStatus: getMasterDetailStatus ?? this.getMasterDetailStatus,
      masterDetail: masterDetail ?? this.masterDetail,
      masterReviewStatus: masterReviewStatus ?? this.masterReviewStatus,
      masterReviews: masterReviews ?? this.masterReviews,
    );
  }
}

abstract class MasterEvent {}

class MasterFetch extends MasterEvent {
  final double? lat;
  final double? long;
  final int pageSize;

  MasterFetch({this.lat, this.long, this.pageSize = 5});
}

class GetMasterDetail extends MasterEvent {
  final int masterId;

  GetMasterDetail(this.masterId);
}

class GetMasterReviews extends MasterEvent {
  final String url;

  GetMasterReviews(this.url);
}

class MasterBloc extends Bloc<MasterEvent, MasterState> {
  final MasterRepositoryImpl repository;
  final LocationService locationService;

  MasterBloc(this.repository, this.locationService) : super(MasterState()) {
    on<MasterFetch>((event, emit) async {
      emit(state.copyWith(status: MasterStatus.loading));
      double? lat = event.lat;
      double? long = event.long;
      String? address;
      if (lat == null || long == null) {
        final position = await locationService.getCurrentLocation();
        if (position != null) {
          lat = position.latitude;
          long = position.longitude;
          print('position is not null');
          address = await locationService.getAddressFromLatLng(lat, long);
        } else {
          print('Could not get user location');
          emit(state.copyWith(status: MasterStatus.failure, error: 'Could not get user location'));
          return;
        }
      }
      print('fetchMasters bloc $lat $long');
      final result = await repository.fetchMasters(lat: lat, long: long, pageSize: event.pageSize);
      if (result.errorText.isEmpty) {
        print('adress came here >>> $address');
        emit(MasterState(status: MasterStatus.success, masters: result.data, currentAddress: address));
      } else {
        emit(state.copyWith(status: MasterStatus.failure, error: result.errorText, currentAddress: address));
      }
    });

    on<GetMasterDetail>((event, emit) async {
      emit(state.copyWith(getMasterDetailStatus: FormzSubmissionStatus.inProgress));

      double? lat;
      double? long;
      final position = await locationService.getCurrentLocation();
      if (position != null) {
        lat = position.latitude;
        long = position.longitude;
      } else {
        emit(state.copyWith(status: MasterStatus.failure, error: 'Could not get user location'));
        return;
      }

      final result = await repository.getMasterDetail(id: event.masterId, lat: lat, long: long);

      if (result.errorText.isEmpty) {
        if (result.data is MasterModel && (result.data as MasterModel).allReviewsUrl.isNotEmpty) {
          add(GetMasterReviews((result.data as MasterModel).allReviewsUrl));
        }
        emit(state.copyWith(masterDetail: result.data, getMasterDetailStatus: FormzSubmissionStatus.success));
      } else {
        emit(
          state.copyWith(
            status: MasterStatus.failure,
            error: result.errorText,
            getMasterDetailStatus: FormzSubmissionStatus.failure,
          ),
        );
      }
    });

    on<GetMasterReviews>((event, emit) async {
      emit(state.copyWith(masterReviewStatus: FormzSubmissionStatus.inProgress));

      final result = await repository.getMasterReviews(url: event.url);
      if (result.errorText.isEmpty) {
        emit(state.copyWith(masterReviews: result.data, masterReviewStatus: FormzSubmissionStatus.success));
      } else {
        emit(
          state.copyWith(
            status: MasterStatus.failure,
            error: result.errorText.isNotEmpty ? result.errorText : 'Something went wrong',
            masterReviewStatus: FormzSubmissionStatus.failure,
          ),
        );
      }
    });
  }
}
