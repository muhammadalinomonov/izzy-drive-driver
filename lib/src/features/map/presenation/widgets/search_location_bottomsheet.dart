import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../../../../core/constants/color/app_icons.dart';
import '../../data/model/search_locations_response.dart';
import '../bloc/map_bloc.dart';

void showAddressBottomSheet(
  BuildContext context,
  mapbox.Position position, {
  required Function(LocationData) onSelected, // Add onSelected callback
  required Function() getMyLocation, // Add onSelected callback
}) {
  TextEditingController searchController = TextEditingController();
  String query = '';

  // Get the MapBloc instance from the provided context
  final mapBloc = context.read<MapBloc>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (dialogContext) => BlocProvider.value(
      value: mapBloc, // Pass the existing MapBloc instance
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                width: double.infinity,
                decoration: ShapeDecoration(
                  color: const Color(0xFFEFF2F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(AppIcons.truck),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search address...',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.30,
                        ),
                        onChanged: (value) {
                          query = value;
                          context.read<MapBloc>().add(
                            FetchNearbyLocationsEvent(
                              latitude: position.lat.toDouble(),
                              longitude: position.lng.toDouble(),
                              query: value.isEmpty ? null : value,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              MaterialButton(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    color: const Color(0xFFE2E7EB),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                minWidth: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: () {
                  getMyLocation(); // Call the getMyLocation function
                  Navigator.pop(dialogContext);

                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 12,
                  children: [
                    Icon(
                      Icons.my_location,
                      color: const Color(0xFF0866FF),
                      size: 20,
                    ),
                    Text(
                      'Mening joylashuvim',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.30,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<MapBloc, MapState>(
                  builder: (context, state) {
                    if (state is MapLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is LocationsSuccess) {
                      final locations = state.nearbyLocations.data;
                      if (locations.isEmpty) {
                        return const Center(child: Text('No locations found'));
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: locations.length,
                        itemBuilder: (context, index) {
                          return _buildAddressTile(
                            locations[index],
                            dialogContext,
                            onSelected, // Pass onSelected callback
                          );
                        },
                      );
                    } else if (state is MapFailure) {
                      return Center(child: Text('Kalit so`z xato kiritildi'));
                    }
                    return const Center(child: Text('Enter a search query'));
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildAddressTile(
  LocationData location,
  BuildContext dialogContext,
  Function(LocationData) onSelected,
) {
  return ListTile(
    leading: Container(
      width: 18,
      height: 18,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: const ShapeDecoration(
                color: Color(0xFFE0EFFF),
                shape: OvalBorder(),
              ),
            ),
          ),
          Positioned(
            left: 3,
            top: 3,
            child: Container(
              width: 12,
              height: 12,
              decoration: const ShapeDecoration(
                color: Color(0xFF0866FF),
                shape: OvalBorder(),
              ),
            ),
          ),
        ],
      ),
    ),
    title: Text(
      location.formatted,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        letterSpacing: -0.30,
      ),
    ),
    onTap: () {
      // Call the onSelected callback with the selected location and close the bottom sheet
      onSelected(location);
      Navigator.pop(dialogContext);
    },
  );
}
