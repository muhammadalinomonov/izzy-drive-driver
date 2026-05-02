import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:taxi_app/src/features/map/data/model/nearby_masters_response.dart';
import 'package:taxi_app/src/features/map/domain/map_repo.dart';

import '../../data/model/search_locations_response.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final MapRepo mapRepo;

  MapBloc({required this.mapRepo}) : super(const MapState()) {
    on<FetchNearbyMechanicsEvent>(_onFetchNearbyMechanics);
    on<FetchNearbyLocationsEvent>(_onFetchNearbyLocations);
    on<PickerModeChangedEvent>(_onPickerModeChanged);
    on<LocationSelectedEvent>(_onLocationSelected);
  }

  Future<void> _onFetchNearbyMechanics(
    FetchNearbyMechanicsEvent event,
    Emitter<MapState> emit,
  ) async {
    emit(state.copyWith(mechanicsStatus: MapStatus.loading));
    final response = await mapRepo.getNearbyMechanics(
      latitude: event.latitude,
      longitude: event.longitude,
    );
    if (response.errorText.isEmpty && response.data != null) {
      final mechanics = response.data as NearbyMastersResponse;
      emit(state.copyWith(
        mechanicsStatus: MapStatus.success,
        nearbyMechanics: mechanics,
        // The `near-mechanics-km` response carries reverse-geocoded address
        // for the queried point — adopt it as the current selectedAddress.
        selectedAddress: mechanics.data.driverCurrentAddress.address,
        selectedLatitude: event.latitude,
        selectedLongitude: event.longitude,
      ));
    } else {
      emit(state.copyWith(
        mechanicsStatus: MapStatus.failure,
        errorMessage: response.errorText,
      ));
    }
  }

  Future<void> _onFetchNearbyLocations(
    FetchNearbyLocationsEvent event,
    Emitter<MapState> emit,
  ) async {
    emit(state.copyWith(locationsStatus: MapStatus.loading));
    final response = await mapRepo.getNearbyLocations(
      latitude: event.latitude,
      longitude: event.longitude,
      query: event.query,
    );
    if (response.errorText.isEmpty && response.data != null) {
      final locations = response.data as NearbyLocationsResponse;
      emit(state.copyWith(
        locationsStatus: MapStatus.success,
        suggestions: locations.data,
      ));
    } else {
      emit(state.copyWith(
        locationsStatus: MapStatus.failure,
        errorMessage: response.errorText,
      ));
    }
  }

  void _onPickerModeChanged(
    PickerModeChangedEvent event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(pickerMode: event.mode));
  }

  void _onLocationSelected(
    LocationSelectedEvent event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(
      selectedAddress: event.address,
      selectedLatitude: event.latitude,
      selectedLongitude: event.longitude,
      pickerMode: PickerMode.map,
    ));
  }
}
