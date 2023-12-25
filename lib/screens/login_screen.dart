import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../stores/auth_store.dart';
import '../services/locator.dart';
import '../constants/route_names.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthStore _authStore = locator<AuthStore>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _serverController = TextEditingController();

  bool get _isFormValid => _formKey.currentState?.validate() ?? false;

  // List of predefined servers
  final List<String> _predefinedServers = [
    'http://localhost:8001',
    'http://192.168.2.110:8001',
    'https://cashbook.markus-heck.dev',
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Observer(
          builder: (_) {
            if (_authStore.isLoggedIn) {
              // Redirect to the home screen if already logged in
              Future.microtask(() => Navigator.of(context).pushReplacementNamed(RouteNames.homeScreen));
              return const SizedBox.shrink(); // Placeholder widget
            }

            return _buildLoginForm();
          },
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => setState(() {}),
              // Update UI on text change
              validator: (value) => value?.trim().isEmpty == true ? 'Username is required' : null,
              onFieldSubmitted: (_) => _performLogin()),
          TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              onChanged: (value) => setState(() {}),
              // Update UI on text change
              validator: (value) => value?.trim().isEmpty == true ? 'Password is required' : null,
              onFieldSubmitted: (_) => _performLogin()),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return _predefinedServers;
              }
              return _predefinedServers.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              setState(() {
                _serverController.text = selection;
              });
            },
            fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
              return TextFormField(
                controller: fieldTextEditingController,
                focusNode: fieldFocusNode,
                decoration: const InputDecoration(labelText: 'Server'),
                validator: (value) => value?.trim().isEmpty == true ? 'Server is required' : null,
                onChanged: (value) {
                  // Update the form's state when the server field changes
                  setState(() {});
                },
              );
            },
          ),
          ElevatedButton(
            onPressed: _isFormValid ? () => _performLogin() : null,
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildPredefinedServersList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _predefinedServers.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(_predefinedServers[index]),
          onTap: () {
            // Set the server input field to the selected server
            setState(() {
              _serverController.text = _predefinedServers[index];
            });
          },
        );
      },
    );
  }

  void _performLogin() async {
    ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _authStore.login(_usernameController.text, _passwordController.text, _serverController.text);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Login Failed: ${e.toString()}')),
      );
    }
  }

  void _showLoginError(dynamic error, BuildContext context) {
    final snackBar = SnackBar(content: Text('Login Failed: ${error.toString()}'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
