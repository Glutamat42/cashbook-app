import 'package:cashbook/config/app_config.dart';
import 'package:cashbook/repositories/categories_repository.dart';
import 'package:cashbook/repositories/documents_repository.dart';
import 'package:cashbook/repositories/entries_repository.dart';
import 'package:cashbook/repositories/users_repository.dart';
import 'package:cashbook/stores/user_store.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:mobx/mobx.dart';
import '../stores/auth_store.dart';
import '../stores/entry_store.dart';
import '../stores/category_store.dart';
import '../repositories/auth_repository.dart';

GetIt locator = GetIt.instance;

void setupLocator() {
  Dio dio = Dio(BaseOptions(
      baseUrl: "http://localhost:8080",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10)));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      // Skip adding token for login requests
      if (!options.path.endsWith('/api/login')) {
        final authStore = locator<AuthStore>();
        final apiToken = authStore.user?.token;
        if (apiToken != null) {
          options.headers['Authorization'] = apiToken;
        }
      }
      return handler.next(options); // Continue with the request
    },
    // Add onResponse and onError handlers if needed
  ));

  locator.registerLazySingleton(() => dio);

  locator.registerLazySingleton(() => AuthStore());
  locator.registerLazySingleton(() => EntryStore());
  locator.registerLazySingleton(() => CategoryStore());
  locator.registerLazySingleton(() => UserStore());

  locator.registerLazySingleton(() => AuthRepository(locator<Dio>()));
  locator.registerLazySingleton(() => EntriesRepository(locator<Dio>()));
  locator.registerLazySingleton(() => CategoriesRepository(locator<Dio>()));
  locator.registerLazySingleton(() => UsersRepository(locator<Dio>()));
  locator.registerLazySingleton(() => DocumentsRepository(locator<Dio>()));

  // Create a reaction to update Dio's base URL when AuthStore's baseUrl changes
  reaction(
    (_) => locator<AuthStore>().baseUrl, // React to changes in baseUrl
    (String? newBaseUrl) {
      if (newBaseUrl != null && newBaseUrl.isNotEmpty) {
        locator<Dio>().options.baseUrl = newBaseUrl;
      }
    },
  );
}
