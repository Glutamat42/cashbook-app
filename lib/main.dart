import 'package:cashbook/config/app_config.dart';
import 'package:cashbook/screens/home_screen.dart';
import 'package:cashbook/services/locator.dart';
import 'package:cashbook/stores/auth_store.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'constants/route_names.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure plugin services are initialized
  await AppConfig.loadConfig(); // Load the configuration
  _setupLogging(AppConfig().logLevel);
  setupLocator();
  runApp(MyApp());
}

void _setupLogging(String level) {
  Level logLevel;
  bool invalidLevel = false;

  switch (level.toUpperCase()) {
    case 'ALL':
      logLevel = Level.ALL;
      break;
    case 'FINE':
      logLevel = Level.FINE;
      break;
    case 'INFO':
      logLevel = Level.INFO;
      break;
    case 'WARNING':
      logLevel = Level.WARNING;
      break;
    case 'SEVERE':
      logLevel = Level.SEVERE;
      break;
    case 'OFF':
      logLevel = Level.OFF;
      break;
    default:
      logLevel = Level.INFO; // Default level
      invalidLevel = true;
      break;
  }

  Logger.root.level = logLevel; // Set this level as per your need
  Logger.root.onRecord.listen((record) {
    final timestamp = record.time.toIso8601String();
    final logLevel = record.level.name.padRight(7); // "WARNING" has 7 characters
    final loggerName = record.loggerName;
    final message = record.message;

    // ignore: avoid_print
    print('$timestamp | $logLevel | $loggerName | $message');
  });

  if (invalidLevel) {
    Logger.root.warning('Invalid log level: $level. Defaulting to INFO.');
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final AuthStore _authStore = locator<AuthStore>();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    String initialRoute =
        _authStore.isLoggedIn ? RouteNames.homeScreen : RouteNames.loginScreen;

    return MaterialApp(
      title: 'Cashbook',
      initialRoute: initialRoute,
      scrollBehavior: AppScrollBehavior(),
      routes: {
        RouteNames.loginScreen: (context) => LoginScreen(),
        RouteNames.homeScreen: (context) => HomeScreen(),
        // Define other routes
      },
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}


class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}