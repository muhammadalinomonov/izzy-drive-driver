import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:taxi_app/core/extensions/status_code_extension.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/core/network/toll_api_constants.dart';
import 'package:taxi_app/core/network/toll_dio.dart';
import 'package:taxi_app/core/network/toll_session.dart';
import 'package:taxi_app/core/service_locater.dart';
import 'package:taxi_app/core/utils/json_safe.dart';
import 'package:taxi_app/features/trips/data/model/support_chat_model.dart';

/// Normal support chat (docs/mobile-api.md §8.1/§8.2) - the one conversation
/// shared by every "Support Message" entry point in the app. Not yet live per
/// that doc's own callout; this source is written against its exact
/// specification so nothing here needs to change once the backend catches up.
@lazySingleton
class SupportChatDataSource {
  SupportChatDataSource();

  final client = serviceLocator.get<TollDioSettings>().dio;

  /// `GET mobile/support-chat` — newest-first (§8.1). `data.conversation` is
  /// deliberately not parsed: nothing in this app's UI needs the conversation
  /// envelope, only the messages inside it.
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
        errorText: _errorMessage(response.data),
        errorCode: _errorCode(response.data),
      );
    } on DioException catch (e) {
      return NetworkResponse<SupportChatPage>(
        errorText: _errorMessage(e.response?.data, 'Network error'),
        errorCode: _errorCode(e.response?.data),
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
        errorText: _errorMessage(response.data),
        errorCode: _errorCode(response.data),
      );
    } on DioException catch (e) {
      return NetworkResponse<SupportChatMessage>(
        errorText: _errorMessage(e.response?.data, 'Network error'),
        errorCode: _errorCode(e.response?.data),
      );
    } catch (e) {
      return NetworkResponse<SupportChatMessage>(errorText: e.toString());
    }
  }

  /// Same nested-`error` envelope every toll-API source parses.
  static String _errorMessage(dynamic body, [String fallback = 'Server error']) {
    if (body is Map) {
      final error = body['error'];
      if (error is Map) {
        final message = error['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    }
    return dioErrorMessage(body, fallback);
  }

  static String? _errorCode(dynamic body) {
    if (body is! Map) return null;
    final error = body['error'];
    if (error is! Map) return null;
    final code = error['code'];
    return code is String && code.isNotEmpty ? code : null;
  }
}
