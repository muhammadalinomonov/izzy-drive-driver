import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:taxi_app/src/features/map/domain/map_repo.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/features/map/data/model/nearby_masters_response.dart';

import '../../data/model/search_locations_response.dart';

part 'map_event.dart';

part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final MapRepo mapRepo;

  MapBloc({required this.mapRepo}) : super(MapInitial()) {
    on<FetchNearbyMechanicsEvent>((event, emit) async {
      emit(MapLoading());
      final response = await mapRepo.getNearbyMechanics(latitude: event.latitude, longitude: event.longitude);
      if (response.errorText.isEmpty && response.data != null) {
        emit(MapSuccess(nearbyMechanics: response.data as NearbyMastersResponse));
      } else {
        emit(MapFailure(errorMessage: response.errorText));
      }
    });

    on<FetchNearbyLocationsEvent>((event, emit) async {
      emit(MapLoading());
      final response = await mapRepo.getNearbyLocations(
        latitude: event.latitude,
        longitude: event.longitude,
        query: event.query,
      );
      if (response.errorText.isEmpty && response.data != null) {
        emit(LocationsSuccess(nearbyLocations: response.data as NearbyLocationsResponse));
      } else {
        emit(MapFailure(errorMessage: response.errorText));
      }
    });
  }
}
