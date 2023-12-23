import 'package:dio/dio.dart';
import '../models/user.dart';

class UsersRepository {
  final Dio dio;

  UsersRepository(this.dio);

  Future<List<User>> getUsers() async {
    try {
      final response = await dio.get('/api/users');
      return (response.data as List).map((json) => User.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load users: ${e.message}');
    } on Exception catch (e) {
      throw Exception('Failed to load users: ${e.toString()}');
    }
  }
}
