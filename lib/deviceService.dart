import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const String _prefsKey = 'persistent_device_id';
  static const String _baseUrl = 'https://unheeded-uromeric-jadon.ngrok-free.dev';
  static const String _endpoint = '/gyroscope/deviceId';

  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Try to load already saved ID
    String? deviceId = prefs.getString(_prefsKey);
    if (deviceId != null && deviceId.trim().isNotEmpty) {
      return deviceId;
    }

    // 2. Try platform-specific fallback (not always persistent)
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id; // fallback (often changes on some devices)
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
      }
    } catch (_) {
      // ignore
    }

    // 3. Ultimate fallback → generate UUID and save it forever
    deviceId ??= const Uuid().v4();

    // Save for next time (this is what makes it survive reinstalls)
    await prefs.setString(_prefsKey, deviceId);

    return deviceId;
  }

  /// Main function you probably want to call once on app start
  static Future<bool> sendDeviceIdToBackend() async {
    debugPrint("Ggs");
    try {
      final deviceId = await getOrCreateDeviceId();
      debugPrint("DEvice ir $deviceId");

      final uri = Uri.parse('https://unheeded-uromeric-jadon.ngrok-free.dev/app/gyroscope/deviceId');

      final response = await http.post(
        uri,
       headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': deviceId,           // most common format
          // or just deviceId as raw string if your backend expects raw body:
          // body: deviceId,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Device ID sent successfully → $deviceId');
        return true;
      } else {
        print('Failed to send device ID');
        print('Status: ${response.statusCode}');
        print('Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending device ID: $e');
      return false;
    }
  }
}