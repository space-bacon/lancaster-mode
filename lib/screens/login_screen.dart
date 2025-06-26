// File: screens/login_screen.dart

import 'package:flutter/material.dart';

import '../services/auth_service.dart';

import 'chat_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoading = false;
  String? error;

  void _signIn() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        error = 'Email and password must not be empty.';
        isLoading = false;
      });
      return;
    }

    final result = await AuthService.signIn(email, password);
    if (result == 'success') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen()),
      );
    } else {
      setState(() {
        error = result;
        isLoading = false;
      });
    }
  }

  void _register() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        error = 'Email and password must not be empty.';
        isLoading = false;
      });
      return;
    }

    final result = await AuthService.register(email, password);
    if (result == 'success') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen()),
      );
    } else {
      setState(() {
        error = result;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login to Lancaster Mode')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(error!, style: TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            if (isLoading)
              CircularProgressIndicator()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: _signIn, child: Text('Login')),
                  ElevatedButton(onPressed: _register, child: Text('Register')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
