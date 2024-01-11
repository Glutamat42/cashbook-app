import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:mobx/mobx.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

part 'options_store.g.dart';

class OptionsStore = _OptionsStore with _$OptionsStore;

enum UpdateNotificationStatus { noUpdate, notify, alreadyNotified }

abstract class _OptionsStore with Store {
  final Logger _log = Logger('_OptionsStore');

  @observable
  String? currentAppVersion;

  @observable
  String? currentAppBuildNumber;

  @observable
  Map<String, String>? latestVersionInfo;

  @observable
  bool isUpdateAvailable = false;

  @observable
  UpdateNotificationStatus notifyUpdateAvailable = UpdateNotificationStatus.noUpdate;

  @action
  void _checkUpdateAvailable() {
    if (latestVersionInfo == null) {
      _log.fine('No latest version info available');
      isUpdateAvailable = false;
      return;
    }

    final latestVersion = latestVersionInfo!['latestVersion'];
    if (latestVersion == null) {
      _log.fine('No latest version available');
      isUpdateAvailable = false;
    } else {
      bool updateAvail = _isNewerVersion(currentAppVersion!, latestVersion);
      _log.info('Update available: $updateAvail');
      if (updateAvail) {
        notifyUpdateAvailable = UpdateNotificationStatus.notify;
        isUpdateAvailable = true;
      }
    }
  }

  @action
  Future<void> loadAppVersion() async {
    WidgetsFlutterBinding.ensureInitialized();

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    currentAppVersion = packageInfo.version;
    currentAppBuildNumber = packageInfo.buildNumber;
    _log.info('Current app version: $currentAppVersion+$currentAppBuildNumber');

    // update check only if: is release mode, not web, and on windows or android
    if (kReleaseMode && !kIsWeb && (Platform.isWindows || Platform.isAndroid)) {
      await _loadLatestAppVersion("Glutamat42", "cashbook-app");
      _checkUpdateAvailable();
    }
  }

  @action
  Future<void> _loadLatestAppVersion(String repoOwner, String repoName) async {
    final url = 'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';

    try {
      final response = await Dio().get(url);

      if (response.statusCode == 200) {
        dynamic asset;
        if (Platform.isAndroid) {
          asset = response.data['assets']
              .where((dynamic asset) => asset['content_type'] == "application/vnd.android.package-archive")
              .toList()[0];
        } else if (Platform.isWindows) {
          asset = response.data['assets']
              .where((dynamic asset) => asset['name'].toString().toLowerCase().contains("windows"))
              .toList()[0];
        } else {
          throw Exception('Updater: Unsupported platform');
        }

        latestVersionInfo = {
          'latestVersion': response.data['tag_name'],
          'githubReleaseUrl': response.data['html_url'],
          'createdAt': response.data['created_at'],
          'publishedAt': response.data['published_at'],
          'body': response.data['body'],
          'assetUrl': asset['browser_download_url'],
        };
        _log.info('Latest version info: ${latestVersionInfo?["latestVersion"]}');
      } else {
        _log.warning('Failed to fetch release data: ${response.statusCode}');
      }
    } catch (e) {
      _log.warning('Error checking for updates: $e');
    }
  }

  bool _isNewerVersion(String currentVersion, String latestVersion) {
    try {
      final current = Version.parse(currentVersion);
      final latest = Version.parse(latestVersion);
      return latest > current;
    } catch (e) {
      _log.warning('Error comparing version: $e');
      return false;
    }
  }
}
