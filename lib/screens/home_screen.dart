import 'dart:io';

import 'package:cashbook/stores/options_store.dart';
import 'package:cashbook/widgets/sorting_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/entry.dart';
import '../stores/category_store.dart';
import '../stores/user_store.dart';
import '../widgets/entry_item.dart';
import '../stores/entry_store.dart';
import '../stores/auth_store.dart';
import '../services/locator.dart';
import '../constants/route_names.dart';
import '../widgets/filter_dialog.dart';
import 'details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthStore _authStore = locator<AuthStore>();
  final EntryStore _entryStore = locator<EntryStore>();
  final CategoryStore _categoryStore = locator<CategoryStore>();
  final UserStore _userStore = locator<UserStore>();
  final OptionsStore _optionsStore = locator<OptionsStore>();
  final Logger _log = Logger('_HomeScreenState');
  bool _isSearchVisible = false;

  @override
  void initState() {
    _entryStore.loadEntries();
    _categoryStore.loadCategories();
    _userStore.loadUsers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!_authStore.isLoggedIn) {
      // TODO: login page is pushed two times, no idea why, but this is sufficient for now as this should not happen often
      _log.info('User is not logged in. Redirecting to login screen.');
      Future.microtask(() => Navigator.of(context).pushReplacementNamed(RouteNames.loginScreen));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              _showSortingDialog();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToNewEntry,
        child: const Icon(Icons.add),
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: <Widget>[
          _isSearchVisible ? _buildSearchBar() : Container(),
          _buildFilterInfoBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: Observer(
                builder: (_) => ListView.builder(
                  itemCount: _entryStore.visibleEntries.length + 1,
                  // +1 for the sort criteria bar
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildSortCriteriaBar(); // Sort criteria at the top
                    }
                    final entry = _entryStore.visibleEntries[index - 1];
                    return EntryItem(entry: entry);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToNewEntry() {
    // Navigate to DetailsScreen with a new Entry object
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => DetailsScreen(entry: Entry(date: DateTime.now())),
    ));
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            // Wrap ListView with Expanded
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                UserAccountsDrawerHeader(
                  accountName: Text(_authStore.user?.username ?? 'User'),
                  accountEmail: const Text(''),
                ),
                (!kIsWeb && Platform.isAndroid)
                    ? Observer(
                        builder: (_) => _optionsStore.isUpdateAvailable
                            ? ListTile(
                                textColor: Colors.red,
                                iconColor: Colors.red,
                                leading: const Icon(Icons.system_update),
                                title: const Text('Update Available'),
                                onTap: () {
                                  // Download the latest APK
                                  launchUrl(Uri.parse(_optionsStore.latestVersionInfo!['assetUrl']!));
                                },
                              )
                            : const SizedBox.shrink(),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              _authStore.logout();
              Navigator.of(context).pushReplacementNamed(RouteNames.loginScreen);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Licenses'),
            onTap: () {
              showLicensePage(context: context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Markus Heck @Github'),
            onTap: () {
              // Open the GitHub releases page
              launchUrl(Uri.parse('https://github.com/Glutamat42/'));
            },
          ),
          Observer(
            builder: (_) => Text(
              'Version: ${_optionsStore.currentAppVersion}+${_optionsStore.currentAppBuildNumber}',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFilterInfoBar() {
    return Observer(
      builder: (_) {
        List<String> activeFilters = [];

        if (_entryStore.currentFilters[FilterField.category] != null) {
          activeFilters.add('Category: ${_entryStore.currentFilters[FilterField.category]}');
        }
        if (_entryStore.currentFilters[FilterField.invoiceMissing] == true) {
          activeFilters.add('Invoice Missing');
        }
        if (_entryStore.currentFilters[FilterField.searchText] != null) {
          activeFilters.add('Search: ${_entryStore.currentFilters[FilterField.searchText]}');
        }
        if (_entryStore.currentFilters[FilterField.notPayed] == true) {
          activeFilters.add('Not Payed');
        }

        if (activeFilters.isEmpty) {
          return const SizedBox.shrink(); // No active filters
        }

        return Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(8),
          color: Colors.blue[100], // Example color for the info bar
          child: Text('Active Filters: ${activeFilters.join(', ')}', style: const TextStyle(fontSize: 16)),
        );
      },
    );
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _entryStore.loadEntries(),
      _categoryStore.loadCategories(),
      _userStore.loadUsers(),
    ]);
  }

  Widget _buildSortCriteriaBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.blue[100], // Just an example color
      child: Observer(
        builder: (_) => Text(
          'Sorted by ${_entryStore.currentSortField.toString().split('.').last} '
          'in ${_entryStore.currentSortOrder.toString().split('.').last} order',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Search',
          suffixIcon: Icon(Icons.search),
        ),
        controller: TextEditingController()..text = _entryStore.currentFilters[FilterField.searchText] ?? '',
        onChanged: (value) {
          final newFilters = Map<FilterField, dynamic>.from(_entryStore.currentFilters);
          newFilters[FilterField.searchText] = value.isNotEmpty ? value : null;
          _entryStore.applyFilters(newFilters);
        },
      ),
    );
  }

  Future<void> _showSortingDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => SortingDialog(
        initialSortField: _entryStore.currentSortField,
        initialSortOrder: _entryStore.currentSortOrder,
      ),
    );

    if (result != null) {
      SortField field = result['field'];
      SortOrder order = result['order'];
      _entryStore.sortEntries(field, order);
    }
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog<Map<FilterField, dynamic>>(
      context: context,
      builder: (BuildContext context) => FilterDialog(currentFilters: _entryStore.currentFilters),
    );

    if (result != null) {
      _entryStore.applyFilters(result);
    }
  }
}
