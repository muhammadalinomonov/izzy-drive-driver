import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/cancel_reasons/data/model/cancel_reason_model.dart';
import 'package:taxi_app/features/cancel_reasons/data/source/cancel_reason_data_source.dart';
import 'package:taxi_app/features/cancel_reasons/domain/repo/cancel_reason_repo.dart';

class CancelReasonRepoImpl extends CancelReasonRepo {
  final CancelReasonDataSource dataSource;

  CancelReasonRepoImpl({required this.dataSource});

  @override
  Future<NetworkResponse<List<CancelReasonModel>>> fetch({String audience = 'driver'}) {
    return dataSource.fetch(audience: audience);
  }
}
