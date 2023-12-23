import 'package:cashbook/models/user.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  final Dio dio;

  AuthRepository(this.dio);

  Future<User> login(String username, String password) async {
    try {
      final response = await dio.post(
        '/api/login',
        data: {'username': username, 'password': password},
      );
      User user = User.fromJson(response.data);
      return user;
    } on DioException catch (e) {
      throw Exception('Failed to load categories: ${e.message}');
    } on Exception catch (e) {
      throw Exception('Failed to load categories: ${e.toString()}');
    }
  }
}
