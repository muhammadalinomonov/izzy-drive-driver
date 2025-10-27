import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String? errorMessage;
  final String? errorKey;

  const Failure({this.errorMessage, this.errorKey});

  @override
  List<Object?> get props => [errorMessage, errorKey];
}

class ServerFailure extends Failure {
  final num? statusCode;

  const ServerFailure({this.statusCode, super.errorMessage, super.errorKey});

  @override
  String toString() {
    return 'ServerFailure(statusCode: $statusCode, errorMessage: $errorMessage)';
  }
}

class ParsingFailure extends Failure {
  const ParsingFailure({super.errorMessage, super.errorKey});
}

class DioFailure extends Failure {
  const DioFailure({super.errorMessage, super.errorKey});
}
