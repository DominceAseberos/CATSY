// Custom exception hierarchy for data-layer errors.
//
// These are thrown by remote/local data sources and caught by repositories,
// which then convert them into Failure objects for the presentation layer.

class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'No internet connection'});

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;

  const AuthException({required this.message});

  @override
  String toString() => 'AuthException: $message';
}

class SyncException implements Exception {
  final String message;
  final String? entityId;

  const SyncException({required this.message, this.entityId});

  @override
  String toString() => 'SyncException($entityId): $message';
}
