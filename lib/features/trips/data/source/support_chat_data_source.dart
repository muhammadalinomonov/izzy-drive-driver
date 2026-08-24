import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:taxi_app/core/extensions/status_code_extension.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/core/network/toll_api_constants.dart';
import 'package:taxi_app/core/network/toll_dio.dart';
import 'package:taxi_app/core/network/toll_envelope.dart';
import 'package:taxi_app/core/network/toll_session.dart';
import 'package:taxi_app/core/service_locater.dart';
import 'package:taxi_app/core/utils/json_safe.dart';
import 'package:taxi_app/features/trips/data/model/support_chat_model.dart';
import 'package:taxi_app/features/trips/data/model/support_timeline_model.dart';

/// Normal support chat (docs/mobile-api.md §8.1/§8.2) plus the unified
/// timeline view that supersedes it as the driver's main screen
/// (docs/mobile-chat-complete-api-websocket.md §6) - both live on the same
/// `mobile/support-chat` resource, so one data source owns both.
@lazySingleton
class SupportChatDataSource {
  SupportChatDataSource();

  final client = serviceLocator.get<TollDioSettings>().dio;

  /// `GET mobile/support-chat?view=timeline` — the driver's single merged
  /// feed: plain messages and route-review cards, newest-first, discriminated
  /// by `type` (§6.1/§6.2). This is what the unified support screen loads;
  /// [fetchHistory] stays for the legacy message-only shape, which the
  /// backend keeps serving unchanged (§6.4).
  Future<NetworkResponse<SupportTimelinePage>> fetchTimeline({
    int page = 1,
    int perPage = 50,
  }) async {
    if (!TollSession.hasToken) {
      return NetworkResponse<SupportTimelinePage>(
        errorText: 'Toll account is not connected.',
        errorCode: 'TOLL_SESSION_MISSING',
      );
    }
    try {
      final response = await client.get(
        TollApiConstants.supportChat,
        queryParameters: {'view': 'timeline', 'page': page, 'per_page': perPage},
      );
      if (response.isSuccess) {
        final body = toMap(response.data);
        return NetworkResponse<SupportTimelinePage>(
          data: SupportTimelinePage.fromJson(
            toMap(body['data']),
            toMap(body['pagination']),
          ),
        );
      }
      return NetworkResponse<SupportTimelinePage>(
        errorText: tollErrorMessage(response.data),
        errorCode: tollErrorCode(response.data),
      );
    } on DioException catch (e) {
      return NetworkResponse<SupportTimelinePage>(
        errorText: tollErrorMessage(e.response?.data, 'Network error'),
        errorCode: tollErrorCode(e.response?.data),
      );
    } catch (e) {
      return NetworkResponse<SupportTimelinePage>(errorText: e.toString());
    }
  }

  /// `GET mobile/support-chat` — legacy message-only history, newest-first
  /// (§6.4). `data.conversation` is deliberately not parsed: nothing in this
  /// app's UI needs the conversation envelope, only the messages inside it.
  Future<NetworkResponse<SupportChatPage>> fetchHistory({
    int page = 1,
    int perPage = 50,
  }) async {
    if (!TollSession.hasToken) {
      return NetworkResponse<SupportChatPage>(
        errorText: 'Toll account is not connected.',
        errorCode: 'TOLL_SESSION_MISSING',
      );
    }
    try {
      final response = await client.get(
        TollApiConstants.supportChat,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      if (response.isSuccess) {
        final body = toMap(response.data);
        return NetworkResponse<SupportChatPage>(
          data: SupportChatPage.fromJson(
            toMap(body['data']),
            toMap(body['pagination']),
          ),
        );
      }
      return NetworkResponse<SupportChatPage>(
        errorText: tollErrorMessage(response.data),
        errorCode: tollErrorCode(response.data),
      );
    } on DioException catch (e) {
      return NetworkResponse<SupportChatPage>(
        errorText: tollErrorMessage(e.response?.data, 'Network error'),
        errorCode: tollErrorCode(e.response?.data),
      );
    } catch (e) {
      return NetworkResponse<SupportChatPage>(errorText: e.toString());
    }
  }

  /// `POST mobile/support-chat/messages` (§8.2). No idempotency key exists
  /// for this endpoint - per the doc, a timed-out send must not be blindly
  /// retried, so this method makes exactly one attempt and leaves the
  /// "check history first" reconciliation to the caller.
  Future<NetworkResponse<SupportChatMessage>> sendMessage(String message) async {
    if (!TollSession.hasToken) {
      return NetworkResponse<SupportChatMessage>(
        errorText: 'Toll account is not connected.',
        errorCode: 'TOLL_SESSION_MISSING',
      );
    }
    try {
      final response = await client.post(
        TollApiConstants.supportChatMessages,
        data: {'message': message},
      );
      if (response.isSuccess) {
        final data = toMap(toMap(response.data)['data']);
        return NetworkResponse<SupportChatMessage>(
          data: SupportChatMessage.fromJson(toMap(data['message'])),
        );
      }
      return NetworkResponse<SupportChatMessage>(
        errorText: tollErrorMessage(response.data),
        errorCode: tollErrorCode(response.data),
      );
    } on DioException catch (e) {
      return NetworkResponse<SupportChatMessage>(
        errorText: tollErrorMessage(e.response?.data, 'Network error'),
        errorCode: tollErrorCode(e.response?.data),
      );
    } catch (e) {
      return NetworkResponse<SupportChatMessage>(errorText: e.toString());
    }
  }
}
