// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:web_socket_channel/web_socket_channel.dart';

// // ─── Enums ────────────────────────────────────────────────────────────────────

// enum GyroSamplingRate { fastest, game, ui, normal }

// enum PhoneState { active, idle }

// // ─── Models ───────────────────────────────────────────────────────────────────

// class GyroData {
//   final double x, y, z;
//   final int timestampNs;
//   final String sessionId;
//   final String gameId;
//   final bool isIdle;

//   const GyroData({
//     required this.x, required this.y, required this.z,
//     required this.timestampNs,
//     this.sessionId = '', this.gameId = '', this.isIdle = false,
//   });

//   factory GyroData.fromMap(Map<String, dynamic> m) => GyroData(
//     x: (m['x'] as num).toDouble(),
//     y: (m['y'] as num).toDouble(),
//     z: (m['z'] as num).toDouble(),
//     timestampNs: (m['timestampNs'] as num).toInt(),
//     sessionId: m['sessionId'] as String? ?? '',
//     gameId: m['gameId'] as String? ?? '',
//     isIdle: m['isIdle'] as bool? ?? false,
//   );

//   Map<String, dynamic> toMap() => {
//     'x': x, 'y': y, 'z': z,
//     'timestampNs': timestampNs,
//     'sessionId': sessionId,
//     'gameId': gameId,
//   };
// }

// class SessionInfo {
//   final String sessionId;
//   final String gameId;
//   final int startTimeMs;
//   final int? endTimeMs;
//   final int? durationMs;
//   final int? totalReadings;

//   const SessionInfo({
//     required this.sessionId, required this.gameId,
//     required this.startTimeMs,
//     this.endTimeMs, this.durationMs, this.totalReadings,
//   });

//   Duration? get duration => durationMs != null
//       ? Duration(milliseconds: durationMs!) : null;
// }

// // ─── Callbacks ────────────────────────────────────────────────────────────────

// typedef GyroDataCallback      = void Function(GyroData data);
// typedef SessionCallback       = void Function(SessionInfo session);
// typedef PhoneStateCallback    = void Function(PhoneState state, String sessionId);
// typedef VoidSessionCallback   = void Function(String sessionId);

// // ─── Main SDK ─────────────────────────────────────────────────────────────────

// class GyroscopePlugin {

//   static const _method = MethodChannel('gyroscope_plugin/methods');
//   static const _events = EventChannel('gyroscope_plugin/events');

//   // Stream controllers
//   final _gyroController = StreamController<GyroData>.broadcast();
//   StreamSubscription? _eventSub;

//   // WebSocket
//   WebSocketChannel? _ws;
//   StreamSubscription? _wsSub;
//   bool _wsConnected = false;

//   // State
//   String? _sessionId;
//   String? _gameId;
//   bool _isActive = false;

//   // Callbacks
//   GyroDataCallback? _onData;
//   SessionCallback? _onSessionStarted;
//   SessionCallback? _onSessionStopped;
//   PhoneStateCallback? _onPhoneState;

//   // ── Getters ──────────────────────────────────────────────────────────────────

//   bool get isActive => _isActive;
//   String? get sessionId => _sessionId;
//   Stream<GyroData> get gyroStream => _gyroController.stream;

//   // ── Setup MethodChannel callbacks from native ─────────────────────────────

//   void _setupMethodCallHandler() {
//     _method.setMethodCallHandler((call) async {
//       final args = Map<String, dynamic>.from(call.arguments as Map? ?? {});

//       switch (call.method) {

//         // Gyro data reading
//         case 'onGyroData':
//           final data = GyroData.fromMap(args);
//           _gyroController.add(data);
//           _onData?.call(data);

//           // Real-time WebSocket bhejo
//           if (_wsConnected && _ws != null) {
//             try {
//               _ws!.sink.add(jsonEncode({
//                 'type': 'gyro_data',
//                 ...data.toMap(),
//                 'timestampMs': DateTime.now().millisecondsSinceEpoch,
//               }));
//             } catch (_) {}
//           }
//           break;

//         // Phone still ho gaya
//         case 'onGyroIdle':
//           _onPhoneState?.call(PhoneState.idle, args['sessionId'] as String? ?? '');
//           break;

//         // Phone hila
//         case 'onGyroActive':
//           _onPhoneState?.call(PhoneState.active, args['sessionId'] as String? ?? '');
//           break;

//         // Session shuru
//         case 'onSessionStarted':
//           _sessionId = args['sessionId'] as String?;
//           _gameId = args['gameId'] as String?;
//           _isActive = true;
//           _onSessionStarted?.call(SessionInfo(
//             sessionId: args['sessionId'] as String,
//             gameId: args['gameId'] as String,
//             startTimeMs: (args['startTimeMs'] as num).toInt(),
//           ));
//           break;

//         // Session band
//         case 'onSessionStopped':
//           _isActive = false;
//           final info = SessionInfo(
//             sessionId: args['sessionId'] as String,
//             gameId: args['gameId'] as String,
//             startTimeMs: (args['startTimeMs'] as num).toInt(),
//             endTimeMs: (args['endTimeMs'] as num).toInt(),
//             durationMs: (args['durationMs'] as num).toInt(),
//             totalReadings: (args['totalReadings'] as num).toInt(),
//           );
//           _onSessionStopped?.call(info);

//           // Session end pe REST API pe save karo
//           if (_restApiUrl != null) {
//             _saveSessionToApi(info);
//           }

//           // WebSocket pe session_stop bhejo
//           if (_wsConnected && _ws != null) {
//             try {
//               _ws!.sink.add(jsonEncode({
//                 'type': 'session_stop',
//                 'sessionId': info.sessionId,
//                 'gameId': info.gameId,
//                 'durationMs': info.durationMs,
//                 'totalReadings': info.totalReadings,
//               }));
//             } catch (_) {}
//           }
//           break;
//       }
//     });
//   }

//   String? _restApiUrl;
//   String? _wsUrl;

//   // ── Main API ──────────────────────────────────────────────────────────────────

//   Future<bool> hasGyroscope() async =>
//       await _method.invokeMethod<bool>('hasGyroscope') ?? false;

//   /// Game start karo — session + gyroscope ek saath shuru ho jaate hain
//   Future<String?> startGame({
//     required String gameId,
//     GyroSamplingRate samplingRate = GyroSamplingRate.game,
//     bool autoLog = false,
//     GyroDataCallback? onData,
//     SessionCallback? onSessionStart,
//     SessionCallback? onSessionStop,
//     PhoneStateCallback? onPhoneState,
//     String? wsUrl,
//     String? restApiUrl,
//   }) async {
//     _onData = onData;
//     _onSessionStarted = onSessionStart;
//     _onSessionStopped = onSessionStop;
//     _onPhoneState = onPhoneState;
//     _restApiUrl = restApiUrl;
//     _wsUrl = wsUrl;

//     // Setup MethodChannel handler
//     _setupMethodCallHandler();

//     // WebSocket connect karo
//     if (wsUrl != null) await _connectWs(wsUrl, gameId);

//     // Native session start karo
//     final sessionId = await _method.invokeMethod<String>('startSession', {
//       'gameId': gameId,
//       'samplingRate': samplingRate.index,
//       'autoLog': autoLog,
//     });

//     _sessionId = sessionId;
//     _gameId = gameId;
//     _isActive = true;

//     return sessionId;
//   }

//   /// Game band karo
//   Future<void> stopGame() async {
//     await _method.invokeMethod('stopSession');
//     _isActive = false;
//   }

//   // ── WebSocket ─────────────────────────────────────────────────────────────────

//   Future<void> _connectWs(String url, String gameId) async {
//     try {
//       _ws = WebSocketChannel.connect(Uri.parse(url));
//       await _ws!.ready;
//       _wsConnected = true;

//       _ws!.sink.add(jsonEncode({
//         'type': 'session_start',
//         'gameId': gameId,
//         'sessionId': _sessionId,
//         'timestampMs': DateTime.now().millisecondsSinceEpoch,
//       }));

//       _wsSub = _ws!.stream.listen(
//         (_) {},
//         onDone: () => _wsConnected = false,
//         onError: (_) => _wsConnected = false,
//       );
//     } catch (_) {
//       _wsConnected = false;
//     }
//   }

//   Future<void> _disconnectWs() async {
//     await _wsSub?.cancel();
//     await _ws?.sink.close();
//     _ws = null;
//     _wsConnected = false;
//   }

//   // ── REST API ──────────────────────────────────────────────────────────────────

//   Future<void> _saveSessionToApi(SessionInfo info) async {
//     if (_restApiUrl == null) return;
//     try {
//       await http.post(
//         Uri.parse('$_restApiUrl/api/sessions'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'sessionId': info.sessionId,
//           'gameId': info.gameId,
//           'startTimeMs': info.startTimeMs,
//           'endTimeMs': info.endTimeMs,
//           'durationMs': info.durationMs,
//           'totalReadings': info.totalReadings,
//         }),
//       );
//     } catch (_) {}
//   }

//   // ── Dispose ───────────────────────────────────────────────────────────────────

//   Future<void> dispose() async {
//     await stopGame();
//     await _disconnectWs();
//     await _eventSub?.cancel();
//     await _gyroController.close();
//     _method.setMethodCallHandler(null);
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum GyroSamplingRate { fastest, game, ui, normal }

enum PhoneState { active, idle }

// ─── Models ───────────────────────────────────────────────────────────────────

class GyroData {
  final double x, y, z;
  final double ax, ay, az;  // Accelerometer
  final int timestampNs;
  final String sessionId;
  final String gameId;
  final bool isIdle;

  const GyroData({
    required this.x, required this.y, required this.z,
    this.ax = 0, this.ay = 0, this.az = 0,
    required this.timestampNs,
    this.sessionId = '', this.gameId = '', this.isIdle = false,
  });

  factory GyroData.fromMap(Map<String, dynamic> m) => GyroData(
    x: (m['x'] as num).toDouble(),
    y: (m['y'] as num).toDouble(),
    z: (m['z'] as num).toDouble(),
    ax: (m['ax'] as num?)?.toDouble() ?? 0,
    ay: (m['ay'] as num?)?.toDouble() ?? 0,
    az: (m['az'] as num?)?.toDouble() ?? 0,
    timestampNs: (m['timestampNs'] as num).toInt(),
    sessionId: m['sessionId'] as String? ?? '',
    gameId: m['gameId'] as String? ?? '',
    isIdle: m['isIdle'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {
    'x': x, 'y': y, 'z': z,
    'ax': ax, 'ay': ay, 'az': az,
    'timestampNs': timestampNs,
    'sessionId': sessionId,
    'gameId': gameId,
  };
}

class SessionInfo {
  final String sessionId;
  final String gameId;
  final int startTimeMs;
  final int? endTimeMs;
  final int? durationMs;
  final int? totalReadings;

  const SessionInfo({
    required this.sessionId, required this.gameId,
    required this.startTimeMs,
    this.endTimeMs, this.durationMs, this.totalReadings,
  });

  Duration? get duration => durationMs != null
      ? Duration(milliseconds: durationMs!) : null;
}

// ─── Callbacks ────────────────────────────────────────────────────────────────

typedef GyroDataCallback      = void Function(GyroData data);
typedef SessionCallback       = void Function(SessionInfo session);
typedef PhoneStateCallback    = void Function(PhoneState state, String sessionId);
typedef VoidSessionCallback   = void Function(String sessionId);

// ─── Main SDK ─────────────────────────────────────────────────────────────────

class GyroscopePlugin {

  static const _method = MethodChannel('gyroscope_plugin/methods');
  static const _events = EventChannel('gyroscope_plugin/events');

  // Stream controllers
  final _gyroController = StreamController<GyroData>.broadcast();
  StreamSubscription? _eventSub;

  // WebSocket
  WebSocketChannel? _ws;
  StreamSubscription? _wsSub;
  bool _wsConnected = false;

  // State
  String? _sessionId;
  String? _gameId;
  bool _isActive = false;

  // Callbacks
  GyroDataCallback? _onData;
  SessionCallback? _onSessionStarted;
  SessionCallback? _onSessionStopped;
  PhoneStateCallback? _onPhoneState;

  // ── Getters ──────────────────────────────────────────────────────────────────

  bool get isActive => _isActive;
  String? get sessionId => _sessionId;
  Stream<GyroData> get gyroStream => _gyroController.stream;

  // ── Setup MethodChannel callbacks from native ─────────────────────────────

  void _setupMethodCallHandler() {
    _method.setMethodCallHandler((call) async {
      final args = Map<String, dynamic>.from(call.arguments as Map? ?? {});

      switch (call.method) {

        // Gyro data reading
        case 'onGyroData':
          final data = GyroData.fromMap(args);
          _gyroController.add(data);
          _onData?.call(data);

          // Real-time WebSocket bhejo
          if (_wsConnected && _ws != null) {
            try {
              _ws!.sink.add(jsonEncode({
                'type': 'gyro_data',
                ...data.toMap(),
                'timestampMs': DateTime.now().millisecondsSinceEpoch,
              }));
            } catch (_) {}
          }
          break;

        // Phone still ho gaya
        case 'onGyroIdle':
          _onPhoneState?.call(PhoneState.idle, args['sessionId'] as String? ?? '');
          break;

        // Phone hila
        case 'onGyroActive':
          _onPhoneState?.call(PhoneState.active, args['sessionId'] as String? ?? '');
          break;

        // Session shuru
        case 'onSessionStarted':
          _sessionId = args['sessionId'] as String?;
          _gameId = args['gameId'] as String?;
          _isActive = true;
          _onSessionStarted?.call(SessionInfo(
            sessionId: args['sessionId'] as String,
            gameId: args['gameId'] as String,
            startTimeMs: (args['startTimeMs'] as num).toInt(),
          ));
          break;

        // Session band
        case 'onSessionStopped':
          _isActive = false;
          final info = SessionInfo(
            sessionId: args['sessionId'] as String,
            gameId: args['gameId'] as String,
            startTimeMs: (args['startTimeMs'] as num).toInt(),
            endTimeMs: (args['endTimeMs'] as num).toInt(),
            durationMs: (args['durationMs'] as num).toInt(),
            totalReadings: (args['totalReadings'] as num).toInt(),
          );
          _onSessionStopped?.call(info);

          // Session end pe REST API pe save karo
          if (_restApiUrl != null) {
            _saveSessionToApi(info);
          }

          // WebSocket pe session_stop bhejo
          if (_wsConnected && _ws != null) {
            try {
              _ws!.sink.add(jsonEncode({
                'type': 'session_stop',
                'sessionId': info.sessionId,
                'gameId': info.gameId,
                'durationMs': info.durationMs,
                'totalReadings': info.totalReadings,
              }));
            } catch (_) {}
          }
          break;
      }
    });
  }

  String? _restApiUrl;
  String? _wsUrl;

  // ── Main API ──────────────────────────────────────────────────────────────────

  Future<bool> hasGyroscope() async =>
      await _method.invokeMethod<bool>('hasGyroscope') ?? false;

  /// Game start karo — session + gyroscope ek saath shuru ho jaate hain
  Future<String?> startGame({
    required String gameId,
    GyroSamplingRate samplingRate = GyroSamplingRate.game,
    bool autoLog = false,
    GyroDataCallback? onData,
    SessionCallback? onSessionStart,
    SessionCallback? onSessionStop,
    PhoneStateCallback? onPhoneState,
    String? wsUrl,
    String? restApiUrl,
  }) async {
    _onData = onData;
    _onSessionStarted = onSessionStart;
    _onSessionStopped = onSessionStop;
    _onPhoneState = onPhoneState;
    _restApiUrl = restApiUrl;
    _wsUrl = wsUrl;

    // Setup MethodChannel handler
    _setupMethodCallHandler();

    // WebSocket connect karo
    if (wsUrl != null) await _connectWs(wsUrl, gameId);

    // Native session start karo
    final sessionId = await _method.invokeMethod<String>('startSession', {
      'gameId': gameId,
      'samplingRate': samplingRate.index,
      'autoLog': autoLog,
    });

    _sessionId = sessionId;
    _gameId = gameId;
    _isActive = true;

    return sessionId;
  }

  /// Game band karo
  Future<void> stopGame() async {
    await _method.invokeMethod('stopSession');
    _isActive = false;
  }

  // ── WebSocket ─────────────────────────────────────────────────────────────────

  Future<void> _connectWs(String url, String gameId) async {
    try {
      _ws = WebSocketChannel.connect(Uri.parse(url));
      await _ws!.ready;
      _wsConnected = true;

      _ws!.sink.add(jsonEncode({
        'type': 'session_start',
        'gameId': gameId,
        'sessionId': _sessionId,
        'timestampMs': DateTime.now().millisecondsSinceEpoch,
      }));

      _wsSub = _ws!.stream.listen(
        (_) {},
        onDone: () => _wsConnected = false,
        onError: (_) => _wsConnected = false,
      );
    } catch (_) {
      _wsConnected = false;
    }
  }

  Future<void> _disconnectWs() async {
    await _wsSub?.cancel();
    await _ws?.sink.close();
    _ws = null;
    _wsConnected = false;
  }

  // ── REST API ──────────────────────────────────────────────────────────────────

  Future<void> _saveSessionToApi(SessionInfo info) async {
    if (_restApiUrl == null) return;
    try {
      await http.post(
        Uri.parse('$_restApiUrl/api/sessions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': info.sessionId,
          'gameId': info.gameId,
          'startTimeMs': info.startTimeMs,
          'endTimeMs': info.endTimeMs,
          'durationMs': info.durationMs,
          'totalReadings': info.totalReadings,
        }),
      );
    } catch (_) {}
  }

  // ── Dispose ───────────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await stopGame();
    await _disconnectWs();
    await _eventSub?.cancel();
    await _gyroController.close();
    _method.setMethodCallHandler(null);
  }
}