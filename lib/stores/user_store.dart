import 'package:logging/logging.dart';
import 'package:mobx/mobx.dart';
import '../models/user.dart';
import '../repositories/users_repository.dart';
import '../services/locator.dart';

part 'user_store.g.dart';

class UserStore = _UserStore with _$UserStore;

abstract class _UserStore with Store {
  final Logger _logger = Logger('UserStore');
  final UsersRepository _usersRepository = locator<UsersRepository>();

  @observable
  ObservableList<User> users = ObservableList<User>();

  @action
  Future<void> loadUsers() async {
    try {
      final fetchedUsers = await _usersRepository.getUsers();
      users = ObservableList<User>.of(fetchedUsers);
    } catch (e) {
      _logger.severe('Failed to load users: $e');
    }
  }

  @action
  Future<void> onLogout() async {
    users.clear();
  }
}
