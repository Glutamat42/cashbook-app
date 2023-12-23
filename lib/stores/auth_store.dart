import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobx/mobx.dart';
import '../repositories/auth_repository.dart';
import '../services/locator.dart';

part 'auth_store.g.dart';

class AuthStore = _AuthStore with _$AuthStore;

abstract class _AuthStore with Store {
  final AuthRepository _authRepository = locator<AuthRepository>();

  @observable
  bool isLoggedIn = false;

  @observable
  String? authToken;

  _AuthStore() {
    _loadAuthToken();
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('authToken');
    isLoggedIn = authToken != null && authToken!.isNotEmpty;

  //   TODO: validate token still valid
  }

  @action
  Future<void> login(String username, String password) async {
    try {
      authToken = await _authRepository.login(username, password);
      isLoggedIn = authToken != null;
      if (isLoggedIn) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', authToken!);
      }
    } catch (e) {
      // Handle error, e.g., show an error message
      isLoggedIn = false;
      authToken = null;
      throw e; // Re-throw the error
    }
  }

  @action
  Future<void> logout() async {
    isLoggedIn = false;
    authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    // Clear stored token and any other cleanup
  }
}
