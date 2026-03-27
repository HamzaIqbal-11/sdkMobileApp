import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gyroscope/accelerometer_screen.dart';
import 'package:gyroscope/addTransaction.dart';
import 'package:gyroscope/apiConfig.dart';
import 'package:gyroscope/deviceService.dart';
import 'package:gyroscope/device_info_Screen.dart';
import 'package:gyroscope/faceService.dart';
import 'package:gyroscope/gyroscope_screen.dart';
import 'package:gyroscope/kycService.dart';
import 'package:gyroscope/gyroscopePlugin.dart';
import 'package:gyroscope/serviceModel.dart';
import 'package:gyroscope/transactionHistory.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;

const _overlayChannel = MethodChannel('gyroscope_plugin/overlay');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Send device ID right after app starts (only once is usually enough)
  await _requestLocationPermission(); // pehle location

  // await DeviceService.sendDeviceIdToBackend();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

Future<PermissionStatus> _requestLocationPermission() async {
  final status = await Permission.location.request();
  debugPrint('📍 Location permission: $status');
  return status;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Candy Tracker',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF050510),
    ),
    home: const HomeScreen(),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _sdk = GyroscopePlugin();
  String? rtmpUrl;
  String? streamKey;
  bool _isStreaming = false;
  bool _hasGyro = false;
  String _sessionId = '';
  int _readingCount = 0;
  double _gx = 0, _gy = 0, _gz = 0;
  double _ax = 0, _ay = 0, _az = 0;
  bool _phoneIdle = false;
  String _statusMsg = 'Ready to play';
  DateTime? _sessionStart;
  String _duration = '0s';
  Timer? _durationTimer;
  Timer? _backendTimer;
  bool _gameWasLaunched = false;
  SessionInfo? _lastSession;
  // static const String streamStartBaseUrl = 'http://136.113.114.24:3000/app';
  // 'https://unheeded-uromeric-jadon.ngrok-free.dev/app';

  static const String _streamBaseUrl =
      'rtmp://rtmps.production.earnscape.io/live';
  IO.Socket? _socket;

  bool _socketConnected = false;

  // ── Backend URL ─────────────────────────────────────────────────────────
  static const String _backendUrl = appUrl;

  bool _overlayPermissionGranted = false;
  bool _waitingForPermission = false;
  bool _hasTransactions = false;

  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;


     AppConfigModel? appConfig;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _checkGyro();
    // App launch hote hi permission check karo aur bottomsheet dikhao
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // _checkAndShowPermissionSheet();
      _registerDevice();
      
      await _requestCameraPermission();

    await  fetchProducts();
      _startSensors();
      if (isServiceActive('streaming')){
      await _startGame();
      }

      debugPrint("URl = ${appUrl}");

    });
    debugPrint(isServiceActive("streaming").toString());
     debugPrint(isServiceActive("facial_recognition").toString());
      debugPrint(isServiceActive("gyroscope").toString());
       debugPrint(isServiceActive("accelerometer").toString());
        debugPrint(isServiceActive("transaction").toString());
         debugPrint(isServiceActive("location").toString());
    
  }


  Future<void> _openDriveRecording() async {
    if (streamKey == null) {
      _showSnack('No recording available');
      return;
    }

    try {
      _showSnack2('Fetching recording...');
      debugPrint("streem key${streamKey}");
      final response = await http
          .get(
            Uri.parse('$_backendUrl/stream/$streamKey'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      debugPrint("stree ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final driveUrl = data['data']?['driveUrl'] ?? '';

        if (driveUrl.isEmpty) {
          _showSnack('Recording not ready yet');
          return;
        }

        final uri = Uri.parse(driveUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showSnack('Cannot open Drive link');
        }
      } else {
        _showSnack('Failed to get recording:  ');
      }
    } catch (e) {
      debugPrint('❌ Drive fetch error: $e');
      _showSnack('Network error');
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      debugPrint('📸 Camera permission granted');
    } else {
      debugPrint('❌ Camera permission denied');
    }
  }

  Future<void> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    debugPrint('🎙️ Mic permission: $status');
  }

  String _status = 'Sending device ID...';

  Future<void> _registerDevice() async {
    // final prefs = await SharedPreferences.getInstance();
    // final alreadySent = prefs.getBool('device_id_sent') ?? false;

    // if (alreadySent) {
    //   setState(() => _status = 'Device already registered');
    //   return;
    // }

    final success = await DeviceService.sendDeviceIdToBackend();

    if (success) {
      // await prefs.setBool('device_id_sent', true);
      setState(() => _status = 'Device registered ✓');
    } else {
      setState(() => _status = 'Failed to register device');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (_waitingForPermission) {
        // User settings se wapis aaya — permission check karo
        _waitingForPermission = false;
        _recheckPermissionAfterSettings();
        return;
      }
      if (_gameWasLaunched && _isStreaming) {
        _stopGame();
        _gameWasLaunched = false;
      }
    } else if (state == AppLifecycleState.paused) {
      if (_isStreaming) _gameWasLaunched = true;
    }
  }

  // ── Permission Check ──────────────────────────────────────────────────────

  Future<void> _checkAndShowPermissionSheet() async {
    final bool granted =
        await _overlayChannel.invokeMethod('checkOverlayPermission') ?? false;
    setState(() => _overlayPermissionGranted = granted);

    if (!granted) {
      // Permission nahi hai — bottomsheet dikhao
      _showPermissionBottomSheet();
    }
  }

  Future<void> _recheckPermissionAfterSettings() async {
    final bool granted =
        await _overlayChannel.invokeMethod('checkOverlayPermission') ?? false;
    setState(() => _overlayPermissionGranted = granted);

    if (granted && mounted) {
      // Permission mil gayi — success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Overlay permission granted!'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (!granted && mounted) {
      // Still nahi mili — bottomsheet dobara dikhao
      _showPermissionBottomSheet();
    }
  }

  void _showPermissionBottomSheet() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PermissionBottomSheet(
        onProceed: () {
          Navigator.pop(ctx);
          _requestOverlayPermission();
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  Future<void> _requestOverlayPermission() async {
    _waitingForPermission = true;
    try {
      await _overlayChannel.invokeMethod('requestOverlayPermission');
    } catch (_) {}
  }

  // ── Game Start/Stop ───────────────────────────────────────────────────────

Future<void> fetchProducts() async {
   
    try {
       final prefs = await SharedPreferences.getInstance();
      // final info = await _overlayChannel.invokeMethod('getDeviceInfo', {});final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('persistent_device_id') ?? '';
      //final deviceId = info['deviceId'] ?? '';

      final response = await http.get(
        Uri.parse('$appUrl/config/NX-994'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));
 debugPrint("response  ${response.statusCode }");
      if (response.statusCode == 200) {
 final data = jsonDecode(response.body);
      
    setState(() {
      appConfig = AppConfigModel.fromJson(data);
    });
       
         debugPrint("dataa $data");
        // setState(() {
        //   _transactions = list.map((e) => Map<String, dynamic>.from(e)).toList();
        //   _loading = false;
        // });
      } else {
      //  setState(() { _error = 'Server error: ${response.statusCode}'; _loading = false; });
      }
    } catch (e) {
      //setState(() { _error = 'Failed to load transactions'; _loading = false; });
    }
  }

  Future<void> _checkGyro() async {
    final has = await _sdk.hasGyroscope();
    setState(() => _hasGyro = has);
  }

  Future<void> _startGame() async {
    // Permission nahi hai toh bottomsheet dikhao
   // await _requestMicPermission();

    // if (!_overlayPermissionGranted) {
    //   _showPermissionBottomSheet();
    //   return;
    // }

    // if (!_hasGyro) {
    //   _showSnack('No gyroscope found on this device!');
    //   return;
    // }

    setState(() => _lastSession = null);

    setState(() {
      _statusMsg = 'Starting stream...';
    });



    // Get device ID
    final info = await _overlayChannel.invokeMethod('getDeviceInfo', {});
final deviceId = info['deviceId'] ?? '';

    // debugPrint("sf${streamStartBaseUrl}");
    debugPrint(" devicesss ${deviceId}");

    // ── Backend se RTMP credentials le lo ──
    try {
      final response = await http.post(
        Uri.parse(
          '$_backendUrl/stream/start',
        ), // same backend jo gyroscope ke liye use kar rahe ho
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'organization_id': '1',
          'product_id': '1',
          'deviceId': deviceId,
          'streamTitle': 'CandyCrush',
          'streamerName': "dummy", // ya agar username hai to change kar dena
        }),
      );

      debugPrint("resposne ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        debugPrint("faf ${data['data']}");
        rtmpUrl = data['data']['rtmpUrl'];
        streamKey = data['data']['streamKey'];

        // SharedPreferences prefs = await SharedPreferences.getInstance();
        // prefs.setString('streamKey', streamKey!);

        debugPrint('RTMP URL received: $rtmpUrl');
        debugPrint('Stream Key received: $streamKey');
      } else if (response.statusCode == 403) {
        _showSnack('Streaming service is not active for this product');
        return;
      } else {
        debugPrint('Backend /stream/start failed: ${response.statusCode}');
        _showSnack('Could not start recording  ');
        setState(() => _statusMsg = 'Server error');
        return;
      }
    } catch (e) {
      debugPrint('Error calling /stream/start: $e');
      _showSnack('Network error');
      setState(() => _statusMsg = 'Network error');
      return;
    }

    // ── 3. Start gyroscope session ── (bilkul same rakha)

    // ── 5. Request MediaProjection with RTMP details ──
    try {
      await _overlayChannel.invokeMethod('requestMediaProjection', {
        'targetPackageName': 'com.king.candycrushsaga',
        'streamTitle': 'candy_crush',
        'youtubeUrl': '',
        'tiktokUrl': '',
        'facebookStreamUrl': '',
        'gameId': 'candy_crush',
        'playerId': deviceId,
        'audio': 'true',
        'videoEnabled': 'false',
        'streamKey': '$streamKey',
        'twitchKey': '',
        'playerName': "deviceId",
        'gameName': 'Candy Crush',
        'minimumStreamSpeed': '1',
        'badConnectionTimeout': '30',
        'streamUrl': '$rtmpUrl/$streamKey',
      });
      debugPrint(
        '✅ MediaProjection requested with RTMP: $rtmpUrl / $streamKey',
      );
    } catch (e) {
      debugPrint('❌ MediaProjection error: $e');
      _showSnack('Failed to start streaming');
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (_socket != null && _socketConnected) {
      _socket!.emit('startStreaming', {
        'streamTitle': 'candy_crush',
        'g_id': 26, // ← your game ID (int) — update if different
        'p_id': 14086, // ← player/device ID
        'streamKey': streamKey,
      });
      debugPrint('📡 Socket emitted startStreaming with key: $streamKey');
    } else {
      debugPrint('⚠️ Socket not connected, retrying...');
      _socket?.onConnect((_) {
        _socket!.emit('startStreaming', {
          'streamTitle': 'candy_crush',
          'g_id': 26,
          'p_id': 14086,
          'streamKey': streamKey,
        });
        debugPrint(
          '📡 Socket emitted startStreaming (retry) with key: $streamKey',
        );
      });
    }

    // ── 6. Overlay start karo ── (same)

    // ── 7. Game open karo ── (same)
    // await _openGame();

    final sessionId = await _sdk.startGame(
      gameId: 'candy_crush',
      samplingRate: GyroSamplingRate.game,
      autoLog: false,
      onData: (GyroData data) {
        if (!mounted) return;
        setState(() {
          _gx = data.x;
          _gy = data.y;
          _gz = data.z;
          _ax = data.ax;
          _ay = data.ay;
          _az = data.az; // ← ye add karo
          _phoneIdle = data.isIdle;
          _readingCount++;
        });
      },
      onSessionStart: (SessionInfo info) {
        if (!mounted) return;
        setState(() {
          _sessionId = info.sessionId;
          _isStreaming = true;
          _statusMsg = '🟢 Streaming active';
          _sessionStart = DateTime.now();
        });
        _startDurationTimer();
        _startBackendTimer();
      },
      onSessionStop: (SessionInfo info) {
        if (!mounted) return;
        setState(() {
          _lastSession = info;
          _isStreaming = false;
          _statusMsg = '✅ Session completed!';
          _readingCount = 0;
          _gx = 0;
          _gy = 0;
          _gz = 0;
        });
        _durationTimer?.cancel();
      },
      onPhoneState: (PhoneState state, String sid) {
        if (!mounted) return;
        setState(() => _phoneIdle = state == PhoneState.idle);
      },
    );

    setState(() => _sessionId = sessionId ?? '');

    _showSnack2('Recording started — will auto-stop in 5 minutes');

    Future.delayed(const Duration(minutes: 5), () {
      if (_isStreaming && mounted) {
        _stopGame();
        _showSnack2('Recording auto-stopped after 5 minutes');
      }
    });
    // try {
    //   await _overlayChannel.invokeMethod('startOverlay');
    // } catch (_) {}
  }

  

// Sirf sensors — no streaming, no API
Future<void> _startSensors() async {
  await _sdk.startGame(
    gameId: 'sensors_only',
    samplingRate: GyroSamplingRate.game,
    autoLog: false,
    onData: (GyroData data) {
      if (!mounted) return;
      setState(() {
        _gx = data.x; _gy = data.y; _gz = data.z;
        _ax = data.ax; _ay = data.ay; _az = data.az;
        _phoneIdle = data.isIdle;
        _readingCount++;
      });
    },
    onSessionStart: (SessionInfo info) {
      if (!mounted) return;
      setState(() { _sessionId = info.sessionId; });
    },
    onSessionStop: (SessionInfo info) {},
    onPhoneState: (PhoneState state, String sid) {
      if (!mounted) return;
      setState(() => _phoneIdle = state == PhoneState.idle);
    },
  );
  debugPrint('✅ Sensors started (no streaming)');
}

  Future<void> _stopGame() async {
    // ── Save duration before reset ──
    String finalDuration = _duration;
    if (_sessionStart != null) {
      final diff = DateTime.now().difference(_sessionStart!).inSeconds;
      finalDuration = '${diff}s';
    }
    // ── Stop screen recording/streaming ──
    try {
      await _overlayChannel.invokeMethod('stopStreaming');
      debugPrint('🛑 Streaming stopped');
    } catch (_) {}

    // ── Tell backend stream ended ──
    if (_socket != null && _socketConnected) {
      _socket!.emit('endStream', {
        'p_id': 14086, // ✅ FIXED — numeric player ID
      });
      debugPrint('📡 Socket emitted endStream');
    }

    // ── Stop gyroscope ──
    await _sdk.stopGame();

    // ── Stop overlay ──
    try {
      await _overlayChannel.invokeMethod('stopOverlay');
    } catch (_) {}

    // ── Disconnect socket ──

    _durationTimer?.cancel();
    _backendTimer?.cancel();
    setState(() {
      _isStreaming = false;
      if (_lastSession == null) {
        _statusMsg = '⏹ Stopped after $finalDuration';
        _duration = finalDuration; // ✅ keep last duration
      }
      _sessionStart = null;
    });
  }

  Future<void> _openGame() async {
    final appUri = Uri.parse('android-app://com.king.candycrushsaga');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      final storeUri = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.king.candycrushsaga',
      );
      await launchUrl(storeUri, mode: LaunchMode.externalApplication);
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sessionStart == null || !mounted) return;
      final diff = DateTime.now().difference(_sessionStart!).inSeconds;
      setState(() => _duration = '${diff}s');
    });
  }

  void _startBackendTimer() {
    _backendTimer?.cancel();
    _backendTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!_isStreaming) return;
      _sendToBackend(
        GyroData(
          x: _gx,
          y: _gy,
          z: _gz,
          ax: _ax,
          ay: _ay,
          az: _az,
          timestampNs: 0,
          isIdle: _phoneIdle,
        ),
      );
    });
  }

  // ── Send to Backend ──────────────────────────────────────────────────────
  Future<void> _sendToBackend(GyroData data) async {
   final info = await _overlayChannel.invokeMethod('getDeviceInfo', {});
final deviceId = info['deviceId'] ?? '';
    final payload = {
      'deviceId': deviceId,
      'organization_id': '1',
      'product_id': '1',
      'gyro_x': data.x,
      'gyro_y': data.y,
      'gyro_z': data.z,
      'accel_x': data.ax,
      'accel_y': data.ay,
      'accel_z': data.az,
    };

    print('📡 Sending to backend: $payload');

    try {
      final response = await http.post(
        Uri.parse("$_backendUrl/activity/update"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      print('✅ Backend response: ${response.body}');
      print('✅ Backend response: ${response.statusCode}');
    } catch (e) {
      print('❌ Backend error: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  void _showSnack2(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF667EEA),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Face Recognition Flow ───────────────────────────────────────────────

  Future<void> _startFaceRecognition() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('persistent_device_id') ?? '';

    var camStatus = await Permission.camera.status;
    if (!camStatus.isGranted) {
      camStatus = await Permission.camera.request();
      if (!camStatus.isGranted) {
        _showSnack('Camera permission required for facial recognition');
        return; // block
      }
    }

    final faceService = FaceService(
      apiUrl: '$_backendUrl/facial/save-embedding',
    );

    while (true) {
      dynamic result;
      try {
        result = await _overlayChannel.invokeMethod('openFaceRecognition', {});
      } catch (e) {
        debugPrint('❌ Face SDK error: $e');
        _showSnack('Failed to open camera. Check AndroidManifest.');
        return;
      }

      if (result == null || result['success'] != true) {
        debugPrint('❌ Face capture cancelled');
        return;
      }

      final imagePath = result['imagePath'] ?? '';
      if (imagePath.isEmpty) {
        _showSnack('No image captured');
        return;
      }
      debugPrint('📸 Face captured: $imagePath');

      if (mounted) _showFaceLoader();

      final apiResult = await faceService.uploadFace(
        imagePath: imagePath,
        fields: {
          'organization_id': '1',
          'product_id': '1',
          'device_id': deviceId,
          'username': "Bilal",

          // 'playerId': '14086',
          // 'streamKey': _streamKey,
        },
      );

      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      debugPrint('📡 result $apiResult');
      // if (apiResult['success'] != true) {
      //   _showSnack('Upload failed: ${apiResult['error']}');
      //   return;
      // }

      final status = apiResult['httpCode'] ?? -1;
      final message = apiResult['message'] ?? '';

      debugPrint('📡 Face API: status==$status, msg=$message');

      if (status == 200 || status == 202) {
        _showSnack2('✅ ${message.isNotEmpty ? message : "Face registered!"}');
        return;
      }

      // if (status == 401  ) {
      //   _showSnack2('✅ ${message.isNotEmpty ? message : "Face already registered!"}');
      //   return;
      // }

      // if (status == 402 || (status == 401 )) {
      //   _showSnack(message.isNotEmpty ? message : 'Please try again — only one face allowed');
      //   await Future.delayed(const Duration(seconds: 1));
      //   continue;
      // }
      if (status == 400) {
        _showSnack(
          '${apiResult['message'].isNotEmpty ? apiResult['message'] : " No face detected in the image"}',
        );
        return;
      }

      _showSnack(message.isNotEmpty ? message : 'Something went wrong');
      return;
    }
  }

  void _showFaceLoader() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            width: 280,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A3E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF667EEA),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Analyzing your face...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'This may take a few minutes,\nplease don\'t close the app',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── KYC Flow ────────────────────────────────────────────────────────────

  Future<void> _startKycFlow() async {
    dynamic result;
    try {
      result = await _overlayChannel.invokeMethod('openKyc', {});
    } catch (e) {
      debugPrint('❌ KYC SDK error: $e');
      _showSnack('Failed to open KYC. Check AndroidManifest.');
      return;
    }

    if (result == null || result['success'] != true) {
      debugPrint('❌ KYC cancelled');
      return;
    }

    final docType = result['docType'] ?? '';
    final frontPhoto = result['frontPhoto'] ?? '';
    final backPhoto = result['backPhoto'] ?? '';
    final selfieVideo = result['selfieVideo'] ?? '';

    debugPrint(
      '📁 KYC: docType=$docType front=$frontPhoto back=$backPhoto video=$selfieVideo',
    );

    final kycService = KycService(
      baseUrl: 'https://production.earnscape.io/api',
      playerId: '14086',
    );

    if (frontPhoto.isNotEmpty) {
      _showSnack2('Uploading document...');
      final docUpload = await kycService.uploadDocument(
        docType: docType,
        frontPhotoPath: frontPhoto,
        backPhotoPath: backPhoto.isNotEmpty ? backPhoto : null,
      );
      if (docUpload['success'] != true) {
        _showSnack('Doc upload failed: ${docUpload['error']}');
        return;
      }
      debugPrint('✅ Doc uploaded');
    }

    if (selfieVideo.isNotEmpty) {
      _showSnack2('Uploading video...');
      final videoUpload = await kycService.uploadSelfieVideo(
        videoPath: selfieVideo,
      );
      if (videoUpload['success'] != true) {
        _showSnack('Video upload failed: ${videoUpload['error']}');
        return;
      }
      debugPrint('✅ Video uploaded');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ KYC uploaded successfully!'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

   bool isServiceActive(String serviceName) {
    if (appConfig == null) return false;
    try {
      return appConfig!.data.services
          .firstWhere((s) => s.name == serviceName)
          .isActive;
    } catch (e) {
      return false;
    }
    
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _glowController.dispose();
    _durationTimer?.cancel();

    _sdk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Client 3 (NX-994)"),
        actions: [
          if (_isStreaming)
            TextButton(
              onPressed: () => _stopGame(),
              child: Text(
                "Stop Recording",
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),

            
 if (isServiceActive('streaming'))
          if (!_isStreaming)
            TextButton(
              onPressed: () => _startGame(),
              child: Text(
                "Start recording",
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF050510), Color(0xFF0A0A20), Color(0xFF050515)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // const SizedBox(height: 24),

                  // const SizedBox(height: 20),

 if (isServiceActive('facial_recognition'))
                  ElevatedButton(
                    onPressed: () => _startFaceRecognition(),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Add Facial Recognition',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),

 if (isServiceActive('facial_recognition'))
                  const SizedBox(height: 12),

                  // ElevatedButton(
                  //   onPressed: () => _startKycFlow(),
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(8.0),
                  //     child: Text('Open KYC Verification', style: TextStyle(color: Colors.white, fontSize: 20)),
                  //   ),
                  // ),

                  
 if (isServiceActive('streaming'))
                  ElevatedButton(
                    onPressed: () => _openDriveRecording(),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'My Recording',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
if (isServiceActive('streaming'))
                  SizedBox(height: 20),
                  
 if (isServiceActive('transaction'))
                  ElevatedButton(
                    onPressed: () async {
                     // fetchProducts();
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddTransactionScreen(backendUrl: _backendUrl),
                        ),
                      );
                      if (result == true) {
                        setState(() => _hasTransactions = true);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Add Transaction',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                  
 if (isServiceActive('transaction'))
                  const SizedBox(height: 12),
                                    
 if (isServiceActive('transaction'))
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TransactionHistoryScreen(backendUrl: _backendUrl),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Transaction History',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                                    
 if (isServiceActive('transaction'))
                  const SizedBox(height: 12),

                  if (isServiceActive('gyroscope'))
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GyroscopeScreen(
                          gx: _gx,
                          gy: _gy,
                          gz: _gz,
                          ax: _ax,
                          ay: _ay,
                          az: _az,
                          hasGyro: _hasGyro,
                          backendUrl: _backendUrl,
                          gyroStream: _sdk.gyroStream, // ← live stream
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Gyroscope Data',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                  if (isServiceActive('gyroscope'))
                  const SizedBox(height: 12),

                  if (isServiceActive('accelerometer'))
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AccelerometerScreen(
                          ax: _ax,
                          ay: _ay,
                          az: _az,
                          gx: _gx,
                          gy: _gy,
                          gz: _gz,
                          backendUrl: _backendUrl,
                          gyroStream: _sdk.gyroStream, // ← live stream
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Accelerometer Data',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                  if (isServiceActive('accelerometer'))
                  const SizedBox(height: 12),

                  if (isServiceActive('location'))
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DeviceInfoScreen(),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Device Id and Location',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
 
                 if (!isServiceActive("streaming") &&
    !isServiceActive("facial_recognition") &&
    !isServiceActive("gyroscope") &&
    !isServiceActive("accelerometer") &&
    !isServiceActive("transaction") &&
    !isServiceActive("location"))
                   
                    
                       Center(
                        child: Text(
                          textAlign: TextAlign.center,
                          'No Product is Active',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
                     
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLaunchButton() {
    return GestureDetector(
      onTap: _startGame,
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF667EEA,
                ).withOpacity(0.4 + _glowAnim.value * 0.2),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text(
                'LAUNCH GAME',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Permission Bottom Sheet ──────────────────────────────────────────────────

class _PermissionBottomSheet extends StatelessWidget {
  final VoidCallback onProceed;
  final VoidCallback onCancel;

  const _PermissionBottomSheet({
    required this.onProceed,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D2B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withOpacity(0.15),
              border: Border.all(color: Colors.orange.withOpacity(0.4)),
            ),
            child: const Icon(Icons.layers, color: Colors.orange, size: 32),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Overlay Permission Required',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Proceed button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onProceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'PROCEED TO SETTINGS',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Cancel button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: onCancel,
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 14, color: Colors.white38),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
