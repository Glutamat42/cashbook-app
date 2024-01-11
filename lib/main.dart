import 'dart:io';

import 'package:cashbook/config/app_config.dart';
import 'package:cashbook/models/local_document.dart';
import 'package:cashbook/screens/home_screen.dart';
import 'package:cashbook/services/locator.dart';
import 'package:cashbook/stores/auth_store.dart';
import 'package:cashbook/stores/entry_store.dart';
import 'package:cashbook/stores/options_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'constants/route_names.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure plugin services are initialized
  await AppConfig.loadConfig(); // Load the configuration
  _setupLogging(AppConfig().logLevel);
  setupLocator();
  final AuthStore authStore = locator<AuthStore>();
  await authStore.loadAuthTokenFuture;
  runApp(const MyApp());
}

void _setupLogging(String level) async {
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

  Logger.root.level = logLevel;

  final File? file = await _localFile;
  Logger.root.onRecord.listen((record) async {
    final timestamp = record.time.toIso8601String();
    final logLevel = record.level.name.padRight(7); // "WARNING" has 7 characters
    final loggerName = record.loggerName;
    final message = record.message;

    final logMessage = '$timestamp | $logLevel | $loggerName | $message';

    // Print log to console
    // ignore: avoid_print
    print(logMessage);

    // Write log to file
    if (!kIsWeb) {
      await file!.writeAsString("$logMessage\n", mode: FileMode.append);
    }
  });

  if (file != null) {
    Logger.root.info('Logging to file: ${file.path}');
  }

  if (invalidLevel) {
    Logger.root.warning('Invalid log level: $level. Defaulting to INFO.');
  }
}

Future<File?> get _localFile async {
  if (kIsWeb) {
    return null;
  } else if (Platform.isAndroid || Platform.isIOS || Platform.isWindows) {
    // TODO: logrotate
    final directory = await getApplicationDocumentsDirectory();
    // create subdirectory dev.markus_heck.cashbook if it does not exist
    final subDirectory = Directory('${directory.path}/dev.markus_heck.cashbook');
    if (!subDirectory.existsSync()) {
      subDirectory.createSync();
    }
    return File('${subDirectory.path}/app_logs.txt');
  } else {
    throw UnsupportedError('This platform is not supported for file logging');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Logger _log = Logger('MyApp');

  final AuthStore _authStore = locator<AuthStore>();
  final EntryStore _entryStore = locator<EntryStore>();
  final OptionsStore _optionsStore = locator<OptionsStore>();
  late final Future<void> loadUpdateInfoFuture;

  List<SharedFile>? list;

  @override
  void initState() {
    super.initState();

    loadUpdateInfoFuture = _optionsStore.loadAppVersion();

    // Implementation of intention is not perfect here as it relies on that the files are loaded before the user opens
    // the details page of an entry. Usually that should work fine as the user will at least need a few seconds to
    // open the details page. This should be sufficient to load the files from the intent.

    // For sharing images coming from outside the app while the app is in the memory
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // kisweb check is required as Platform is not available on web
      FlutterSharingIntent.instance.getMediaStream().listen((List<SharedFile> value) {
        _log.info("Shared: getMediaStream ${value.map((f) => f.value).join(",")}");
        for (var sharedFile in value) {
          _entryStore.intentDocuments ??= <LocalDocument>[];
          File file = File(sharedFile.value!);
          _entryStore.intentDocuments!.add(LocalDocument(
            originalFilename: sharedFile.value!.split("/").last,
            fileBytes: file.readAsBytesSync(),
          ));
        }
      }, onError: (err) {
        _log.warning("getIntentDataStream error: $err");
      });

      // For sharing images coming from outside the app while the app is closed
      FlutterSharingIntent.instance.getInitialSharing().then((List<SharedFile> value) {
        _log.info("Shared: getInitialMedia ${value.map((f) => f.value).join(",")}");
        for (var sharedFile in value) {
          _entryStore.intentDocuments ??= <LocalDocument>[];
          File file = File(sharedFile.value!);
          _entryStore.intentDocuments!.add(LocalDocument(
            originalFilename: sharedFile.value!.split("/").last,
            fileBytes: file.readAsBytesSync(),
          ));
        }
      });
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    String initialRoute = _authStore.isLoggedIn ? RouteNames.homeScreen : RouteNames.loginScreen;
    _log.info('Initial route: $initialRoute');

    return MaterialApp(
      title: 'Cashbook',
      initialRoute: initialRoute,
      scrollBehavior: AppScrollBehavior(),
      routes: {
        RouteNames.loginScreen: (context) => const LoginScreen(),
        RouteNames.homeScreen: (context) => const HomeScreen(),
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
