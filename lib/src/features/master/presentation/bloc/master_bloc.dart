import 'dart:ffi';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taxi_app/src/core/location_service.dart';
import '../../data/model/master_model.dart';
import '../../data/repository/master_repository_impl.dart';

enum MasterStatus { initial, loading, success, failure }

class MasterState {
  final MasterStatus status;
  final List<MasterModel> masters;
  final String? error;
  final String? currentAddress;

  MasterState({
    this.status = MasterStatus.initial,
    this.masters = const [],
    this.error,
    this.currentAddress,
  });

  MasterState copyWith({
    MasterStatus? status,
    List<MasterModel>? masters,
    String? error,
    String? currentAddress,
  }) {
    return MasterState(
      status: status ?? this.status,
      masters: masters ?? this.masters,
      error: error,
      currentAddress: currentAddress ?? this.currentAddress,
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
          emit(
            state.copyWith(
              status: MasterStatus.failure,
              error: 'Could not get user location',
            ),
          );
          return;
        }
      }
      print('fetchMasters bloc $lat $long');
      final result = await repository.fetchMasters(
        lat: lat,
        long: long,
        pageSize: event.pageSize,
      );
      if (result.errorText.isEmpty) {
        print('adress came here >>> $address');
        emit(
          MasterState(
            status: MasterStatus.success,
            masters: result.data,
            currentAddress: address,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: MasterStatus.failure,
            error: result.errorText,
            currentAddress: address,
          ),
        );
      }
    });
  }
}
