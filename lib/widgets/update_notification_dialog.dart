import 'package:cashbook/services/locator.dart';
import 'package:cashbook/stores/options_store.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateNotificationDialog extends StatelessWidget {
  final OptionsStore _optionsStore = locator<OptionsStore>();

  UpdateNotificationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Available'),
      content: const SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text('A new version of the app is available.'),
            SizedBox(height: 10),
            Text('It is recommended to update as soon as possible.'),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Later'),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
        TextButton(
          child: const Text('Download'),
          onPressed: () {
            // Assuming _optionsStore.latestVersionInfo['apkUrl'] contains the URL
            launchUrl(Uri.parse(_optionsStore.latestVersionInfo!['assetUrl']!));
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
      ],
    );
  }
}
