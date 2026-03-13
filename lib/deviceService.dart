// import 'dart:convert';
// import 'dart:io';

import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gyroscope/apiConfig.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// class DeviceService {
//   static const String _prefsKey = 'persistent_device_id';
//   static const String _baseUrl = 'https://unheeded-uromeric-jadon.ngrok-free.dev/app';
//   static const String _endpoint = '/activity/register';


  

//  static Future<String> getOrCreateDeviceId() async {
//     final prefs = await SharedPreferences.getInstance();

//     // 1. Try to load already saved ID
//     String? deviceId = prefs.getString(_prefsKey);
//     if (deviceId != null && deviceId.trim().isNotEmpty) {
//       return deviceId;
//     }

//     // 2. Try platform-specific fallback
//     try {
//       final deviceInfo = DeviceInfoPlugin();
//       if (Platform.isAndroid) {
//         final androidInfo = await deviceInfo.androidInfo;
//         deviceId = androidInfo.id;
//       } else if (Platform.isIOS) {
//         final iosInfo = await deviceInfo.iosInfo;
//         deviceId = iosInfo.identifierForVendor;
//       }
//     } catch (_) {}

//     // 3. Fallback → UUID
//     deviceId ??= const Uuid().v4();
//     await prefs.setString(_prefsKey, deviceId);
//     return deviceId;
//   }

//   static Future<bool> sendDeviceIdToBackend() async {
//     debugPrint("Ggs");
//     try {
//       final deviceId = await getOrCreateDeviceId();
//       debugPrint("DEvice ir $deviceId");

//       // ── Get location (don't save, just send) ──
//       double latitude = 0;
//       double longitude = 0;
//       try {
//         LocationPermission permission = await Geolocator.checkPermission();
//         if (permission == LocationPermission.denied) {
//           permission = await Geolocator.requestPermission();
//         }
//         if (permission == LocationPermission.whileInUse ||
//             permission == LocationPermission.always) {
//           final position = await Geolocator.getCurrentPosition(
//             desiredAccuracy: LocationAccuracy.high,
//           ).timeout(const Duration(seconds: 15));
//           latitude = position.latitude;
//           longitude = position.longitude;
//           debugPrint('📍 Location: $latitude, $longitude');
//         }
//       } catch (e) {
//         debugPrint('⚠️ Location error: $e');
//       }

//       final uri = Uri.parse('$_baseUrl$_endpoint');
//       debugPrint("SF $uri");

//       final response = await http.post(
//         uri,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'deviceId': deviceId,
//           'lat': latitude,
//           'long': longitude,
//         }),
//       );

//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         print('Device ID sent successfully → $deviceId');
//          print('lat long sent successfully → ${latitude} ${longitude}');
//         return true;
//       } else {
//         print('Failed to send device ID');
//         print('Status: ${response.statusCode}');
//         print('Body: ${response.body}');
//         return false;
//       }
//     } catch (e) {
//       print('Error sending device ID: $e');
//       return false;
//     }
//   }
// }


class DeviceService {
  
   static const String _prefsKey = 'persistent_device_id';
 static const String _baseUrl = appUrl;
// 'http://35.188.96.226:3000/app';
 //'https://unheeded-uromeric-jadon.ngrok-free.dev/app';
  static const String _endpoint = '/activity/register';

  static const _overlayChannel = MethodChannel('gyroscope_plugin/overlay');

  static Future<bool> sendDeviceIdToBackend() async {
    try {
       final prefs = await SharedPreferences.getInstance();

 
      // SDK se sab data lo
     final info = await _overlayChannel.invokeMethod('getDeviceInfo', {});
      final deviceId = info['deviceId'] ?? '';
 await prefs.setString(_prefsKey,deviceId);
      debugPrint("device Id ${info['deviceId']}");
        debugPrint("lat ${info['latitude']}");
          debugPrint("long ${info['longitude']}");

      // API call Flutter mein
      final response = await http.post(
        Uri.parse('$_baseUrl/activity/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': info['deviceId'],
          'lat': info['latitude'],
          'long': info['longitude'],
          
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Device ID sent successfully → $deviceId');
         print('lat long sent successfully → ${info['latitude']} ${info['latitude']}');
        return true;
      } else {
        print('Failed to send device ID');
        print('Status: ${response.statusCode}');
        print('Body: ${response.body}');
        return false;
      }
    }  
      catch (e) {
      debugPrint('❌ Error: $e');
      return false;
    }
  }
}