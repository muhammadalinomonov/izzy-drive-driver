import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/cancel_reasons/data/model/cancel_reason_model.dart';

abstract class CancelReasonRepo {
  Future<NetworkResponse<List<CancelReasonModel>>> fetch({String audience = 'driver'});
}
