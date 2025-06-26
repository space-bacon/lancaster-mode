import 'package:flutter/material.dart';

import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initializeFirebase();
  runApp(const LancasterApp());
}

class LancasterApp extends StatefulWidget {
  const LancasterApp({super.key});

  @override
  State<LancasterApp> createState() => _LancasterAppState();
}

class _LancasterAppState extends State<LancasterApp> {
  late Future<bool> _isLoggedInFuture;

  @override
  void initState() {
    super.initState();
    _isLoggedInFuture = Future.value(AuthService.isUserLoggedIn());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lancaster Mode',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: FutureBuilder<bool>(
        future: _isLoggedInFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data! ? ChatScreen() : LoginScreen();
        },
      ),
    );
  }
}
