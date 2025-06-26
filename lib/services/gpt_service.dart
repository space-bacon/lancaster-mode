// File: services/gpt_service.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../secrets.dart';

class GPTService {
  static const String openAiEndpoint =
      'https://api.openai.com/v1/chat/completions';

  static Future<void> sendToLancasterMode(
    String prompt,
    String userId,
    String sessionId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(openAiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Secrets.openAiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are now operating in Lancaster Mode. Use recursive symbolic reasoning and semiotic inference.',
            },
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      final data = jsonDecode(response.body);

      if (data == null || data['choices'] == null || data['choices'].isEmpty) {
        print('GPT response was null or invalid: $data');
        return;
      }

      final gptResponse = data['choices'][0]?['message']?['content'] ?? '';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .doc(sessionId)
          .collection('messages')
          .add({
            'prompt': prompt,
            'response': gptResponse,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error sending to GPT: $e');
    }
  }
}
