// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;

// /// KycService — All KYC API calls. No models, just Maps.
// class KycService {
//   final String baseUrl;
//   final String playerId;

//   KycService({required this.baseUrl, required this.playerId});

//   // ── 1. Upload Document Photos ─────────────────────────────────────────────

//   Future<Map<String, dynamic>> uploadDocument({
//     required String docType,
//     required String frontPhotoPath,
//     String? backPhotoPath,
//   }) async {
//     try {
//       final url = Uri.parse('$baseUrl/player/uploadPlayerKycDocument/$playerId');
//       debugPrint('📡 Upload Doc: POST $url');

//       final request = http.MultipartRequest('POST', url);
//       request.fields['identityDocumentType'] = docType;

//       // Front photo
//       final frontFile = File(frontPhotoPath);
//       if (!frontFile.existsSync()) return {'success': false, 'error': 'Front photo not found'};
//       request.files.add(await http.MultipartFile.fromPath('images', frontPhotoPath));

//       // Back photo
//       if (backPhotoPath != null && backPhotoPath.isNotEmpty) {
//         final backFile = File(backPhotoPath);
//         if (backFile.existsSync()) {
//           request.files.add(await http.MultipartFile.fromPath('images', backPhotoPath));
//         }
//       }

//       final streamed = await request.send().timeout(const Duration(seconds: 120));
//       final response = await http.Response.fromStream(streamed);
//       debugPrint('📡 Doc Response: ${response.statusCode} — ${response.body}');

//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         return {'success': true, 'message': _msg(response.body)};
//       } else {
//         return {'success': false, 'error': 'HTTP ${response.statusCode}: ${_msg(response.body)}'};
//       }
//     } catch (e) {
//       debugPrint('❌ Upload Doc Error: $e');
//       return {'success': false, 'error': e.toString()};
//     }
//   }

//   // ── 2. Upload Selfie Video ────────────────────────────────────────────────

//   Future<Map<String, dynamic>> uploadSelfieVideo({required String videoPath}) async {
//     try {
//       final url = Uri.parse('$baseUrl/player/uploadplayerKycSelfieVideo/$playerId');
//       debugPrint('📡 Upload Video: POST $url');

//       final videoFile = File(videoPath);
//       if (!videoFile.existsSync()) return {'success': false, 'error': 'Video not found'};

//       final sizeMB = videoFile.lengthSync() / (1024 * 1024);
//       if (sizeMB > 20) return {'success': false, 'error': 'Video exceeds 20MB'};

//       final request = http.MultipartRequest('POST', url);
//       request.files.add(await http.MultipartFile.fromPath('video', videoPath));

//       final streamed = await request.send().timeout(const Duration(seconds: 180));
//       final response = await http.Response.fromStream(streamed);
//       debugPrint('📡 Video Response: ${response.statusCode} — ${response.body}');

//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         return {'success': true, 'message': _msg(response.body)};
//       } else {
//         return {'success': false, 'error': 'HTTP ${response.statusCode}: ${_msg(response.body)}'};
//       }
//     } catch (e) {
//       debugPrint('❌ Upload Video Error: $e');
//       return {'success': false, 'error': e.toString()};
//     }
//   }

//   // ── 3. Submit KYC ─────────────────────────────────────────────────────────

//   Future<Map<String, dynamic>> submitKyc() async {
//     try {
//       final url = Uri.parse('$baseUrl/player/submitPlayerKyc');
//       debugPrint('📡 Submit KYC: POST $url');

//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'pid': playerId}),
//       ).timeout(const Duration(seconds: 30));

//       debugPrint('📡 Submit Response: ${response.statusCode} — ${response.body}');

//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         return {'success': true, 'message': _msg(response.body).isEmpty ? 'KYC submitted!' : _msg(response.body)};
//       } else {
//         return {'success': false, 'error': 'HTTP ${response.statusCode}: ${_msg(response.body)}'};
//       }
//     } catch (e) {
//       debugPrint('❌ Submit Error: $e');
//       return {'success': false, 'error': e.toString()};
//     }
//   }

//   // ── 4. Full Flow: Upload Doc + Video + Submit ─────────────────────────────

//   Future<Map<String, dynamic>> uploadAndSubmit({
//     required String docType,
//     required String frontPhotoPath,
//     String? backPhotoPath,
//     required String selfieVideoPath,
//   }) async {
//     // Step 1: Upload doc
//     final docResult = await uploadDocument(
//       docType: docType,
//       frontPhotoPath: frontPhotoPath,
//       backPhotoPath: backPhotoPath,
//     );
//     if (docResult['success'] != true) {
//       return {'success': false, 'error': 'Doc upload failed: ${docResult['error']}'};
//     }

//     // Step 2: Upload video
//     final videoResult = await uploadSelfieVideo(videoPath: selfieVideoPath);
//     if (videoResult['success'] != true) {
//       return {'success': false, 'error': 'Video upload failed: ${videoResult['error']}'};
//     }

//     // Step 3: Submit
//     final submitResult = await submitKyc();
//     if (submitResult['success'] != true) {
//       return {'success': false, 'error': 'Submit failed: ${submitResult['error']}'};
//     }

//     return {'success': true, 'message': submitResult['message']};
//   }

//   // ── Helper ────────────────────────────────────────────────────────────────

//   String _msg(String body) {
//     try { return jsonDecode(body)['message'] ?? ''; } catch (_) { return body; }
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// KycService — All KYC API calls. No models, just Maps.
class KycService {
  final String baseUrl;
  final String playerId;

  KycService({required this.baseUrl, required this.playerId});

  // ── 1. Upload Document Photos ─────────────────────────────────────────────

  Future<Map<String, dynamic>> uploadDocument({
    required String docType,
    required String frontPhotoPath,
    String? backPhotoPath,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/player/uploadPlayerKycDocument/$playerId');
      debugPrint('📡 Upload Doc: POST $url');

      final request = http.MultipartRequest('POST', url);
      request.fields['identityDocumentType'] = docType;

      // Front photo
      final frontFile = File(frontPhotoPath);
      if (!frontFile.existsSync()) return {'success': false, 'error': 'Front photo not found'};
      request.files.add(await http.MultipartFile.fromPath('images', frontPhotoPath));

      // Back photo
      if (backPhotoPath != null && backPhotoPath.isNotEmpty) {
        final backFile = File(backPhotoPath);
        if (backFile.existsSync()) {
          request.files.add(await http.MultipartFile.fromPath('images', backPhotoPath));
        }
      }

      final streamed = await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamed);
      debugPrint('📡 Doc Response: ${response.statusCode} — ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': _msg(response.body)};
      } else {
        return {'success': false, 'error': 'HTTP ${response.statusCode}: ${_msg(response.body)}'};
      }
    } catch (e) {
      debugPrint('❌ Upload Doc Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── 2. Upload Selfie Video ────────────────────────────────────────────────

  Future<Map<String, dynamic>> uploadSelfieVideo({required String videoPath}) async {
    try {
      final url = Uri.parse('$baseUrl/player/uploadplayerKycSelfieVideo/$playerId');
      debugPrint('📡 Upload Video: POST $url');

      final videoFile = File(videoPath);
      if (!videoFile.existsSync()) return {'success': false, 'error': 'Video not found'};

      final sizeMB = videoFile.lengthSync() / (1024 * 1024);
      if (sizeMB > 20) return {'success': false, 'error': 'Video exceeds 20MB'};

      final request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('video', videoPath));

      final streamed = await request.send().timeout(const Duration(seconds: 180));
      final response = await http.Response.fromStream(streamed);
      debugPrint('📡 Video Response: ${response.statusCode} — ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': _msg(response.body)};
      } else {
        return {'success': false, 'error': 'HTTP ${response.statusCode}: ${_msg(response.body)}'};
      }
    } catch (e) {
      debugPrint('❌ Upload Video Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── 3. Submit KYC ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> submitKyc() async {
    try {
      final url = Uri.parse('$baseUrl/player/submitPlayerKyc');
      debugPrint('📡 Submit KYC: POST $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pid': playerId}),
      ).timeout(const Duration(seconds: 30));

      debugPrint('📡 Submit Response: ${response.statusCode} — ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': _msg(response.body).isEmpty ? 'KYC submitted!' : _msg(response.body)};
      } else {
        return {'success': false, 'error': 'HTTP ${response.statusCode}: ${_msg(response.body)}'};
      }
    } catch (e) {
      debugPrint('❌ Submit Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── 4. Full Flow: Upload Doc + Video + Submit ─────────────────────────────

  Future<Map<String, dynamic>> uploadAndSubmit({
    required String docType,
    required String frontPhotoPath,
    String? backPhotoPath,
    required String selfieVideoPath,
  }) async {
    // Step 1: Upload doc
    final docResult = await uploadDocument(
      docType: docType,
      frontPhotoPath: frontPhotoPath,
      backPhotoPath: backPhotoPath,
    );
    if (docResult['success'] != true) {
      return {'success': false, 'error': 'Doc upload failed: ${docResult['error']}'};
    }

    // Step 2: Upload video
    final videoResult = await uploadSelfieVideo(videoPath: selfieVideoPath);
    if (videoResult['success'] != true) {
      return {'success': false, 'error': 'Video upload failed: ${videoResult['error']}'};
    }

    // Step 3: Submit
    final submitResult = await submitKyc();
    if (submitResult['success'] != true) {
      return {'success': false, 'error': 'Submit failed: ${submitResult['error']}'};
    }

    return {'success': true, 'message': submitResult['message']};
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  String _msg(String body) {
    try { return jsonDecode(body)['message'] ?? ''; } catch (_) { return body; }
  }
}