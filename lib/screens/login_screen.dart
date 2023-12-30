import 'package:cashbook/widgets/auto_complete_text_edit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../stores/auth_store.dart';
import '../services/locator.dart';
import '../constants/route_names.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

// TODO: login with invalid credentials shows confusing error (long text with 401) -> improve
// 405: wrong api url
class _LoginScreenState extends State<LoginScreen> {
  final AuthStore _authStore = locator<AuthStore>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final TextEditingController _serverController;

  bool get _isFormValid => _formKey.currentState?.validate() ?? false;
  bool _usernameTouched = false;
  bool _passwordTouched = false;
  bool _serverTouched = false;

  // List of predefined servers
  final List<String> _predefinedServers = [
    'http://localhost:8001',
    'http://192.168.2.110:8001',
    'https://cashbook-api.markus-heck.dev',
  ];

  @override
  void initState() {
    _serverController = TextEditingController(text: _authStore.baseUrl ?? '');
    super.initState();
  }

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
              autofillHints: const [AutofillHints.username],
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                setState(() {
                  _usernameTouched = true;
                });
              },
              // Update UI on text change
              validator: (value) => _usernameTouched && (value?.trim().isEmpty == true) ? 'Username is required' : null,
              onFieldSubmitted: (_) => _performLogin()),
          TextFormField(
              autofillHints: const [AutofillHints.password],
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              onChanged: (value) {
                setState(() {
                  _passwordTouched = true;
                });
              },
              // Update UI on text change
              validator: (value) => _passwordTouched && (value?.trim().isEmpty == true) ? 'Password is required' : null,
              onFieldSubmitted: (_) => _performLogin()),
          AutoCompleteTextEdit(
            controller: _serverController,
            labelText: 'Server',
            suggestions: _predefinedServers,
            onChanged: (_) {
              setState(() {
                _serverTouched = true;
              });
            },
            validator: (value) => _serverTouched && (value?.trim().isEmpty == true) ? 'Server is required' : null,
            autofillHints: const [AutofillHints.url],
            onFieldSubmitted: (_) => _performLogin(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isFormValid ? () => _performLogin() : null,
            child: const Text('Login'),
          ),
        ],
      ),
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
}
