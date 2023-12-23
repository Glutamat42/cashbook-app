import 'package:mobx/mobx.dart';
import 'auth_store.dart';

part 'app_store.g.dart';

class AppStore = _AppStore with _$AppStore;

abstract class _AppStore with Store {
// Any other application-wide state and actions can be added here
}
