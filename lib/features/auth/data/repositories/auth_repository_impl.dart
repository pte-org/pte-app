import 'package:dio/dio.dart';
import 'package:aptis_app/core/network/api_exceptions.dart';
import 'package:aptis_app/core/network/token_store.dart';
import 'package:aptis_app/features/auth/data/models/auth_response_model.dart';
import 'package:aptis_app/features/auth/domain/entities/auth_session.dart';
import 'package:aptis_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final TokenStore _tokenStore;

  const AuthRepositoryImpl({required Dio dio, required TokenStore tokenStore})
    : _dio = dio,
      _tokenStore = tokenStore;

  @override
  Future<AuthSession> login({
    required String credential,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'credential': credential, 'password': password},
      );
      final session = AuthResponseModel.fromJson(response.data!).toEntity();
      if (session.isStudent) {
        await _tokenStore.saveTokens(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        );
      }
      return session;
    } on DioException catch (error) {
      throw mapDioExceptionToApiException(error);
    }
  }
}
