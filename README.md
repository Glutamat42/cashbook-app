# cashbook

# Install
## Windows
requires [Microsoft Visual C++ Redistributable packages for Visual Studio 2015, 2017, 2019, and 2022 (vc_redist.x64.exe)](https://aka.ms/vs/17/release/vc_redist.x64.exe)


generate mobx files: flutter packages pub run build_runner build --delete-conflicting-outputs

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---


# todolist

- allow users to select compression level (maybe: source, 4k (8MP), WQHD (3.6MP), FHD (2MP))
- multi language (i18n)
- csv import
- maybe fix image rotation on avif compression with regular camera (https://stackoverflow.com/questions/60176001/how-to-fix-wrong-rotation-of-photo-from-camera-in-flutter)
- Bug: Windows create entry with document -> directly after creation shown as document mission on home screen.
- Bug: Windows change date with text input field: failed to update entry

- switch lumen to laravel
  - improve auth


known bugs:
- filter, then sort -> filter is not applied anymore
- create entry, first set amount, then "income" -> amount is not set
- Some apple images cannot be uploaded
