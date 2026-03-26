import 'package:catsy_pos/core/network/api_client.dart';

/// Response model for API Bridge login.
class AuthTokenResponse {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;

  AuthTokenResponse({
    required this.accessToken,
    this.refreshToken,
    required this.tokenType,
  });

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) =>
      AuthTokenResponse(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String?,
        tokenType: json['token_type'] as String? ?? 'bearer',
      );
}

/// Remote data source for authentication against the API Bridge.
class AuthRemoteSource {
  final ApiClient _api;

  AuthRemoteSource(this._api);

  Future<AuthTokenResponse> login(String email, String password) async {
    final data =
        await _api.post(
              '/admin/login',
              {'email': email, 'password': password},
              auth: false,
            )
            as Map<String, dynamic>;
    return AuthTokenResponse.fromJson(data);
  }

  Future<void> logout() async {
    try {
      await _api.post('/admin/logout', {});
    } catch (_) {
    }
  }
}
