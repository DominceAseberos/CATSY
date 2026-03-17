import 'package:equatable/equatable.dart';

/// Sealed failure hierarchy for the domain/presentation layers.
///
/// Repositories return `Either<Failure, T>` so that the UI can pattern-match
/// on the failure type and display an appropriate message.
sealed class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({required super.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection'});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

class SyncFailure extends Failure {
  final String? entityId;

  const SyncFailure({required super.message, this.entityId});

  @override
  List<Object?> get props => [message, entityId];
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({required super.message, this.fieldErrors});

  @override
  List<Object?> get props => [message, fieldErrors];
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.message = 'An unexpected error occurred'});
}
