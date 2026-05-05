import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/core/utils/json_safe.dart';
import 'package:taxi_app/src/features/common/data/models/generic_pagination.dart';
import 'package:taxi_app/src/features/order_proccess/data/model/current_order_model.dart';
import 'package:taxi_app/src/features/profile/data/model/order_history_model.dart';
import 'package:taxi_app/src/features/profile/data/model/output_model.dart';

import '../model/profile_model.dart';

class ProfileDataSource {
  ProfileDataSource();

  final client = serviceLocator.get<DioSettings>().dio;

  Future<NetworkResponse> fetchProfile() async {
    try {
      final token = StorageRepository.getString('token');
      final response = await client.get(
        ApiConstants.profileGet,
        options: Options(headers: {'Authorization': "Bearer $token"}),
      );
      if (response.isSuccess) {
        print('Profile fetched successfully: ${response.data}');
        return NetworkResponse(data: ProfileModel.fromJson(toMap(response.data['data'])));
      } else {
        print('Error fetching profile: ${response.data}');
        return NetworkResponse(errorText: dioErrorMessage(response.data, 'Something went wrong try again'));
      }
    } on DioException catch (e) {
      print('Dio exception fetching profile: ${e.response?.statusCode}');
      print('Dio exception response body: ${e.response?.data}');
      return NetworkResponse(errorText: dioErrorMessage(e.response?.data, 'Something went wrong'));
    } catch (e) {
      print('Error fetching profile: $e');
      return NetworkResponse(errorText: 'Something went wrong');
    }
  }

  Future<GenericPagination<OutPutModel>> getAllOutputs() async {
    try {
      final token = StorageRepository.getString('token');
      final response = await client.get(
        ApiConstants.getOutputs,
        options: Options(headers: {'Authorization': "Bearer $token"}),
      );

      if (response.isSuccess) {
        print('Outputs fetched successfully: ${response.data}');
        return GenericPagination<OutPutModel>.fromJson(toMap(response.data), (data) => OutPutModel.fromJson(toMap(data)));
      } else {
        print('Error fetching outputs: ${response.data}');
        throw Exception(dioErrorMessage(response.data, 'Something went wrong try again'));
      }
    } on DioException catch (e) {
      print('Dio exception fetching outputs: ${e.response?.statusCode}');
      print('Dio exception response body: ${e.response?.data}');
      throw Exception(dioErrorMessage(e.response?.data, 'Something went wrong'));
    } catch (e) {
      print('Error fetching outputs: $e');
      throw Exception('Something went wrong');
    }
  }

  Future<NetworkResponse> createOutput(Map<String, dynamic> outputData) async {
    try {
      final token = StorageRepository.getString('token');
      final response = await client.post(
        ApiConstants.createOutput,
        data: outputData,
        options: Options(headers: {'Authorization': "Bearer $token"}),
      );
      if (response.isSuccess) {
        print('Output created successfully: ${response.data}');
        return NetworkResponse(data: OutPutModel.fromJson(toMap(response.data['data'])));
      } else {
        print('Error creating output: ${response.data}');
        return NetworkResponse(errorText: dioErrorMessage(response.data, 'Something went wrong try again'));
      }
    } on DioException catch (e) {
      print('Dio exception creating output: ${e.response?.statusCode}');
      print('Dio exception response body: ${e.response?.data}');
      return NetworkResponse(errorText: dioErrorMessage(e.response?.data, 'Something went wrong'));
    } catch (e) {
      print('Error creating output: $e');
      return NetworkResponse(errorText: 'Something went wrong');
    }
  }

  Future<NetworkResponse> updatePassword(Map<String, dynamic> passwordData) async {
    final token = StorageRepository.getString('token');
    try {
      final response = await client.post(
        ApiConstants.updatePassword,
        data: passwordData,
        options: Options(headers: {'Authorization': "Bearer $token"}),
      );
      if (response.isSuccess) {
        print('Password updated successfully: ${response.data}');
        return NetworkResponse(data: response.data);
      } else {
        print('Error updating password: ${response.data}');
        return NetworkResponse(errorText: dioErrorMessage(response.data, 'Something went wrong'));
      }
    } on DioException catch (e) {
      print('Dio exception updating password: ${e.response?.statusCode}');

      print('Dio exception response body: ${e.response?.data}');

      return NetworkResponse(errorText: dioErrorMessage(e.response?.data, 'Something went wrong'));
    } catch (e) {
      print('Error updating password: $e');
      return NetworkResponse(errorText: 'Something went wrong');
    }
  }

  Future<GenericPagination<CurrentOrderModel>> getOrdersHistory({String? next}) async {
    try {
      final token = StorageRepository.getString('token');
      final response = await client.get(
        ApiConstants.ordersHistory,
        queryParameters: {'next': next},
        options: Options(headers: {'Authorization': "Bearer $token"}),
      );
      if (response.isSuccess) {
        print('Orders fetched successfully: ${response.data}');
        return GenericPagination<CurrentOrderModel>.fromJson(toMap(response.data), (data) => CurrentOrderModel.fromJson(toMap(data)));
      } else {
        print('Error fetching orders: ${response.data}');
        throw Exception(dioErrorMessage(response.data, 'Something went wrong try again'));
      }
    } on DioException catch (e) {
      print('Dio exception fetching orders: ${e.response?.statusCode}');
      print('Dio exception response body: ${e.response?.data}');
      throw Exception(dioErrorMessage(e.response?.data, 'Something went wrong'));
    } catch (e) {
      print('Error fetching orders: $e');
      throw Exception('Something went wrong');
    }
  }

  Future<OrderHistoryModel> getOrdersHistoryDetail({required int id}) async {
    try {
      final token = StorageRepository.getString('token');
      final response = await client.get(
        ApiConstants.ordersHistoryDetail,
        queryParameters: {'order_id': id},
        options: Options(headers: {'Authorization': "Bearer $token"}),
      );
      if (response.isSuccess) {
        print('Orders fetched successfully: ${response.data}');
        return OrderHistoryModel.fromJson(toMap(response.data['data']));
      } else {
        print('Error fetching orders: ${response.data}');
        throw Exception(dioErrorMessage(response.data, 'Something went wrong try again'));
      }
    } on DioException catch (e) {
      print('Dio exception fetching orders: ${e.response?.statusCode}');
      print('Dio exception response body: ${e.response?.data}');
      throw Exception(dioErrorMessage(e.response?.data, 'Something went wrong'));
    } catch (e) {
      print('Error fetching orders: $e');
      throw Exception('Something went wrong');
    }
  }
}
