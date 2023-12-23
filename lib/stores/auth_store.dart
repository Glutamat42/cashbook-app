import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobx/mobx.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../services/locator.dart';

part 'auth_store.g.dart';

class AuthStore = _AuthStore with _$AuthStore;

abstract class _AuthStore with Store {
  final AuthRepository _authRepository = locator<AuthRepository>();

  @observable
  bool isLoggedIn = false;

  @observable
  User? user;

  _AuthStore() {
    _loadAuthToken();
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('authToken');
    int? userId = prefs.getInt('userId');
    String? username = prefs.getString('username');

    if (authToken != null && userId != null && username != null) {
      user = User(id: userId, username: username);
    }

    isLoggedIn = authToken != null && authToken!.isNotEmpty;

  //   TODO: validate token still valid
  }

  @action
  Future<void> login(String username, String password) async {
    try {
      User user = await _authRepository.login(username, password);

      isLoggedIn = user.token != null;
      if (isLoggedIn) {
        this.user = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', user.token!);
        await prefs.setInt('userId', user.id);
        await prefs.setString('username', user.username);
      }
    } catch (e) {
      isLoggedIn = false;
      user = null;
      rethrow; // Re-throw the error
    }
  }

  @action
  Future<void> logout() async {
    isLoggedIn = false;
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userId');
    await prefs.remove('username');
  }
}
