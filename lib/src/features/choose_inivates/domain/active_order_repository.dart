
// File: lib/src/features/active_order/domain/repo/active_order_repository.dart

import '../../../core/network/network_response.dart';

abstract class ActiveOrderRepository {
Future<NetworkResponse> fetchActiveOrder();
}
