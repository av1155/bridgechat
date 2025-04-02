import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'conversation_selection.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _username = ''; // New variable for username.
  bool _isSignUp = false;

  void _toggleForm() {
    setState(() {
      _isSignUp = !_isSignUp;
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        if (_isSignUp) {
          // Pass _username along with _email and _password.
          await _authService.signUp(_email, _password, _username);
        } else {
          await _authService.signIn(_email, _password);
        }
        // Navigate to conversation selection after auth.
        Navigator.pushReplacementNamed(context, '/recentConversations');
      } catch (e) {
        // Handle errors.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSignUp ? 'Sign Up' : 'Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_isSignUp) // Only show username field for sign-up.
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Username'),
                  onSaved: (value) => _username = value!.trim(),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Enter a username'
                              : null,
                ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                onSaved: (value) => _email = value!.trim(),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Enter an email'
                            : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSaved: (value) => _password = value!.trim(),
                validator:
                    (value) =>
                        value != null && value.length < 6
                            ? 'Password too short'
                            : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
              ),
              TextButton(
                onPressed: _toggleForm,
                child: Text(
                  _isSignUp
                      ? 'Already have an account? Sign In'
                      : 'Don’t have an account? Sign Up',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
