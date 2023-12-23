import 'package:dio/dio.dart';

class AuthRepository {
  final Dio dio;

  AuthRepository(this.dio);

  Future<String> login(String username, String password) async {
    try {
      final response = await dio.post(
        '/api/login',
        data: {'username': username, 'password': password},
      );
      // Assuming the token is returned in response data
      return response.data['token'];
    } on DioException catch (e) {
      // Handle Dio errors here (e.g., network errors, invalid response)
      throw Exception('Failed to login: ${e.message}');
    }
  }

// Additional methods for other authentication-related operations can be added here
}
