import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/features/home/presentation/widgets/location_row_item.dart';
import 'package:taxi_app/src/features/home/presentation/widgets/search_input.dart';
import 'package:taxi_app/src/features/map/presenation/bloc/map_bloc.dart';
import 'package:taxi_app/src/routes/pages.dart';
import 'package:taxi_app/src/utils/local.dart';

class SearchLocationScreen extends StatefulWidget {
  const SearchLocationScreen({super.key});

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardDismisser(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            children: [
              SizedBox(height: context.padding.top),
              Row(
                children: [
                  IconButton(onPressed: () => context.pop(), icon: Icon(Icons.arrow_back)),
                  SizedBox(width: 4),
                  Expanded(
                    child: SearchInputWidget(
                      onChanged: (value) {
                        context.read<MapBloc>().add(FetchNearbyLocationsEvent(query: value, latitude: 0, longitude: 0));
                      },
                      hint: 'Usta qayerga borsin ?',
                      textInputAction: TextInputAction.search,
                      suffix: GestureDetector(
                        onTap: () {
                          context.pushReplacement(Pages.map);
                        },
                        child: Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.map_outlined)),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                ],
              ),
              SizedBox(height: 24),
              BlocBuilder<MapBloc, MapState>(
                builder: (context, state) {
                  if (state is LocationsSuccess) {
                    return Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) => LocationRowItem(
                          title: state.nearbyLocations.data[index].formatted,
                          onTap: () {
                            currentAddress = state.nearbyLocations.data[index].formatted;
                            currentLocation = Position(
                              state.nearbyLocations.data[index].lat,
                              state.nearbyLocations.data[index].lon,
                            );
                            context.push(Pages.chat);
                          },
                        ),
                        separatorBuilder: (context, index) => Divider(indent: 46, color: AppColor.lightBlue),
                        itemCount: state.nearbyLocations.data.length,
                      ),
                    );
                  }
                  if (state is MapLoading) {
                    return Expanded(child: Center(child: CircularProgressIndicator.adaptive()));
                  }
                  return SizedBox();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
