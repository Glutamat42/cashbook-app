import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../stores/entry_store.dart';
import '../stores/auth_store.dart';
import '../widgets/entry_item.dart';
import '../services/locator.dart';
import '../constants/route_names.dart';

class HomeScreen extends StatelessWidget {
  final AuthStore _authStore = locator<AuthStore>();
  final EntryStore _entryStore = locator<EntryStore>();

  HomeScreen({super.key}) {
    _entryStore.loadEntries(); // Load entries when the screen is created
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filtering functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              // TODO: Implement sorting functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _authStore.logout();
              Navigator.of(context).pushReplacementNamed(RouteNames.loginScreen);
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                // TODO: Implement search functionality
              },
            ),
          ),
          Expanded(
            child: Observer(
              builder: (_) => ListView.builder(
                itemCount: _entryStore.entries.length,
                itemBuilder: (context, index) {
                  final entry = _entryStore.entries[index];
                  return EntryItem(
                    description: entry.description,
                    recipientSender: entry.recipientSender,
                    amount: entry.amount,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
