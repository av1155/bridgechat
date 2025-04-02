import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'utils/languages.dart';

class AuthScreen extends StatefulWidget {
  final bool isSignUp;

  const AuthScreen({Key? key, this.isSignUp = false}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _username = '';
  String _preferredLanguage = 'English';
  bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.isSignUp;
  }

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
          await _authService.signUp(
            _email,
            _password,
            _username,
            _preferredLanguage,
          );
        } else {
          await _authService.signIn(_email, _password);
        }
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/recentConversations');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(title: Text(_isSignUp ? 'Sign Up' : 'Sign In')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (_isSignUp)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextFormField(
                        style: TextStyle(fontSize: isMobile ? 14 : 16),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: const Icon(Icons.person),
                          labelStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                        ),
                        onSaved: (value) => _username = value!.trim(),
                        validator:
                            (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Enter a username'
                                    : null,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      style: TextStyle(fontSize: isMobile ? 14 : 16),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        labelStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                      ),
                      onSaved: (value) => _email = value!.trim(),
                      validator:
                          (value) =>
                              (value == null || value.isEmpty)
                                  ? 'Enter an email'
                                  : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      style: TextStyle(fontSize: isMobile ? 14 : 16),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        labelStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                      ),
                      obscureText: true,
                      onSaved: (value) => _password = value!.trim(),
                      validator:
                          (value) =>
                              (value != null && value.length < 6)
                                  ? 'Password too short'
                                  : null,
                    ),
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: 20),
                    // NEW: Dropdown to select preferred language
                    Row(
                      children: [
                        const Text('Preferred Language: '),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
                          value: _preferredLanguage,
                          items:
                              supportedLanguages.keys.map((langName) {
                                return DropdownMenuItem(
                                  value: langName,
                                  child: Text(langName),
                                );
                              }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _preferredLanguage = val ?? 'English';
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 30,
                        vertical: isMobile ? 12 : 16,
                      ),
                    ),
                    child: Text(
                      _isSignUp ? 'Sign Up' : 'Sign In',
                      style: TextStyle(fontSize: isMobile ? 14 : 16),
                    ),
                  ),
                  TextButton(
                    onPressed: _toggleForm,
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Sign In'
                          : 'Don’t have an account? Sign Up',
                      style: TextStyle(fontSize: isMobile ? 14 : 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
