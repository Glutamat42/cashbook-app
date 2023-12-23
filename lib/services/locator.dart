import 'package:cashbook/config/app_config.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../stores/auth_store.dart';
import '../repositories/auth_repository.dart';

GetIt locator = GetIt.instance;

void setupLocator() {
  Dio dio = Dio(BaseOptions(
      baseUrl: AppConfig().apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10)
  ));
  locator.registerLazySingleton(() => dio);
  locator.registerLazySingleton(() => AuthStore());
  locator.registerLazySingleton(() => AuthRepository(locator<Dio>()));
}
