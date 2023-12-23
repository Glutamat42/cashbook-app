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

  bool get _isFormValid => _formKey.currentState?.validate() ?? false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
              Future.microtask(() => Navigator.of(context)
                  .pushReplacementNamed(RouteNames.homeScreen));
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
                validator: (value) => value?.trim().isEmpty == true ? 'Username is required' : null,
                onFieldSubmitted: (_) => _performLogin()),
            TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value?.trim().isEmpty == true ? 'Password is required' : null,
                onFieldSubmitted: (_) => _performLogin()),
            ElevatedButton(
              onPressed: _isFormValid ? () => _performLogin() : null,
              child: const Text('Login'),
            ),
          ],
        ));
  }

  void _performLogin() async {
    try {
      await _authStore.login(
          _usernameController.text, _passwordController.text);
    } catch (e) {
      _showLoginError(e, context);
    }
  }

  void _showLoginError(dynamic error, BuildContext context) {
    final snackBar =
        SnackBar(content: Text('Login Failed: ${error.toString()}'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
