// File: services/auth_service.dart

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../secrets.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> initializeFirebase() async {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: Secrets.apiKey,
          authDomain: Secrets.authDomain,
          projectId: Secrets.projectId,
          storageBucket: Secrets.storageBucket,
          messagingSenderId: Secrets.messagingSenderId,
          appId: Secrets.appId,
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  }

  static bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  static String getCurrentUserId() {
    return _auth.currentUser?.uid ?? '';
  }

  static Future<void> signInAnonymously() async {
    await _auth.signInAnonymously();
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<String> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return 'success';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    }
  }

  static Future<String> register(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'role': 'free',
        'tokens': 999,
        'created_at': FieldValue.serverTimestamp(),
      });

      return 'success';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Registration failed';
    }
  }
}
