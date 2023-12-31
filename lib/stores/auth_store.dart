import 'package:cashbook/stores/category_store.dart';
import 'package:cashbook/stores/entry_store.dart';
import 'package:cashbook/stores/user_store.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobx/mobx.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../services/locator.dart';

part 'auth_store.g.dart';

class AuthStore = _AuthStore with _$AuthStore;

abstract class _AuthStore with Store {
  final Logger _log = Logger('AuthStore');
  final AuthRepository _authRepository = locator<AuthRepository>();

  @observable
  bool isLoggedIn = false;

  @observable
  String? baseUrl;

  @observable
  User? user;

  late Future<void> loadAuthTokenFuture;

  _AuthStore() {
    loadAuthTokenFuture = _loadAuthToken();
  }

  @action
  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('authToken');
    int? userId = prefs.getInt('userId');
    String? username = prefs.getString('username');
    baseUrl = prefs.getString('baseUrl');

    if (authToken != null && userId != null && username != null && baseUrl != null && baseUrl!.isNotEmpty) {
      user = User(id: userId, username: username, token: authToken);

      // check if token is still valid
      try {
        // Dio baseUrl is not yet set as the reaction is not yet triggered
        await _authRepository.validateToken(baseUrl!);
      } catch (e) {
        _log.severe('Failed to validate token: $e');
        await logout();
      }
    } else {
      _log.severe('No valid login information found in shared preferences, logging out');
      await logout();
    }

    if (user != null) {
      _log.info(
          'Loaded user data from shared preferences for user ${user!.username} and token ${user!.token!.substring(0, 5)}... is valid');
      isLoggedIn = true;
    } else {
      isLoggedIn = false;
    }
  }

  @action
  Future<void> login(String username, String password, String server) async {
    try {
      User user = await _authRepository.login(username, password, server);

      isLoggedIn = user.token != null;
      if (isLoggedIn) {
        this.user = user;
        baseUrl = server;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', user.token!);
        await prefs.setInt('userId', user.id);
        await prefs.setString('username', user.username);
        await prefs.setString('baseUrl', baseUrl!);
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

    locator<CategoryStore>().onLogout();
    locator<EntryStore>().onLogout();
    locator<UserStore>().onLogout();
  }
}
