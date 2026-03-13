// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;

// /// FaceService — Handles face recognition API calls from Flutter side.
// /// SDK only captures image. This service uploads to YOUR backend.
// class FaceService {
//   final String apiUrl;

//   FaceService({required this.apiUrl});

//   /// Upload face image to backend.
//   /// Returns full response as Map so Flutter can decide retry/success.
//   Future<Map<String, dynamic>> uploadFace({
//     required String imagePath,
//     required Map fields, // playerId, streamKey, etc.
//     String imageFieldName = 'image',
//   }) async {
//     try {
//       final file = File(imagePath);
//       if (!file.existsSync()) return {'success': false, 'error': 'Image file not found'};

//       debugPrint('📡 Face Upload: POST $apiUrl');

//       final request = http.MultipartRequest('POST', Uri.parse(apiUrl));

//       // Add all text fields
//       fields.forEach((key, value) {
//         request.fields[key] = value;
//       });

//       // Add image
//       request.files.add(await http.MultipartFile.fromPath(
//         imageFieldName,
//         imagePath,
//         filename: 'face.jpg',
//       ));

//       final streamed = await request.send().timeout(const Duration(minutes: 5));
//       final response = await http.Response.fromStream(streamed);
//       debugPrint('📡 Face Response: ${response.statusCode} — ${response.body}');

//       try {
//         final json = jsonDecode(response.body);
//         return {
//           'success': true,
//           'httpCode': response.statusCode,
//           ...json is Map ? Map<String, dynamic>.from(json) : {'body': response.body},
//         };
//       } catch (_) {
//         return {'success': true, 'httpCode': response.statusCode, 'body': response.body};
//       }
//     } catch (e) {
//       debugPrint('❌ Face Upload Error: $e');
//       return {'success': false, 'error': e.toString()};
//     }
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// FaceService — Handles face recognition API calls from Flutter side.
/// SDK only captures image. This service uploads to YOUR backend.
class FaceService {
  final String apiUrl;

  FaceService({required this.apiUrl});

  /// Upload face image to backend.
  /// Returns full response as Map so Flutter can decide retry/success.
  Future<Map<String, dynamic>> uploadFace({
    required String imagePath,
    required Map<String, String> fields, // playerId, streamKey, etc.
    String imageFieldName = 'image',
  }) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) return {'success': false, 'error': 'Image file not found'};

      debugPrint('📡 Face Upload: POST $apiUrl');

      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Add all text fields
      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add image
      request.files.add(await http.MultipartFile.fromPath(
        imageFieldName,
        imagePath,
        filename: 'face.png',
      ));

      final streamed = await request.send().timeout(const Duration(minutes: 5));
      final response = await http.Response.fromStream(streamed);
      debugPrint('📡 Face Response: ${response.statusCode} — ${response.body}');

      try {
        final json = jsonDecode(response.body);
        return {
          'success': true,
          'httpCode': response.statusCode,
          ...json is Map ? Map<String, dynamic>.from(json) : {'body': response.body},
        };
      } catch (_) {
        return {'success': true, 'httpCode': response.statusCode, 'body': response.body};
      }
    } catch (e) {
      debugPrint('❌ Face Upload Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}