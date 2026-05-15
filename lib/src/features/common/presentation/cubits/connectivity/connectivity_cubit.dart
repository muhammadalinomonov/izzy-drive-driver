import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/src/core/services/connectivity_service.dart';

enum ConnectivityStatus { connected, disconnected }

class ConnectivityState extends Equatable {
  final ConnectivityStatus status;
  const ConnectivityState({this.status = ConnectivityStatus.connected});

  bool get isConnected => status == ConnectivityStatus.connected;
  bool get isDisconnected => status == ConnectivityStatus.disconnected;

  @override
  List<Object?> get props => [status];
}

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final ConnectivityService _service;
  StreamSubscription<bool>? _sub;

  ConnectivityCubit(this._service)
      : super(ConnectivityState(
          status: _service.isOnline
              ? ConnectivityStatus.connected
              : ConnectivityStatus.disconnected,
        )) {
    _sub = _service.onlineStream.listen((isOnline) {
      emit(ConnectivityState(
        status: isOnline
            ? ConnectivityStatus.connected
            : ConnectivityStatus.disconnected,
      ));
    });
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
