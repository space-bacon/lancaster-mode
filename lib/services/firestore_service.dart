// File: services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<String> createNewSession(String userId) async {
    final newDoc = await _db
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .add({'name': '', 'created_at': FieldValue.serverTimestamp()});
    return newDoc.id;
  }

  static Stream<QuerySnapshot> getSessions(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getMessageStream(
    String userId,
    String sessionId,
  ) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Future<void> addMessage({
    required String userId,
    required String sessionId,
    required String prompt,
    required String response,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .doc(sessionId)
        .collection('messages')
        .add({
          'prompt': prompt,
          'response': response,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }
}
