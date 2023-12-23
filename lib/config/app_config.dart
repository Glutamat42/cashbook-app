import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AppConfig {
  late final String apiBaseUrl;
  late final String logLevel;

  AppConfig._internal();

  static final AppConfig _instance = AppConfig._internal();

  factory AppConfig() => _instance;

  static Future<void> loadConfig() async {
    String jsonString = await rootBundle.loadString('assets/config.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _instance.apiBaseUrl = jsonMap['apiBaseUrl'];
    _instance.logLevel = jsonMap['logLevel'];
  }
}
