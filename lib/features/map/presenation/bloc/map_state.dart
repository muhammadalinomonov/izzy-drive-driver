part of 'map_bloc.dart';

enum MapStatus { initial, loading, success, failure }

enum PickerMode { map, list }

@immutable
class MapState extends Equatable {
  final MapStatus mechanicsStatus;
  final MapStatus locationsStatus;
  final NearbyMastersResponse? nearbyMechanics;
  final List<LocationData> suggestions;
  final PickerMode pickerMode;
  final String selectedAddress;
  final double? selectedLatitude;
  final double? selectedLongitude;
  final String errorMessage;

  const MapState({
    this.mechanicsStatus = MapStatus.initial,
    this.locationsStatus = MapStatus.initial,
    this.nearbyMechanics,
    this.suggestions = const [],
    this.pickerMode = PickerMode.map,
    this.selectedAddress = '',
    this.selectedLatitude,
    this.selectedLongitude,
    this.errorMessage = '',
  });

  MapState copyWith({
    MapStatus? mechanicsStatus,
    MapStatus? locationsStatus,
    NearbyMastersResponse? nearbyMechanics,
    List<LocationData>? suggestions,
    PickerMode? pickerMode,
    String? selectedAddress,
    double? selectedLatitude,
    double? selectedLongitude,
    String? errorMessage,
  }) {
    return MapState(
      mechanicsStatus: mechanicsStatus ?? this.mechanicsStatus,
      locationsStatus: locationsStatus ?? this.locationsStatus,
      nearbyMechanics: nearbyMechanics ?? this.nearbyMechanics,
      suggestions: suggestions ?? this.suggestions,
      pickerMode: pickerMode ?? this.pickerMode,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      selectedLatitude: selectedLatitude ?? this.selectedLatitude,
      selectedLongitude: selectedLongitude ?? this.selectedLongitude,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    mechanicsStatus,
    locationsStatus,
    nearbyMechanics,
    suggestions,
    pickerMode,
    selectedAddress,
    selectedLatitude,
    selectedLongitude,
    errorMessage,
  ];
}