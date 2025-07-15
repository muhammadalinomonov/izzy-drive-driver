import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:taxi_app/src/features/chat/data/model/report_response.dart';

Position currentLocation = Position(0, 0);
String currentAddress = '';
ReportResponse? currentReportResponse;