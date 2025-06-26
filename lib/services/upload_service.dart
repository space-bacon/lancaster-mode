// File: services/upload_service.dart

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart'; // <--- Add this

class UploadService {
  static Future<String?> uploadFile({
    required PlatformFile file,
    required String userId,
    String folder = 'uploads',
  }) async {
    try {
      final fileName = file.name;
      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';

      final ref = FirebaseStorage.instance
          .ref()
          .child('$folder/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName');

      UploadTask uploadTask;

      if (kIsWeb) {
        uploadTask = ref.putData(
          file.bytes!,
          SettableMetadata(contentType: mimeType),
        );
      } else {
        final path = file.path;
        if (path == null) throw Exception('File path is null on non-web platform');
        uploadTask = ref.putFile(
          File(path),
          SettableMetadata(contentType: mimeType),
        );
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Upload failed: $e');
      return null;
    }
  }
}
