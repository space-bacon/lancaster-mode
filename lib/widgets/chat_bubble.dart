// File: widgets/chat_bubble.dart

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';

import '../services/upload_service.dart';

class ChatBubble extends StatelessWidget {
  final String userText;
  final String gptText;
  final String userId; // Pass current user ID for upload path

  const ChatBubble({
    Key? key,
    required this.userText,
    required this.gptText,
    required this.userId,
  }) : super(key: key);

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf', 'docx'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Uploading ${file.name}...')));

      final url = await UploadService.uploadFile(file: file, userId: userId);

      if (url != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Uploaded: $url')));
        // You could store the file URL to Firestore here or handle it however needed
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User message bubble with attach icon
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                margin: EdgeInsets.only(top: 8, left: 16, right: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade800,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  userText,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.attach_file, color: Colors.white70),
              tooltip: 'Attach file',
              onPressed: () => _pickFile(context),
            ),
          ],
        ),
        // GPT response bubble
        Container(
          margin: EdgeInsets.only(top: 4, left: 64, right: 16, bottom: 12),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            gptText,
            style: TextStyle(color: Colors.greenAccent, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
