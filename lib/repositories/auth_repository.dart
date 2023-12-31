import 'package:cashbook/models/user.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  final Dio dio;

  AuthRepository(this.dio);

  Future<User> login(String username, String password, server) async {
    dio.options.baseUrl = server;
    final response = await dio.post(
      '/api/login',
      data: {'username': username, 'password': password},
    );
    User user = User.fromJson(response.data);
    return user;
  }

  Future<void> validateToken(String baseUrl) async {
    dio.options.baseUrl = baseUrl;
    await dio.get('/api/token/validate');
  }
}
