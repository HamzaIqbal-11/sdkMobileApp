 
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gyroscope/deviceService.dart';
import 'package:gyroscope/gyroscopePlugin.dart';
import 'package:gyroscope_plugin/gyroscope_plugin.dart' hide GyroscopePlugin;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) => MaterialApp(
//     title: 'Gyro Runner',
//     debugShowCheckedModeBanner: false,
//     theme: ThemeData.dark().copyWith(
//       scaffoldBackgroundColor: const Color(0xFF050510),
//     ),
//     home: const HomeScreen(),
//   );
// }

// // ─── Home Screen ──────────────────────────────────────────────────────────────

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {

//   final _sdk = GyroscopePlugin();

//   // State
//   bool _isStreaming = false;
//   bool _hasGyro = false;
//   String _sessionId = '';
//   int _readingCount = 0;
//   double _gx = 0, _gy = 0, _gz = 0;
//   bool _phoneIdle = false;
//   String _statusMsg = 'Ready to play';
//   DateTime? _sessionStart;
//   String _duration = '0s';
//   Timer? _durationTimer;

//   // Animations
//   late AnimationController _pulseController;
//   late AnimationController _glowController;
//   late Animation<double> _pulseAnim;
//   late Animation<double> _glowAnim;

//   @override
//   void initState() {
//     super.initState();

//     _pulseController = AnimationController(
//       vsync: this, duration: const Duration(milliseconds: 1200),
//     )..repeat(reverse: true);

//     _glowController = AnimationController(
//       vsync: this, duration: const Duration(milliseconds: 2000),
//     )..repeat(reverse: true);

//     _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );
//     _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
//       CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
//     );

//     _checkGyro();
//   }

//   Future<void> _checkGyro() async {
//     final has = await _sdk.hasGyroscope();
//     setState(() => _hasGyro = has);
//   }

//   // ── Start: Streaming ON + Subway Surfers OPEN ──────────────────────────────

//   Future<void> _startGame() async {
//     if (!_hasGyro) {
//       _showSnack('No gyroscope found on this device!');
//       return;
//     }

//     // Start session + gyroscope
//     final sessionId = await _sdk.startGame(
//       gameId: 'subway_surfers',
//       samplingRate: GyroSamplingRate.game,
//       autoLog: false,

//       onData: (GyroData data) {
//         if (!mounted) return;
//         setState(() {
//           _gx = data.x;
//           _gy = data.y;
//           _gz = data.z;
//           _phoneIdle = data.isIdle;
//           _readingCount++;
//         });
//       },

//       onSessionStart: (SessionInfo info) {
//         if (!mounted) return;
//         setState(() {
//           _sessionId = info.sessionId;
//           _isStreaming = true;
//           _statusMsg = '🟢 Streaming active';
//           _sessionStart = DateTime.now();
//         });
//         _startDurationTimer();
//       },

//       onSessionStop: (SessionInfo info) {
//         if (!mounted) return;
//         setState(() {
//           _isStreaming = false;
//           _statusMsg = '🔴 Session ended — ${info.totalReadings} readings saved';
//           _readingCount = 0;
//           _gx = 0; _gy = 0; _gz = 0;
//         });
//         _durationTimer?.cancel();
//       },

//       onPhoneState: (PhoneState state, String sid) {
//         if (!mounted) return;
//         setState(() => _phoneIdle = state == PhoneState.idle);
//       },
//     );

//     setState(() => _sessionId = sessionId ?? '');

//     // ✅ Subway Surfers open karo
//     await _openSubwaySurfers();
//   }

//   // ── Stop: Streaming OFF ────────────────────────────────────────────────────

//   Future<void> _stopGame() async {
//     await _sdk.stopGame();
//     _durationTimer?.cancel();
//     setState(() {
//       _isStreaming = false;
//       _statusMsg = '⏹ Stopped';
//       _duration = '0s';
//       _sessionStart = null;
//     });
//   }

//   // ── Open Subway Surfers ────────────────────────────────────────────────────

//   Future<void> _openSubwaySurfers() async {
//     // Direct app open karo (Android)
//     final appUri = Uri.parse('android-app://com.kiloo.subwaysurf');

//     if (await canLaunchUrl(appUri)) {
//       await launchUrl(appUri);
//     } else {
//       // Agar installed nahi toh Play Store pe bhejo
//       final storeUri = Uri.parse(
//         'https://play.google.com/store/apps/details?id=com.kiloo.subwaysurf',
//       );
//       await launchUrl(storeUri, mode: LaunchMode.externalApplication);
//       _showSnack('Subway Surfers not installed — opening Play Store');
//     }
//   }

//   void _startDurationTimer() {
//     _durationTimer?.cancel();
//     _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (_sessionStart == null || !mounted) return;
//       final diff = DateTime.now().difference(_sessionStart!).inSeconds;
//       setState(() => _duration = '${diff}s');
//     });
//   }

//   void _showSnack(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
//     );
//   }

//   @override
//   void dispose() {
//     _pulseController.dispose();
//     _glowController.dispose();
//     _durationTimer?.cancel();
//     _sdk.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFF050510), Color(0xFF0A0A20), Color(0xFF050515)],
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: Column(
//               children: [

//                 const SizedBox(height: 24),

//                 // ── Header ──
//                 Row(
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text('GYRO', style: TextStyle(
//                           fontSize: 32, fontWeight: FontWeight.w900,
//                           color: Colors.white, letterSpacing: 6,
//                           shadows: [Shadow(color: Color(0xFF00FFFF), blurRadius: 16)],
//                         )),
//                         const Text('RUNNER', style: TextStyle(
//                           fontSize: 14, fontWeight: FontWeight.w300,
//                           color: Color(0xFF00FFFF), letterSpacing: 10,
//                         )),
//                       ],
//                     ),
//                     const Spacer(),
//                     // Streaming indicator
//                     AnimatedBuilder(
//                       animation: _glowAnim,
//                       builder: (_, __) => Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(20),
//                           color: (_isStreaming ? Colors.green : Colors.grey).withOpacity(0.1),
//                           border: Border.all(
//                             color: (_isStreaming ? Colors.green : Colors.grey)
//                                 .withOpacity(_isStreaming ? _glowAnim.value : 0.3),
//                           ),
//                           boxShadow: _isStreaming ? [BoxShadow(
//                             color: Colors.green.withOpacity(_glowAnim.value * 0.4),
//                             blurRadius: 12,
//                           )] : [],
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Container(
//                               width: 8, height: 8,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: _isStreaming ? Colors.green : Colors.grey,
//                                 boxShadow: _isStreaming ? [BoxShadow(
//                                   color: Colors.green.withOpacity(0.8), blurRadius: 6,
//                                 )] : [],
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             Text(
//                               _isStreaming ? 'LIVE' : 'OFFLINE',
//                               style: TextStyle(
//                                 fontSize: 11, fontWeight: FontWeight.bold,
//                                 color: _isStreaming ? Colors.green : Colors.grey,
//                                 letterSpacing: 2,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 32),

//                 // ── Game Card ──
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(24),
//                     gradient: LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: [
//                         const Color(0xFF1A1A3E),
//                         const Color(0xFF0D0D2B),
//                       ],
//                     ),
//                     border: Border.all(color: const Color(0xFF00FFFF).withOpacity(0.15)),
//                     boxShadow: [
//                       BoxShadow(
//                         color: const Color(0xFF00FFFF).withOpacity(0.05),
//                         blurRadius: 30, spreadRadius: 2,
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       // Game icon
//                       AnimatedBuilder(
//                         animation: _pulseAnim,
//                         builder: (_, child) => Transform.scale(
//                           scale: _isStreaming ? _pulseAnim.value : 1.0,
//                           child: child,
//                         ),
//                         child: Container(
//                           width: 100, height: 100,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(24),
//                             gradient: const LinearGradient(
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                               colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: const Color(0xFF667EEA).withOpacity(
//                                     _isStreaming ? 0.6 : 0.3),
//                                 blurRadius: _isStreaming ? 24 : 12,
//                               ),
//                             ],
//                           ),
//                           child: const Center(
//                             child: Text('🏄', style: TextStyle(fontSize: 48)),
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 16),

//                       const Text('Subway Surfers', style: TextStyle(
//                         fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,
//                       )),
//                       const SizedBox(height: 4),
//                       Text(
//                         _isStreaming
//                             ? 'Game is running • Gyroscope active'
//                             : 'Tap to launch game & start tracking',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: _isStreaming ? Colors.greenAccent : Colors.white38,
//                         ),
//                       ),

//                       const SizedBox(height: 24),

//                       // ── Launch / Stop Button ──
//                       _isStreaming
//                           ? _buildStopButton()
//                           : _buildLaunchButton(),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 // ── Session Info ──
//                 if (_isStreaming) ...[
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(16),
//                       color: Colors.white.withOpacity(0.04),
//                       border: Border.all(color: Colors.white10),
//                     ),
//                     child: Column(
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             _InfoTile('DURATION', _duration, Colors.cyanAccent),
//                             _InfoTile('READINGS', '$_readingCount', const Color(0xFF00FFFF)),
//                             _InfoTile(
//                               'STATUS',
//                               _phoneIdle ? 'IDLE' : 'ACTIVE',
//                               _phoneIdle ? Colors.orange : Colors.greenAccent,
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         // Session ID
//                         Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(8),
//                             color: Colors.black.withOpacity(0.3),
//                           ),
//                           child: Text(
//                             'SESSION: ${_sessionId.length > 20 ? _sessionId.substring(0, 20) : _sessionId}...',
//                             style: const TextStyle(
//                               fontSize: 10, color: Colors.white30,
//                               fontFamily: 'monospace', letterSpacing: 1,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 16),

//                   // ── Gyro Bars ──
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(16),
//                       color: Colors.white.withOpacity(0.04),
//                       border: Border.all(color: Colors.white10),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text('GYROSCOPE', style: TextStyle(
//                           fontSize: 10, color: Colors.white38,
//                           letterSpacing: 3, fontWeight: FontWeight.bold,
//                         )),
//                         const SizedBox(height: 12),
//                         Row(children: [
//                           _GyroBar(label: 'X', value: _gx, color: Colors.redAccent),
//                           const SizedBox(width: 8),
//                           _GyroBar(label: 'Y', value: _gy, color: Colors.greenAccent),
//                           const SizedBox(width: 8),
//                           _GyroBar(label: 'Z', value: _gz, color: Colors.blueAccent),
//                         ]),
//                       ],
//                     ),
//                   ),
//                 ],

//                 const Spacer(),

//                 // ── Status message ──
//                 Text(
//                   _statusMsg,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: _isStreaming ? Colors.greenAccent.withOpacity(0.7) : Colors.white24,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLaunchButton() {
//     return GestureDetector(
//       onTap: _startGame,
//       child: AnimatedBuilder(
//         animation: _glowAnim,
//         builder: (_, __) => Container(
//           width: double.infinity,
//           height: 56,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             gradient: const LinearGradient(
//               colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: const Color(0xFF667EEA).withOpacity(0.4 + _glowAnim.value * 0.2),
//                 blurRadius: 20, spreadRadius: 1,
//               ),
//             ],
//           ),
//           child: const Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
//               SizedBox(width: 8),
//               Text('LAUNCH GAME', style: TextStyle(
//                 color: Colors.white, fontSize: 16,
//                 fontWeight: FontWeight.bold, letterSpacing: 2,
//               )),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStopButton() {
//     return GestureDetector(
//       onTap: _stopGame,
//       child: Container(
//         width: double.infinity,
//         height: 56,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           gradient: LinearGradient(
//             colors: [Colors.red.shade700, Colors.red.shade900],
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.red.withOpacity(0.4),
//               blurRadius: 20, spreadRadius: 1,
//             ),
//           ],
//         ),
//         child: const Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.stop_rounded, color: Colors.white, size: 28),
//             SizedBox(width: 8),
//             Text('STOP STREAMING', style: TextStyle(
//               color: Colors.white, fontSize: 16,
//               fontWeight: FontWeight.bold, letterSpacing: 2,
//             )),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─── Widgets ──────────────────────────────────────────────────────────────────

// class _InfoTile extends StatelessWidget {
//   final String label, value;
//   final Color color;
//   const _InfoTile(this.label, this.value, this.color);

//   @override
//   Widget build(BuildContext context) => Column(
//     children: [
//       Text(label, style: TextStyle(
//         fontSize: 9, color: color.withOpacity(0.6),
//         letterSpacing: 2, fontWeight: FontWeight.bold,
//       )),
//       const SizedBox(height: 4),
//       Text(value, style: TextStyle(
//         fontSize: 20, fontWeight: FontWeight.bold, color: color,
//       )),
//     ],
//   );
// }

// class _GyroBar extends StatelessWidget {
//   final String label;
//   final double value;
//   final Color color;
//   const _GyroBar({required this.label, required this.value, required this.color});

//   @override
//   Widget build(BuildContext context) {
//     final filled = (value.clamp(-3.0, 3.0) + 3.0) / 6.0;
//     return Expanded(
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(label, style: TextStyle(
//                 color: color, fontSize: 11, fontWeight: FontWeight.bold,
//               )),
//               Text(value.toStringAsFixed(2), style: TextStyle(
//                 color: color.withOpacity(0.7), fontSize: 10, fontFamily: 'monospace',
//               )),
//             ],
//           ),
//           const SizedBox(height: 4),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(4),
//             child: LinearProgressIndicator(
//               value: filled,
//               backgroundColor: color.withOpacity(0.1),
//               valueColor: AlwaysStoppedAnimation(color),
//               minHeight: 5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:gyroscope/gyroscopePlugin.dart';
// import 'package:gyroscope_plugin/gyroscope_plugin.dart' hide GyroscopePlugin;
// import 'package:url_launcher/url_launcher.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) => MaterialApp(
//     title: 'Gyro Runner',
//     debugShowCheckedModeBanner: false,
//     theme: ThemeData.dark().copyWith(
//       scaffoldBackgroundColor: const Color(0xFF050510),
//     ),
//     home: const HomeScreen(),
//   );
// }

// // ─── Home Screen ──────────────────────────────────────────────────────────────

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {

//   final _sdk = GyroscopePlugin();

//   // State
//   bool _isStreaming = false;
//   bool _hasGyro = false;
//   String _sessionId = '';
//   int _readingCount = 0;
//   double _gx = 0, _gy = 0, _gz = 0;
//   bool _phoneIdle = false;
//   String _statusMsg = 'Ready to play';
//   DateTime? _sessionStart;
//   String _duration = '0s';
//   Timer? _durationTimer;
  
//   // Track if we launched game while streaming
//   bool _gameWasLaunched = false;
  
//   // Session summary data
//   SessionInfo? _lastSession;

//   // Animations
//   late AnimationController _pulseController;
//   late AnimationController _glowController;
//   late Animation<double> _pulseAnim;
//   late Animation<double> _glowAnim;

//   @override
//   void initState() {
//     super.initState();
    
//     // Add lifecycle observer
//     WidgetsBinding.instance.addObserver(this);

//     _pulseController = AnimationController(
//       vsync: this, duration: const Duration(milliseconds: 1200),
//     )..repeat(reverse: true);

//     _glowController = AnimationController(
//       vsync: this, duration: const Duration(milliseconds: 2000),
//     )..repeat(reverse: true);

//     _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );
//     _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
//       CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
//     );

//     _checkGyro();
//   }

//   // ✅ Lifecycle detection - jab app foreground mein wapis aaye
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
    
//     if (state == AppLifecycleState.paused) {
//       // App background mein gaya (game khula)
//       if (_isStreaming) {
//         _gameWasLaunched = true;
//       }
//     } else if (state == AppLifecycleState.resumed) {
//       // App foreground mein wapis aaya
//       if (_gameWasLaunched && _isStreaming) {
//         // Automatically stop karo
//         _stopGame();
//         _gameWasLaunched = false;
//       }
//     }
//   }

//   Future<void> _checkGyro() async {
//     final has = await _sdk.hasGyroscope();
//     setState(() => _hasGyro = has);
//   }

//   // ── Start: Streaming ON + Subway Surfers OPEN ──────────────────────────────

//   Future<void> _startGame() async {
//     if (!_hasGyro) {
//       _showSnack('No gyroscope found on this device!');
//       return;
//     }

//     // Clear previous session
//     setState(() => _lastSession = null);

//     // Start session + gyroscope
//     final sessionId = await _sdk.startGame(
//       gameId: 'subway_surfers',
//       samplingRate: GyroSamplingRate.game,
//       autoLog: false,

//       onData: (GyroData data) {
//         if (!mounted) return;
//         setState(() {
//           _gx = data.x;
//           _gy = data.y;
//           _gz = data.z;
//           _phoneIdle = data.isIdle;
//           _readingCount++;
//         });
//       },

//       onSessionStart: (SessionInfo info) {
//         if (!mounted) return;
//         setState(() {
//           _sessionId = info.sessionId;
//           _isStreaming = true;
//           _statusMsg = '🟢 Streaming active';
//           _sessionStart = DateTime.now();
//         });
//         _startDurationTimer();
//       },

//       onSessionStop: (SessionInfo info) {
//         if (!mounted) return;
//         setState(() {
//           _lastSession = info;
//           _isStreaming = false;
//           _statusMsg = '✅ Session completed!';
//           _readingCount = 0;
//           _gx = 0; _gy = 0; _gz = 0;
//         });
//         _durationTimer?.cancel();
//       },

//       onPhoneState: (PhoneState state, String sid) {
//         if (!mounted) return;
//         setState(() => _phoneIdle = state == PhoneState.idle);
//       },
//     );

//     setState(() => _sessionId = sessionId ?? '');

//     // ✅ Subway Surfers open karo
//     await _openSubwaySurfers();
//   }

//   // ── Stop: Streaming OFF ────────────────────────────────────────────────────

//   Future<void> _stopGame() async {
//     await _sdk.stopGame();
//     _durationTimer?.cancel();
//     setState(() {
//       _isStreaming = false;
//       if (_lastSession == null) {
//         _statusMsg = '⏹ Stopped';
//       }
//       _duration = '0s';
//       _sessionStart = null;
//     });
//   }

//   // ── Open Subway Surfers ────────────────────────────────────────────────────

//   Future<void> _openSubwaySurfers() async {
//     // Direct app open karo (Android)
//     final appUri = Uri.parse('android-app://com.kiloo.subwaysurf');

//     if (await canLaunchUrl(appUri)) {
//       await launchUrl(appUri);
//     } else {
//       // Agar installed nahi toh Play Store pe bhejo
//       final storeUri = Uri.parse(
//         'https://play.google.com/store/apps/details?id=com.kiloo.subwaysurf',
//       );
//       await launchUrl(storeUri, mode: LaunchMode.externalApplication);
//       _showSnack('Subway Surfers not installed — opening Play Store');
//     }
//   }

//   void _startDurationTimer() {
//     _durationTimer?.cancel();
//     _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (_sessionStart == null || !mounted) return;
//       final diff = DateTime.now().difference(_sessionStart!).inSeconds;
//       setState(() => _duration = '${diff}s');
//     });
//   }

//   void _showSnack(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
//     );
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _pulseController.dispose();
//     _glowController.dispose();
//     _durationTimer?.cancel();
//     _sdk.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFF050510), Color(0xFF0A0A20), Color(0xFF050515)],
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: Column(
//               children: [

//                 const SizedBox(height: 24),

//                 // ── Header ──
//                 Row(
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text('GYRO', style: TextStyle(
//                           fontSize: 32, fontWeight: FontWeight.w900,
//                           color: Colors.white, letterSpacing: 6,
//                           shadows: [Shadow(color: Color(0xFF00FFFF), blurRadius: 16)],
//                         )),
//                         const Text('RUNNER', style: TextStyle(
//                           fontSize: 14, fontWeight: FontWeight.w300,
//                           color: Color(0xFF00FFFF), letterSpacing: 10,
//                         )),
//                       ],
//                     ),
//                     const Spacer(),
//                     // Streaming indicator
//                     AnimatedBuilder(
//                       animation: _glowAnim,
//                       builder: (_, __) => Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(20),
//                           color: (_isStreaming ? Colors.green : Colors.grey).withOpacity(0.1),
//                           border: Border.all(
//                             color: (_isStreaming ? Colors.green : Colors.grey)
//                                 .withOpacity(_isStreaming ? _glowAnim.value : 0.3),
//                           ),
//                           boxShadow: _isStreaming ? [BoxShadow(
//                             color: Colors.green.withOpacity(_glowAnim.value * 0.4),
//                             blurRadius: 12,
//                           )] : [],
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Container(
//                               width: 8, height: 8,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: _isStreaming ? Colors.green : Colors.grey,
//                                 boxShadow: _isStreaming ? [BoxShadow(
//                                   color: Colors.green.withOpacity(0.8), blurRadius: 6,
//                                 )] : [],
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             Text(
//                               _isStreaming ? 'LIVE' : 'OFFLINE',
//                               style: TextStyle(
//                                 fontSize: 11, fontWeight: FontWeight.bold,
//                                 color: _isStreaming ? Colors.green : Colors.grey,
//                                 letterSpacing: 2,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 32),

//                 // ── Game Card ──
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(24),
//                     gradient: LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: [
//                         const Color(0xFF1A1A3E),
//                         const Color(0xFF0D0D2B),
//                       ],
//                     ),
//                     border: Border.all(color: const Color(0xFF00FFFF).withOpacity(0.15)),
//                     boxShadow: [
//                       BoxShadow(
//                         color: const Color(0xFF00FFFF).withOpacity(0.05),
//                         blurRadius: 30, spreadRadius: 2,
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       // Game icon
//                       AnimatedBuilder(
//                         animation: _pulseAnim,
//                         builder: (_, child) => Transform.scale(
//                           scale: _isStreaming ? _pulseAnim.value : 1.0,
//                           child: child,
//                         ),
//                         child: Container(
//                           width: 100, height: 100,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(24),
//                             gradient: const LinearGradient(
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                               colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: const Color(0xFF667EEA).withOpacity(
//                                     _isStreaming ? 0.6 : 0.3),
//                                 blurRadius: _isStreaming ? 24 : 12,
//                               ),
//                             ],
//                           ),
//                           child: const Center(
//                             child: Text('🏄', style: TextStyle(fontSize: 48)),
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 16),

//                       const Text('Subway Surfers', style: TextStyle(
//                         fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,
//                       )),
//                       const SizedBox(height: 4),
//                       Text(
//                         _isStreaming
//                             ? 'Game is running • Return to stop'
//                             : 'Tap to launch game & start tracking',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: _isStreaming ? Colors.greenAccent : Colors.white38,
//                         ),
//                       ),

//                       const SizedBox(height: 24),

//                       // ── Launch Button (only show when not streaming) ──
//                       if (!_isStreaming) _buildLaunchButton(),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 // ── Live Session Info ──
//                 if (_isStreaming) ...[
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(16),
//                       color: Colors.white.withOpacity(0.04),
//                       border: Border.all(color: Colors.white10),
//                     ),
//                     child: Column(
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             _InfoTile('DURATION', _duration, Colors.cyanAccent),
//                             _InfoTile('READINGS', '$_readingCount', const Color(0xFF00FFFF)),
//                             _InfoTile(
//                               'STATUS',
//                               _phoneIdle ? 'IDLE' : 'ACTIVE',
//                               _phoneIdle ? Colors.orange : Colors.greenAccent,
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         // Session ID
//                         Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(8),
//                             color: Colors.black.withOpacity(0.3),
//                           ),
//                           child: Text(
//                             'SESSION: ${_sessionId.length > 20 ? _sessionId.substring(0, 20) : _sessionId}...',
//                             style: const TextStyle(
//                               fontSize: 10, color: Colors.white30,
//                               fontFamily: 'monospace', letterSpacing: 1,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 16),

//                   // ── Gyro Bars ──
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(16),
//                       color: Colors.white.withOpacity(0.04),
//                       border: Border.all(color: Colors.white10),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text('GYROSCOPE', style: TextStyle(
//                           fontSize: 10, color: Colors.white38,
//                           letterSpacing: 3, fontWeight: FontWeight.bold,
//                         )),
//                         const SizedBox(height: 12),
//                         Row(children: [
//                           _GyroBar(label: 'X', value: _gx, color: Colors.redAccent),
//                           const SizedBox(width: 8),
//                           _GyroBar(label: 'Y', value: _gy, color: Colors.greenAccent),
//                           const SizedBox(width: 8),
//                           _GyroBar(label: 'Z', value: _gz, color: Colors.blueAccent),
//                         ]),
//                       ],
//                     ),
//                   ),
//                 ],

//                 // ── Session Summary (after stop) ──
//                 if (!_isStreaming && _lastSession != null) ...[
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(16),
//                       gradient: const LinearGradient(
//                         colors: [Color(0xFF1A4D2E), Color(0xFF0D2818)],
//                       ),
//                       border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
//                     ),
//                     child: Column(
//                       children: [
//                         const Icon(Icons.check_circle, color: Colors.greenAccent, size: 48),
//                         const SizedBox(height: 12),
//                         const Text('Session Complete!', style: TextStyle(
//                           fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent,
//                         )),
//                         const SizedBox(height: 16),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceAround,
//                           children: [
//                             _SummaryTile(
//                               'Duration',
//                               '${(_lastSession!.durationMs ?? 0) ~/ 1000}s',
//                               Icons.timer,
//                             ),
//                             _SummaryTile(
//                               'Readings',
//                               '${_lastSession!.totalReadings ?? 0}',
//                               Icons.sensors,
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           'Session ID: ${_lastSession!.sessionId.substring(0, 12)}...',
//                           style: const TextStyle(fontSize: 10, color: Colors.white30),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],

//                 const Spacer(),

//                 // ── Status message ──
//                 Text(
//                   _statusMsg,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: _isStreaming ? Colors.greenAccent.withOpacity(0.7) : Colors.white24,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLaunchButton() {
//     return GestureDetector(
//       onTap: _startGame,
//       child: AnimatedBuilder(
//         animation: _glowAnim,
//         builder: (_, __) => Container(
//           width: double.infinity,
//           height: 56,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             gradient: const LinearGradient(
//               colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: const Color(0xFF667EEA).withOpacity(0.4 + _glowAnim.value * 0.2),
//                 blurRadius: 20, spreadRadius: 1,
//               ),
//             ],
//           ),
//           child: const Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
//               SizedBox(width: 8),
//               Text('LAUNCH GAME', style: TextStyle(
//                 color: Colors.white, fontSize: 16,
//                 fontWeight: FontWeight.bold, letterSpacing: 2,
//               )),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─── Widgets ──────────────────────────────────────────────────────────────────

// class _InfoTile extends StatelessWidget {
//   final String label, value;
//   final Color color;
//   const _InfoTile(this.label, this.value, this.color);

//   @override
//   Widget build(BuildContext context) => Column(
//     children: [
//       Text(label, style: TextStyle(
//         fontSize: 9, color: color.withOpacity(0.6),
//         letterSpacing: 2, fontWeight: FontWeight.bold,
//       )),
//       const SizedBox(height: 4),
//       Text(value, style: TextStyle(
//         fontSize: 20, fontWeight: FontWeight.bold, color: color,
//       )),
//     ],
//   );
// }

// class _SummaryTile extends StatelessWidget {
//   final String label, value;
//   final IconData icon;
//   const _SummaryTile(this.label, this.value, this.icon);

//   @override
//   Widget build(BuildContext context) => Column(
//     children: [
//       Icon(icon, color: Colors.greenAccent.withOpacity(0.7), size: 24),
//       const SizedBox(height: 4),
//       Text(value, style: const TextStyle(
//         fontSize: 22, fontWeight: FontWeight.bold, color: Colors.greenAccent,
//       )),
//       Text(label, style: TextStyle(
//         fontSize: 11, color: Colors.greenAccent.withOpacity(0.6),
//       )),
//     ],
//   );
// }

// class _GyroBar extends StatelessWidget {
//   final String label;
//   final double value;
//   final Color color;
//   const _GyroBar({required this.label, required this.value, required this.color});

//   @override
//   Widget build(BuildContext context) {
//     final filled = (value.clamp(-3.0, 3.0) + 3.0) / 6.0;
//     return Expanded(
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(label, style: TextStyle(
//                 color: color, fontSize: 11, fontWeight: FontWeight.bold,
//               )),
//               Text(value.toStringAsFixed(2), style: TextStyle(
//                 color: color.withOpacity(0.7), fontSize: 10, fontFamily: 'monospace',
//               )),
//             ],
//           ),
//           const SizedBox(height: 4),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(4),
//             child: LinearProgressIndicator(
//               value: filled,
//               backgroundColor: color.withOpacity(0.1),
//               valueColor: AlwaysStoppedAnimation(color),
//               minHeight: 5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

 

// // ✅ Overlay service channel
// const _overlayChannel = MethodChannel('gyroscope_plugin/overlay');

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) => MaterialApp(
//     title: 'Gyro Runner',
//     debugShowCheckedModeBanner: false,
//     theme: ThemeData.dark().copyWith(
//       scaffoldBackgroundColor: const Color(0xFF050510),
//     ),
//     home: const HomeScreen(),
//   );
// }

// // ─── Home Screen ──────────────────────────────────────────────────────────────

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {

//   final _sdk = GyroscopePlugin();

//   // State
//   bool _isStreaming = false;
//   bool _hasGyro = false;
//   String _sessionId = '';
//   int _readingCount = 0;
//   double _gx = 0, _gy = 0, _gz = 0;
//   bool _phoneIdle = false;
//   String _statusMsg = 'Ready to play';
//   DateTime? _sessionStart;
//   String _duration = '0s';
//   Timer? _durationTimer;
  
//   // Track if we launched game while streaming
//   bool _gameWasLaunched = false;
  
//   // Session summary data
//   SessionInfo? _lastSession;

//   // Animations
//   late AnimationController _pulseController;
//   late AnimationController _glowController;
//   late Animation<double> _pulseAnim;
//   late Animation<double> _glowAnim;

//   @override
//   void initState() {
//     super.initState();
    
//     // Add lifecycle observer
//     WidgetsBinding.instance.addObserver(this);

//     _pulseController = AnimationController(
//       vsync: this, duration: const Duration(milliseconds: 1200),
//     )..repeat(reverse: true);

//     _glowController = AnimationController(
//       vsync: this, duration: const Duration(milliseconds: 2000),
//     )..repeat(reverse: true);

//     _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );
//     _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
//       CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
//     );

//     _checkGyro();
//   }

//   // ✅ Lifecycle detection - jab app foreground mein wapis aaye
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
    
//     if (state == AppLifecycleState.paused) {
//       // App background mein gaya (game khula)
//       if (_isStreaming) {
//         _gameWasLaunched = true;
//       }
//     } else if (state == AppLifecycleState.resumed) {
//       // App foreground mein wapis aaya
//       if (_gameWasLaunched && _isStreaming) {
//         // Automatically stop karo
//         _stopGame();
//         _gameWasLaunched = false;
//       }
//     }
//   }

//   Future<void> _checkGyro() async {
//     final has = await _sdk.hasGyroscope();
//     setState(() => _hasGyro = has);
//   }

//   // ── Start: Streaming ON + Subway Surfers OPEN ──────────────────────────────

//   Future<void> _startGame() async {
//     if (!_hasGyro) {
//       _showSnack('No gyroscope found on this device!');
//       return;
//     }

//     // Clear previous session
//     setState(() => _lastSession = null);

//     // Start session + gyroscope
//     final sessionId = await _sdk.startGame(
//       gameId: 'subway_surfers',
//       samplingRate: GyroSamplingRate.game,
//       autoLog: false,

//       onData: (GyroData data) {
//         if (!mounted) return;
//         setState(() {
//           _gx = data.x;
//           _gy = data.y;
//           _gz = data.z;
//           _phoneIdle = data.isIdle;
//           _readingCount++;
//         });
//       },

//       onSessionStart: (SessionInfo info) {
//         if (!mounted) return;
//         setState(() {
//           _sessionId = info.sessionId;
//           _isStreaming = true;
//           _statusMsg = '🟢 Streaming active';
//           _sessionStart = DateTime.now();
//         });
//         _startDurationTimer();
//       },

//       onSessionStop: (SessionInfo info) {
//         if (!mounted) return;
//         setState(() {
//           _lastSession = info;
//           _isStreaming = false;
//           _statusMsg = '✅ Session completed!';
//           _readingCount = 0;
//           _gx = 0; _gy = 0; _gz = 0;
//         });
//         _durationTimer?.cancel();
//       },

//       onPhoneState: (PhoneState state, String sid) {
//         if (!mounted) return;
//         setState(() => _phoneIdle = state == PhoneState.idle);
//       },
//     );

//     setState(() => _sessionId = sessionId ?? '');

//     // ✅ Subway Surfers open karo
//     await _openSubwaySurfers();

//     // ✅ Game ke upar overlay dikhao
//     await _startOverlay();
//   }

//   // ── Stop: Streaming OFF ────────────────────────────────────────────────────

//   Future<void> _stopGame() async {
//     await _sdk.stopGame();
//     await _stopOverlay(); // ✅ Overlay band karo
//     _durationTimer?.cancel();
//     setState(() {
//       _isStreaming = false;
//       if (_lastSession == null) {
//         _statusMsg = '⏹ Stopped';
//       }
//       _duration = '0s';
//       _sessionStart = null;
//     });
//   }

//   // ── Overlay ───────────────────────────────────────────────────────────────

//   Future<void> _startOverlay() async {
//     try {
//       await _overlayChannel.invokeMethod('startOverlay');
//     } catch (_) {}
//   }

//   Future<void> _stopOverlay() async {
//     try {
//       await _overlayChannel.invokeMethod('stopOverlay');
//     } catch (_) {}
//   }

//   // ── Open Subway Surfers ────────────────────────────────────────────────────

//   Future<void> _openSubwaySurfers() async {
//     final appUri = Uri.parse('android-app://com.kiloo.subwaysurf');

//     if (await canLaunchUrl(appUri)) {
//       await launchUrl(appUri);
//     } else {
//       final storeUri = Uri.parse(
//         'https://play.google.com/store/apps/details?id=com.kiloo.subwaysurf',
//       );
//       await launchUrl(storeUri, mode: LaunchMode.externalApplication);
//       _showSnack('Subway Surfers not installed — opening Play Store');
//     }
//   }

//   void _startDurationTimer() {
//     _durationTimer?.cancel();
//     _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (_sessionStart == null || !mounted) return;
//       final diff = DateTime.now().difference(_sessionStart!).inSeconds;
//       setState(() => _duration = '${diff}s');
//     });
//   }

//   void _showSnack(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
//     );
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _pulseController.dispose();
//     _glowController.dispose();
//     _durationTimer?.cancel();
//     _sdk.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFF050510), Color(0xFF0A0A20), Color(0xFF050515)],
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: Column(
//               children: [

//                 const SizedBox(height: 24),

//                 // ── Header ──
//                 Row(
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text('GYRO', style: TextStyle(
//                           fontSize: 32, fontWeight: FontWeight.w900,
//                           color: Colors.white, letterSpacing: 6,
//                           shadows: [Shadow(color: Color(0xFF00FFFF), blurRadius: 16)],
//                         )),
//                         const Text('RUNNER', style: TextStyle(
//                           fontSize: 14, fontWeight: FontWeight.w300,
//                           color: Color(0xFF00FFFF), letterSpacing: 10,
//                         )),
//                       ],
//                     ),
//                     const Spacer(),
//                     AnimatedBuilder(
//                       animation: _glowAnim,
//                       builder: (_, __) => Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(20),
//                           color: (_isStreaming ? Colors.green : Colors.grey).withOpacity(0.1),
//                           border: Border.all(
//                             color: (_isStreaming ? Colors.green : Colors.grey)
//                                 .withOpacity(_isStreaming ? _glowAnim.value : 0.3),
//                           ),
//                           boxShadow: _isStreaming ? [BoxShadow(
//                             color: Colors.green.withOpacity(_glowAnim.value * 0.4),
//                             blurRadius: 12,
//                           )] : [],
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Container(
//                               width: 8, height: 8,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: _isStreaming ? Colors.green : Colors.grey,
//                                 boxShadow: _isStreaming ? [BoxShadow(
//                                   color: Colors.green.withOpacity(0.8), blurRadius: 6,
//                                 )] : [],
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             Text(
//                               _isStreaming ? 'LIVE' : 'OFFLINE',
//                               style: TextStyle(
//                                 fontSize: 11, fontWeight: FontWeight.bold,
//                                 color: _isStreaming ? Colors.green : Colors.grey,
//                                 letterSpacing: 2,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 32),

//                 // ── Game Card ──
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(24),
//                     gradient: const LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: [Color(0xFF1A1A3E), Color(0xFF0D0D2B)],
//                     ),
//                     border: Border.all(color: const Color(0xFF00FFFF).withOpacity(0.15)),
//                     boxShadow: [
//                       BoxShadow(
//                         color: const Color(0xFF00FFFF).withOpacity(0.05),
//                         blurRadius: 30, spreadRadius: 2,
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       AnimatedBuilder(
//                         animation: _pulseAnim,
//                         builder: (_, child) => Transform.scale(
//                           scale: _isStreaming ? _pulseAnim.value : 1.0,
//                           child: child,
//                         ),
//                         child: Container(
//                           width: 100, height: 100,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(24),
//                             gradient: const LinearGradient(
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                               colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: const Color(0xFF667EEA).withOpacity(
//                                     _isStreaming ? 0.6 : 0.3),
//                                 blurRadius: _isStreaming ? 24 : 12,
//                               ),
//                             ],
//                           ),
//                           child: const Center(
//                             child: Text('🏄', style: TextStyle(fontSize: 48)),
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 16),

//                       const Text('Subway Surfers', style: TextStyle(
//                         fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,
//                       )),
//                       const SizedBox(height: 4),
//                       Text(
//                         _isStreaming
//                             ? 'Game is running • Return to stop'
//                             : 'Tap to launch game & start tracking',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: _isStreaming ? Colors.greenAccent : Colors.white38,
//                         ),
//                       ),

//                       const SizedBox(height: 24),

//                       if (!_isStreaming) _buildLaunchButton(),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 // ── Live Session Info ──
//                 if (_isStreaming) ...[
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(16),
//                       color: Colors.white.withOpacity(0.04),
//                       border: Border.all(color: Colors.white10),
//                     ),
//                     child: Column(
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             _InfoTile('DURATION', _duration, Colors.cyanAccent),
//                             _InfoTile('READINGS', '$_readingCount', const Color(0xFF00FFFF)),
//                             _InfoTile(
//                               'STATUS',
//                               _phoneIdle ? 'IDLE' : 'ACTIVE',
//                               _phoneIdle ? Colors.orange : Colors.greenAccent,
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(8),
//                             color: Colors.black.withOpacity(0.3),
//                           ),
//                           child: Text(
//                             'SESSION: ${_sessionId.length > 20 ? _sessionId.substring(0, 20) : _sessionId}...',
//                             style: const TextStyle(
//                               fontSize: 10, color: Colors.white30,
//                               fontFamily: 'monospace', letterSpacing: 1,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 16),

//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(16),
//                       color: Colors.white.withOpacity(0.04),
//                       border: Border.all(color: Colors.white10),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text('GYROSCOPE', style: TextStyle(
//                           fontSize: 10, color: Colors.white38,
//                           letterSpacing: 3, fontWeight: FontWeight.bold,
//                         )),
//                         const SizedBox(height: 12),
//                         Row(children: [
//                           _GyroBar(label: 'X', value: _gx, color: Colors.redAccent),
//                           const SizedBox(width: 8),
//                           _GyroBar(label: 'Y', value: _gy, color: Colors.greenAccent),
//                           const SizedBox(width: 8),
//                           _GyroBar(label: 'Z', value: _gz, color: Colors.blueAccent),
//                         ]),
//                       ],
//                     ),
//                   ),
//                 ],

//                 // ── Session Summary ──
//                 if (!_isStreaming && _lastSession != null) ...[
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(16),
//                       gradient: const LinearGradient(
//                         colors: [Color(0xFF1A4D2E), Color(0xFF0D2818)],
//                       ),
//                       border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
//                     ),
//                     child: Column(
//                       children: [
//                         const Icon(Icons.check_circle, color: Colors.greenAccent, size: 48),
//                         const SizedBox(height: 12),
//                         const Text('Session Complete!', style: TextStyle(
//                           fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent,
//                         )),
//                         const SizedBox(height: 16),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceAround,
//                           children: [
//                             _SummaryTile(
//                               'Duration',
//                               '${(_lastSession!.durationMs ?? 0) ~/ 1000}s',
//                               Icons.timer,
//                             ),
//                             _SummaryTile(
//                               'Readings',
//                               '${_lastSession!.totalReadings ?? 0}',
//                               Icons.sensors,
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           'Session ID: ${_lastSession!.sessionId.substring(0, 12)}...',
//                           style: const TextStyle(fontSize: 10, color: Colors.white30),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],

//                 const Spacer(),

//                 Text(
//                   _statusMsg,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: _isStreaming ? Colors.greenAccent.withOpacity(0.7) : Colors.white24,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLaunchButton() {
//     return GestureDetector(
//       onTap: _startGame,
//       child: AnimatedBuilder(
//         animation: _glowAnim,
//         builder: (_, __) => Container(
//           width: double.infinity,
//           height: 56,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             gradient: const LinearGradient(
//               colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: const Color(0xFF667EEA).withOpacity(0.4 + _glowAnim.value * 0.2),
//                 blurRadius: 20, spreadRadius: 1,
//               ),
//             ],
//           ),
//           child: const Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
//               SizedBox(width: 8),
//               Text('LAUNCH GAME', style: TextStyle(
//                 color: Colors.white, fontSize: 16,
//                 fontWeight: FontWeight.bold, letterSpacing: 2,
//               )),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─── Widgets ──────────────────────────────────────────────────────────────────

// class _InfoTile extends StatelessWidget {
//   final String label, value;
//   final Color color;
//   const _InfoTile(this.label, this.value, this.color);

//   @override
//   Widget build(BuildContext context) => Column(
//     children: [
//       Text(label, style: TextStyle(
//         fontSize: 9, color: color.withOpacity(0.6),
//         letterSpacing: 2, fontWeight: FontWeight.bold,
//       )),
//       const SizedBox(height: 4),
//       Text(value, style: TextStyle(
//         fontSize: 20, fontWeight: FontWeight.bold, color: color,
//       )),
//     ],
//   );
// }

// class _SummaryTile extends StatelessWidget {
//   final String label, value;
//   final IconData icon;
//   const _SummaryTile(this.label, this.value, this.icon);

//   @override
//   Widget build(BuildContext context) => Column(
//     children: [
//       Icon(icon, color: Colors.greenAccent.withOpacity(0.7), size: 24),
//       const SizedBox(height: 4),
//       Text(value, style: const TextStyle(
//         fontSize: 22, fontWeight: FontWeight.bold, color: Colors.greenAccent,
//       )),
//       Text(label, style: TextStyle(
//         fontSize: 11, color: Colors.greenAccent.withOpacity(0.6),
//       )),
//     ],
//   );
// }

// class _GyroBar extends StatelessWidget {
//   final String label;
//   final double value;
//   final Color color;
//   const _GyroBar({required this.label, required this.value, required this.color});

//   @override
//   Widget build(BuildContext context) {
//     final filled = (value.clamp(-3.0, 3.0) + 3.0) / 6.0;
//     return Expanded(
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(label, style: TextStyle(
//                 color: color, fontSize: 11, fontWeight: FontWeight.bold,
//               )),
//               Text(value.toStringAsFixed(2), style: TextStyle(
//                 color: color.withOpacity(0.7), fontSize: 10, fontFamily: 'monospace',
//               )),
//             ],
//           ),
//           const SizedBox(height: 4),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(4),
//             child: LinearProgressIndicator(
//               value: filled,
//               backgroundColor: color.withOpacity(0.1),
//               valueColor: AlwaysStoppedAnimation(color),
//               minHeight: 5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gyroscope/gyroscopePlugin.dart';
import 'package:gyroscope_plugin/gyroscope_plugin.dart' hide GyroscopePlugin;
import 'package:url_launcher/url_launcher.dart';

// const _overlayChannel = MethodChannel('gyroscope_plugin/overlay');

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) => MaterialApp(
//     title: 'Gyro Runner',
//     debugShowCheckedModeBanner: false,
//     theme: ThemeData.dark().copyWith(
//       scaffoldBackgroundColor: const Color(0xFF050510),
//     ),
//     home: const HomeScreen(),
//   );
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen>
//     with TickerProviderStateMixin, WidgetsBindingObserver {

//   final _sdk = GyroscopePlugin();

//   bool _isStreaming = false;
//   bool _hasGyro = false;
//   String _sessionId = '';
//   int _readingCount = 0;
//   double _gx = 0, _gy = 0, _gz = 0;
//   bool _phoneIdle = false;
//   String _statusMsg = 'Ready to play';
//   DateTime? _sessionStart;
//   String _duration = '0s';
//   Timer? _durationTimer;
//   bool _gameWasLaunched = false;
//   SessionInfo? _lastSession;

//   // Overlay permission state
//   bool _overlayPermissionGranted = false;
//   bool _waitingForPermission = false;

//   late AnimationController _pulseController;
//   late AnimationController _glowController;
//   late Animation<double> _pulseAnim;
//   late Animation<double> _glowAnim;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     _pulseController = AnimationController(
//       vsync: this, duration: const Duration(milliseconds: 1200),
//     )..repeat(reverse: true);
//     _glowController = AnimationController(
//       vsync: this, duration: const Duration(milliseconds: 2000),
//     )..repeat(reverse: true);
//     _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );
//     _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
//       CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
//     );

//     _checkGyro();
//     // App launch hote hi permission check karo aur bottomsheet dikhao
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//     });
//       _checkAndShowPermissionSheet();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);

//     if (state == AppLifecycleState.resumed) {
//       if (_waitingForPermission) {
//         // User settings se wapis aaya — permission check karo
//         _waitingForPermission = false;
//         _recheckPermissionAfterSettings();
//         return;
//       }
//       if (_gameWasLaunched && _isStreaming) {
//         _stopGame();
//         _gameWasLaunched = false;
//       }
//     } else if (state == AppLifecycleState.paused) {
//       if (_isStreaming) _gameWasLaunched = true;
//     }
//   }

//   // ── Permission Check ──────────────────────────────────────────────────────

//   Future<void> _checkAndShowPermissionSheet() async {
//     final bool granted =
//         await _overlayChannel.invokeMethod('checkOverlayPermission') ?? false;
//     setState(() => _overlayPermissionGranted = granted);

//     if (!granted) {
//       // Permission nahi hai — bottomsheet dikhao
//       _showPermissionBottomSheet();
//     }
//   }

//   Future<void> _recheckPermissionAfterSettings() async {
//     final bool granted =
//         await _overlayChannel.invokeMethod('checkOverlayPermission') ?? false;
//     setState(() => _overlayPermissionGranted = granted);

//     if (granted && mounted) {
//       // Permission mil gayi — success snackbar
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Row(
//             children: [
//               Icon(Icons.check_circle, color: Colors.white),
//               SizedBox(width: 8),
//               Text('Overlay permission granted!'),
//             ],
//           ),
//           backgroundColor: Colors.green.shade700,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     } else if (!granted && mounted) {
//       // Still nahi mili — bottomsheet dobara dikhao
//       _showPermissionBottomSheet();
//     }
//   }

//   void _showPermissionBottomSheet() {
//     if (!mounted) return;
//     showModalBottomSheet(
//       context: context,
//       isDismissible: true,
//       backgroundColor: Colors.transparent,
//       builder: (ctx) => _PermissionBottomSheet(
//         onProceed: () {
//           Navigator.pop(ctx);
//           _requestOverlayPermission();
//         },
//         onCancel: () => Navigator.pop(ctx),
//       ),
//     );
//   }

//   Future<void> _requestOverlayPermission() async {
//     _waitingForPermission = true;
//     try {
//       await _overlayChannel.invokeMethod('requestOverlayPermission');
//     } catch (_) {}
//   }

//   // ── Game Start/Stop ───────────────────────────────────────────────────────

//   Future<void> _checkGyro() async {
//     final has = await _sdk.hasGyroscope();
//     setState(() => _hasGyro = has);
//   }

//   Future<void> _startGame() async {
//     // Permission nahi hai toh bottomsheet dikhao
//     if (!_overlayPermissionGranted) {
//       _showPermissionBottomSheet();
//       return;
//     }

//     if (!_hasGyro) {
//       _showSnack('No gyroscope found on this device!');
//       return;
//     }

//     setState(() => _lastSession = null);

//     final sessionId = await _sdk.startGame(
//       gameId: 'subway_surfers',
//       samplingRate: GyroSamplingRate.game,
//       autoLog: false,
//       onData: (GyroData data) {
//         if (!mounted) return;
//         setState(() {
//           _gx = data.x; _gy = data.y; _gz = data.z;
//           _phoneIdle = data.isIdle;
//           _readingCount++;
//         });
//       },
//       onSessionStart: (SessionInfo info) {
//         if (!mounted) return;
//         setState(() {
//           _sessionId = info.sessionId;
//           _isStreaming = true;
//           _statusMsg = '🟢 Streaming active';
//           _sessionStart = DateTime.now();
//         });
//         _startDurationTimer();
//       },
//       onSessionStop: (SessionInfo info) {
//         if (!mounted) return;
//         setState(() {
//           _lastSession = info;
//           _isStreaming = false;
//           _statusMsg = '✅ Session completed!';
//           _readingCount = 0;
//           _gx = 0; _gy = 0; _gz = 0;
//         });
//         _durationTimer?.cancel();
//       },
//       onPhoneState: (PhoneState state, String sid) {
//         if (!mounted) return;
//         setState(() => _phoneIdle = state == PhoneState.idle);
//       },
//     );

//     setState(() => _sessionId = sessionId ?? '');

//     // Overlay start karo
//     try {
//       await _overlayChannel.invokeMethod('startOverlay');
//     } catch (_) {}

//     // Game open karo
//     await _openGame();
//   }

//   Future<void> _stopGame() async {
//     await _sdk.stopGame();
//     try { await _overlayChannel.invokeMethod('stopOverlay'); } catch (_) {}
//     _durationTimer?.cancel();
//     setState(() {
//       _isStreaming = false;
//       if (_lastSession == null) _statusMsg = '⏹ Stopped';
//       _duration = '0s';
//       _sessionStart = null;
//     });
//   }

//   Future<void> _openGame() async {
//     final appUri = Uri.parse('android-app://com.king.candycrushsaga');
//     if (await canLaunchUrl(appUri)) {
//       await launchUrl(appUri);
//     } else {
//       final storeUri = Uri.parse(
//           'https://play.google.com/store/apps/details?id=com.king.candycrushsaga');
//       await launchUrl(storeUri, mode: LaunchMode.externalApplication);
//     }
//   }

//   void _startDurationTimer() {
//     _durationTimer?.cancel();
//     _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (_sessionStart == null || !mounted) return;
//       final diff = DateTime.now().difference(_sessionStart!).inSeconds;
//       setState(() => _duration = '${diff}s');
//     });
//   }

//   void _showSnack(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
//     );
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _pulseController.dispose();
//     _glowController.dispose();
//     _durationTimer?.cancel();
//     _sdk.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFF050510), Color(0xFF0A0A20), Color(0xFF050515)],
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: Column(
//               children: [
//                 const SizedBox(height: 24),

//                 // ── Header ──
//                 // Row(
//                 //   children: [
//                 //     Column(
//                 //       crossAxisAlignment: CrossAxisAlignment.start,
//                 //       children: [
//                 //         const Text('GYRO', style: TextStyle(
//                 //           fontSize: 32, fontWeight: FontWeight.w900,
//                 //           color: Colors.white, letterSpacing: 6,
//                 //           shadows: [Shadow(color: Color(0xFF00FFFF), blurRadius: 16)],
//                 //         )),
//                 //         const Text('RUNNER', style: TextStyle(
//                 //           fontSize: 14, fontWeight: FontWeight.w300,
//                 //           color: Color(0xFF00FFFF), letterSpacing: 10,
//                 //         )),
//                 //       ],
//                 //     ),
//                 //     const Spacer(),
//                 //     // Permission badge
//                 //     Container(
//                 //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                 //       decoration: BoxDecoration(
//                 //         borderRadius: BorderRadius.circular(20),
//                 //         color: (_overlayPermissionGranted ? Colors.green : Colors.orange)
//                 //             .withOpacity(0.15),
//                 //         border: Border.all(
//                 //           color: (_overlayPermissionGranted ? Colors.green : Colors.orange)
//                 //               .withOpacity(0.5),
//                 //         ),
//                 //       ),
//                 //       child: Row(
//                 //         mainAxisSize: MainAxisSize.min,
//                 //         children: [
//                 //           Icon(
//                 //             _overlayPermissionGranted
//                 //                 ? Icons.layers
//                 //                 : Icons.layers_clear,
//                 //             size: 12,
//                 //             color: _overlayPermissionGranted
//                 //                 ? Colors.green
//                 //                 : Colors.orange,
//                 //           ),
//                 //           const SizedBox(width: 4),
//                 //           Text(
//                 //             _overlayPermissionGranted ? 'OVERLAY ON' : 'NO OVERLAY',
//                 //             style: TextStyle(
//                 //               fontSize: 9,
//                 //               fontWeight: FontWeight.bold,
//                 //               color: _overlayPermissionGranted
//                 //                   ? Colors.green
//                 //                   : Colors.orange,
//                 //               letterSpacing: 1,
//                 //             ),
//                 //           ),
//                 //         ],
//                 //       ),
//                 //     ),
//                 //     const SizedBox(width: 8),
//                 //     // Live badge
//                 //     AnimatedBuilder(
//                 //       animation: _glowAnim,
//                 //       builder: (_, __) => Container(
//                 //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 //         decoration: BoxDecoration(
//                 //           borderRadius: BorderRadius.circular(20),
//                 //           color: (_isStreaming ? Colors.green : Colors.grey)
//                 //               .withOpacity(0.1),
//                 //           border: Border.all(
//                 //             color: (_isStreaming ? Colors.green : Colors.grey)
//                 //                 .withOpacity(_isStreaming ? _glowAnim.value : 0.3),
//                 //           ),
//                 //           boxShadow: _isStreaming
//                 //               ? [BoxShadow(
//                 //             color: Colors.green.withOpacity(_glowAnim.value * 0.4),
//                 //             blurRadius: 12,
//                 //           )]
//                 //               : [],
//                 //         ),
//                 //         child: Row(
//                 //           mainAxisSize: MainAxisSize.min,
//                 //           children: [
//                 //             Container(
//                 //               width: 8, height: 8,
//                 //               decoration: BoxDecoration(
//                 //                 shape: BoxShape.circle,
//                 //                 color: _isStreaming ? Colors.green : Colors.grey,
//                 //               ),
//                 //             ),
//                 //             const SizedBox(width: 6),
//                 //             Text(
//                 //               _isStreaming ? 'LIVE' : 'OFFLINE',
//                 //               style: TextStyle(
//                 //                 fontSize: 11, fontWeight: FontWeight.bold,
//                 //                 color: _isStreaming ? Colors.green : Colors.grey,
//                 //                 letterSpacing: 2,
//                 //               ),
//                 //             ),
//                 //           ],
//                 //         ),
//                 //       ),
//                 //     ),
//                 //   ],
//                 // ),

//                 // const SizedBox(height: 32),


//                 // ── Game Card ──
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(24),
//                     gradient: const LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: [Color(0xFF1A1A3E), Color(0xFF0D0D2B)],
//                     ),
//                     border: Border.all(
//                         color: const Color(0xFF00FFFF).withOpacity(0.15)),
//                     boxShadow: [
//                       BoxShadow(
//                         color: const Color(0xFF00FFFF).withOpacity(0.05),
//                         blurRadius: 30, spreadRadius: 2,
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       AnimatedBuilder(
//                         animation: _pulseAnim,
//                         builder: (_, child) => Transform.scale(
//                           scale: _isStreaming ? _pulseAnim.value : 1.0,
//                           child: child,
//                         ),
//                         child: Container(
//                           width: 100, height: 100,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(24),
//                             gradient: const LinearGradient(
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                               colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: const Color(0xFF667EEA).withOpacity(
//                                     _isStreaming ? 0.6 : 0.3),
//                                 blurRadius: _isStreaming ? 24 : 12,
//                               ),
//                             ],
//                           ),
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(24),
//                             child: Image.network(
//                               'https://play-lh.googleusercontent.com/gU9NKwpgLDYA6LIYK4dnkAkVyqNHUfTIqklEiNuO4oZ2OCpWQhQdqhnDh8Yb9B8SWIM=s256-rw',
//                               width: 100,
//                               height: 100,
//                               fit: BoxFit.cover,
//                               errorBuilder: (_, __, ___) => const Center(
//                                 child: Text('🍬', style: TextStyle(fontSize: 48)),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       const Text('Candy Crush', style: TextStyle(
//                         fontSize: 22, fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       )),
//                       const SizedBox(height: 4),
//                       Text(
//                         _isStreaming
//                             ? 'Game is running • Return to stop'
//                             : 'Tap to launch game & start tracking',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: _isStreaming
//                               ? Colors.greenAccent
//                               : Colors.white38,
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//                       if (!_isStreaming) _buildLaunchButton(),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 // ── Live Info ──
//                 if (_isStreaming) ...[
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(16),
//                       color: Colors.white.withOpacity(0.04),
//                       border: Border.all(color: Colors.white10),
//                     ),
//                     child: Column(
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             _InfoTile('DURATION', _duration, Colors.cyanAccent),
//                             _InfoTile('READINGS', '$_readingCount',
//                                 const Color(0xFF00FFFF)),
//                             _InfoTile(
//                               'STATUS',
//                               _phoneIdle ? 'IDLE' : 'ACTIVE',
//                               _phoneIdle ? Colors.orange : Colors.greenAccent,
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 12, vertical: 8),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(8),
//                             color: Colors.black.withOpacity(0.3),
//                           ),
//                           child: Text(
//                             'SESSION: ${_sessionId.length > 20 ? _sessionId.substring(0, 20) : _sessionId}...',
//                             style: const TextStyle(
//                               fontSize: 10, color: Colors.white30,
//                               fontFamily: 'monospace', letterSpacing: 1,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(16),
//                       color: Colors.white.withOpacity(0.04),
//                       border: Border.all(color: Colors.white10),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text('GYROSCOPE', style: TextStyle(
//                           fontSize: 10, color: Colors.white38,
//                           letterSpacing: 3, fontWeight: FontWeight.bold,
//                         )),
//                         const SizedBox(height: 12),
//                         Row(children: [
//                           _GyroBar(label: 'X', value: _gx,
//                               color: Colors.redAccent),
//                           const SizedBox(width: 8),
//                           _GyroBar(label: 'Y', value: _gy,
//                               color: Colors.greenAccent),
//                           const SizedBox(width: 8),
//                           _GyroBar(label: 'Z', value: _gz,
//                               color: Colors.blueAccent),
//                         ]),
//                       ],
//                     ),
//                   ),
//                 ],

//                 // ── Session Summary ──
//                 if (!_isStreaming && _lastSession != null) ...[
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(16),
//                       gradient: const LinearGradient(
//                         colors: [Color(0xFF1A4D2E), Color(0xFF0D2818)],
//                       ),
//                       border: Border.all(
//                           color: Colors.greenAccent.withOpacity(0.3)),
//                     ),
//                     child: Column(
//                       children: [
//                         const Icon(Icons.check_circle,
//                             color: Colors.greenAccent, size: 48),
//                         const SizedBox(height: 12),
//                         const Text('Session Complete!', style: TextStyle(
//                           fontSize: 20, fontWeight: FontWeight.bold,
//                           color: Colors.greenAccent,
//                         )),
//                         const SizedBox(height: 16),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceAround,
//                           children: [
//                             _SummaryTile(
//                               'Duration',
//                               '${(_lastSession!.durationMs ?? 0) ~/ 1000}s',
//                               Icons.timer,
//                             ),
//                             // _SummaryTile(
//                             //   'Readings',
//                             //   '${_lastSession!.totalReadings ?? 0}',
//                             //   Icons.sensors,
//                             // ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
                        
//                       ],
//                     ),
//                   ),
//                 ],

//                 const Spacer(),
//                 Text(
//                   _statusMsg,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: _isStreaming
//                         ? Colors.greenAccent.withOpacity(0.7)
//                         : Colors.white24,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLaunchButton() {
//     return GestureDetector(
//       onTap: _startGame,
//       child: AnimatedBuilder(
//         animation: _glowAnim,
//         builder: (_, __) => Container(
//           width: double.infinity,
//           height: 56,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             gradient: const LinearGradient(
//               colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: const Color(0xFF667EEA)
//                     .withOpacity(0.4 + _glowAnim.value * 0.2),
//                 blurRadius: 20, spreadRadius: 1,
//               ),
//             ],
//           ),
//           child: const Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
//               SizedBox(width: 8),
//               Text('LAUNCH GAME', style: TextStyle(
//                 color: Colors.white, fontSize: 16,
//                 fontWeight: FontWeight.bold, letterSpacing: 2,
//               )),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─── Permission Bottom Sheet ──────────────────────────────────────────────────

// class _PermissionBottomSheet extends StatelessWidget {
//   final VoidCallback onProceed;
//   final VoidCallback onCancel;

//   const _PermissionBottomSheet({
//     required this.onProceed,
//     required this.onCancel,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         color: Color(0xFF0D0D2B),
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Handle
//           Container(
//             width: 40, height: 4,
//             decoration: BoxDecoration(
//               color: Colors.white24,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//           const SizedBox(height: 24),

//           // Icon
//           Container(
//             width: 64, height: 64,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.orange.withOpacity(0.15),
//               border: Border.all(color: Colors.orange.withOpacity(0.4)),
//             ),
//             child: const Icon(Icons.layers, color: Colors.orange, size: 32),
//           ),
//           const SizedBox(height: 16),

//           // Title
//           const Text(
//             'Overlay Permission Required',
//             style: TextStyle(
//               fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 12),

//           // Description
          

//           // Steps
         

//           // Proceed button
//           SizedBox(
//             width: double.infinity,
//             height: 52,
//             child: ElevatedButton(
//               onPressed: onProceed,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF667EEA),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//               ),
//               child: const Text(
//                 'PROCEED TO SETTINGS',
//                 style: TextStyle(
//                   fontSize: 15, fontWeight: FontWeight.bold,
//                   color: Colors.white, letterSpacing: 1,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),

//           // Cancel button
//           SizedBox(
//             width: double.infinity,
//             height: 48,
//             child: TextButton(
//               onPressed: onCancel,
//               child: const Text(
//                 'Cancel',
//                 style: TextStyle(fontSize: 14, color: Colors.white38),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _Step extends StatelessWidget {
//   final String number;
//   final String text;
//   const _Step({required this.number, required this.text});

//   @override
//   Widget build(BuildContext context) => Row(
//     children: [
//       Container(
//         width: 22, height: 22,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: const Color(0xFF667EEA).withOpacity(0.3),
//           border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.6)),
//         ),
//         child: Center(
//           child: Text(number, style: const TextStyle(
//             fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold,
//           )),
//         ),
//       ),
//       const SizedBox(width: 10),
//       Text(text, style: const TextStyle(fontSize: 13, color: Colors.white70)),
//     ],
//   );
// }

// // ─── Widgets ──────────────────────────────────────────────────────────────────

// class _InfoTile extends StatelessWidget {
//   final String label, value;
//   final Color color;
//   const _InfoTile(this.label, this.value, this.color);

//   @override
//   Widget build(BuildContext context) => Column(
//     children: [
//       Text(label, style: TextStyle(
//         fontSize: 9, color: color.withOpacity(0.6),
//         letterSpacing: 2, fontWeight: FontWeight.bold,
//       )),
//       const SizedBox(height: 4),
//       Text(value, style: TextStyle(
//         fontSize: 20, fontWeight: FontWeight.bold, color: color,
//       )),
//     ],
//   );
// }

// class _SummaryTile extends StatelessWidget {
//   final String label, value;
//   final IconData icon;
//   const _SummaryTile(this.label, this.value, this.icon);

//   @override
//   Widget build(BuildContext context) => Column(
//     children: [
//       Icon(icon, color: Colors.greenAccent.withOpacity(0.7), size: 24),
//       const SizedBox(height: 4),
//       Text(value, style: const TextStyle(
//         fontSize: 22, fontWeight: FontWeight.bold, color: Colors.greenAccent,
//       )),
//       Text(label, style: TextStyle(
//         fontSize: 11, color: Colors.greenAccent.withOpacity(0.6),
//       )),
//     ],
//   );
// }

// class _GyroBar extends StatelessWidget {
//   final String label;
//   final double value;
//   final Color color;
//   const _GyroBar({required this.label, required this.value, required this.color});

//   @override
//   Widget build(BuildContext context) {
//     final filled = (value.clamp(-3.0, 3.0) + 3.0) / 6.0;
//     return Expanded(
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(label, style: TextStyle(
//                 color: color, fontSize: 11, fontWeight: FontWeight.bold,
//               )),
//               Text(value.toStringAsFixed(2), style: TextStyle(
//                 color: color.withOpacity(0.7), fontSize: 10,
//                 fontFamily: 'monospace',
//               )),
//             ],
//           ),
//           const SizedBox(height: 4),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(4),
//             child: LinearProgressIndicator(
//               value: filled,
//               backgroundColor: color.withOpacity(0.1),
//               valueColor: AlwaysStoppedAnimation(color),
//               minHeight: 5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gyroscope/gyroscopePlugin.dart';
import 'package:gyroscope_plugin/gyroscope_plugin.dart' hide GyroscopePlugin;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const _overlayChannel = MethodChannel('gyroscope_plugin/overlay');

void main() async{
  WidgetsFlutterBinding.ensureInitialized(); 

  // Send device ID right after app starts (only once is usually enough)
  await DeviceService.sendDeviceIdToBackend();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
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

  bool _isStreaming = false;
  bool _hasGyro = false;
  String _sessionId = '';
  int _readingCount = 0;
  double _gx = 0, _gy = 0, _gz = 0;
  bool _phoneIdle = false;
  String _statusMsg = 'Ready to play';
  DateTime? _sessionStart;
  String _duration = '0s';
  Timer? _durationTimer;
  Timer? _backendTimer;
  bool _gameWasLaunched = false;
  SessionInfo? _lastSession;

  // ── Backend URL ─────────────────────────────────────────────────────────
  static const String _backendUrl = 'https://unheeded-uromeric-jadon.ngrok-free.dev/app'; // ← Apna URL yahan daalo

  // Overlay permission state
  bool _overlayPermissionGranted = false;
  bool _waitingForPermission = false;

  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _checkGyro();
    // App launch hote hi permission check karo aur bottomsheet dikhao
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowPermissionSheet();
      _registerDevice();
    });
  }
String _status = 'Sending device ID...';

Future<void> _registerDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadySent = prefs.getBool('device_id_sent') ?? false;

    if (alreadySent) {
      setState(() => _status = 'Device already registered');
      return;
    }

    final success = await DeviceService.sendDeviceIdToBackend();

    if (success) {
      await prefs.setBool('device_id_sent', true);
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

  Future<void> _checkGyro() async {
    final has = await _sdk.hasGyroscope();
    setState(() => _hasGyro = has);
  }

  Future<void> _startGame() async {
    // Permission nahi hai toh bottomsheet dikhao
    if (!_overlayPermissionGranted) {
      _showPermissionBottomSheet();
      return;
    }

    if (!_hasGyro) {
      _showSnack('No gyroscope found on this device!');
      return;
    }

    setState(() => _lastSession = null);

    final sessionId = await _sdk.startGame(
      gameId: 'candy_crush',
      samplingRate: GyroSamplingRate.game,
      autoLog: false,
      onData: (GyroData data) {
        if (!mounted) return;
        setState(() {
          _gx = data.x; _gy = data.y; _gz = data.z;
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
          _gx = 0; _gy = 0; _gz = 0;
        });
        _durationTimer?.cancel();
      },
      onPhoneState: (PhoneState state, String sid) {
        if (!mounted) return;
        setState(() => _phoneIdle = state == PhoneState.idle);
      },
    );

    setState(() => _sessionId = sessionId ?? '');

    // Overlay start karo
    try {
      await _overlayChannel.invokeMethod('startOverlay');
    } catch (_) {}

    // Game open karo
    await _openSubwaySurfers();
  }

  Future<void> _stopGame() async {
    await _sdk.stopGame();
    try { await _overlayChannel.invokeMethod('stopOverlay'); } catch (_) {}
    _durationTimer?.cancel();
    _backendTimer?.cancel();
    setState(() {
      _isStreaming = false;
      if (_lastSession == null) _statusMsg = '⏹ Stopped';
      _duration = '0s';
      _sessionStart = null;
    });
  }

  Future<void> _openSubwaySurfers() async {
    final appUri = Uri.parse('android-app://com.king.candycrushsaga');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      final storeUri = Uri.parse(
          'https://play.google.com/store/apps/details?id=com.king.candycrushsaga');
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
    _backendTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isStreaming) return;
      _sendToBackend(GyroData(x: _gx, y: _gy, z: _gz, timestampNs: 0, isIdle: _phoneIdle));
    });
  }

  // ── Send to Backend ──────────────────────────────────────────────────────
  Future<void> _sendToBackend(GyroData data) async {
    var prefs =await SharedPreferences.getInstance();
   var deviceId =  prefs.getString("persistent_device_id");
    final payload = {
      'deviceId': deviceId,
      'x_value': data.x,
      'y_value': data.y,
      'z_value': data.z,
       
    };

    print('📡 Sending to backend: $payload');

    try {
      final response = await http.post(
        Uri.parse("$_backendUrl/gyroscope/updateGyroscope"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      print('✅ Backend response: \${response.statusCode}');
    } catch (e) {
      print('❌ Backend error: \$e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
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
            child: Column(
              children: [
                const SizedBox(height: 24),

                // ── Header ──
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GYRO', style: TextStyle(
                          fontSize: 32, fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: 6,
                          shadows: [Shadow(color: Color(0xFF00FFFF), blurRadius: 16)],
                        )),
                        const Text('RUNNER', style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w300,
                          color: Color(0xFF00FFFF), letterSpacing: 10,
                        )),
                      ],
                    ),
                    const Spacer(),
                    // Permission badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: (_overlayPermissionGranted ? Colors.green : Colors.orange)
                            .withOpacity(0.15),
                        border: Border.all(
                          color: (_overlayPermissionGranted ? Colors.green : Colors.orange)
                              .withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _overlayPermissionGranted
                                ? Icons.layers
                                : Icons.layers_clear,
                            size: 12,
                            color: _overlayPermissionGranted
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _overlayPermissionGranted ? 'OVERLAY ON' : 'NO OVERLAY',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _overlayPermissionGranted
                                  ? Colors.green
                                  : Colors.orange,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Live badge
                    AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, __) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: (_isStreaming ? Colors.green : Colors.grey)
                              .withOpacity(0.1),
                          border: Border.all(
                            color: (_isStreaming ? Colors.green : Colors.grey)
                                .withOpacity(_isStreaming ? _glowAnim.value : 0.3),
                          ),
                          boxShadow: _isStreaming
                              ? [BoxShadow(
                            color: Colors.green.withOpacity(_glowAnim.value * 0.4),
                            blurRadius: 12,
                          )]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isStreaming ? Colors.green : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isStreaming ? 'LIVE' : 'OFFLINE',
                              style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold,
                                color: _isStreaming ? Colors.green : Colors.grey,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Game Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1A3E), Color(0xFF0D0D2B)],
                    ),
                    border: Border.all(
                        color: const Color(0xFF00FFFF).withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FFFF).withOpacity(0.05),
                        blurRadius: 30, spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _isStreaming ? _pulseAnim.value : 1.0,
                          child: child,
                        ),
                        child: Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF3CAC).withOpacity(
                                    _isStreaming ? 0.7 : 0.3),
                                blurRadius: _isStreaming ? 28 : 12,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              'https://play-lh.googleusercontent.com/gU9NKwpgLDYA6LIYK4dnkAkVyqNHUfTIqklEiNuO4oZ2OCpWQhQdqhnDh8Yb9B8SWIM=s256-rw',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Text('🍬', style: TextStyle(fontSize: 48)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Candy Crush Saga', style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                      const SizedBox(height: 4),
                      Text(
                        _isStreaming
                            ? 'Game is running • Return to stop'
                            : 'Tap to launch game & start tracking',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isStreaming
                              ? Colors.greenAccent
                              : Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!_isStreaming) _buildLaunchButton(),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Live Info ──
                if (_isStreaming) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withOpacity(0.04),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _InfoTile('DURATION', _duration, Colors.cyanAccent),
                            _InfoTile('READINGS', '$_readingCount',
                                const Color(0xFF00FFFF)),
                            _InfoTile(
                              'STATUS',
                              _phoneIdle ? 'IDLE' : 'ACTIVE',
                              _phoneIdle ? Colors.orange : Colors.greenAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black.withOpacity(0.3),
                          ),
                          child: Text(
                            'SESSION: ${_sessionId.length > 20 ? _sessionId.substring(0, 20) : _sessionId}...',
                            style: const TextStyle(
                              fontSize: 10, color: Colors.white30,
                              fontFamily: 'monospace', letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withOpacity(0.04),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GYROSCOPE', style: TextStyle(
                          fontSize: 10, color: Colors.white38,
                          letterSpacing: 3, fontWeight: FontWeight.bold,
                        )),
                        const SizedBox(height: 8),
                        // ── X Y Z Values ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _ValueBox(label: 'X', value: _gx, color: Colors.redAccent),
                            _ValueBox(label: 'Y', value: _gy, color: Colors.greenAccent),
                            _ValueBox(label: 'Z', value: _gz, color: Colors.blueAccent),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          _GyroBar(label: 'X', value: _gx,
                              color: Colors.redAccent),
                          const SizedBox(width: 8),
                          _GyroBar(label: 'Y', value: _gy,
                              color: Colors.greenAccent),
                          const SizedBox(width: 8),
                          _GyroBar(label: 'Z', value: _gz,
                              color: Colors.blueAccent),
                        ]),
                      ],
                    ),
                  ),
                ],

                // ── Session Summary ──
                if (!_isStreaming && _lastSession != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A4D2E), Color(0xFF0D2818)],
                      ),
                      border: Border.all(
                          color: Colors.greenAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.greenAccent, size: 48),
                        const SizedBox(height: 12),
                        const Text('Session Complete!', style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                        )),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _SummaryTile(
                              'Duration',
                              '${(_lastSession!.durationMs ?? 0) ~/ 1000}s',
                              Icons.timer,
                            ),
                            _SummaryTile(
                              'Readings',
                              '${_lastSession!.totalReadings ?? 0}',
                              Icons.sensors,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Session ID: ${_lastSession!.sessionId.substring(0, 12)}...',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white30),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),
                Text(
                  _statusMsg,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isStreaming
                        ? Colors.greenAccent.withOpacity(0.7)
                        : Colors.white24,
                  ),
                ),
                const SizedBox(height: 16),
              ],
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
                color: const Color(0xFF667EEA)
                    .withOpacity(0.4 + _glowAnim.value * 0.2),
                blurRadius: 20, spreadRadius: 1,
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text('LAUNCH GAME', style: TextStyle(
                color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.bold, letterSpacing: 2,
              )),
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
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 64, height: 64,
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
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,
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
                  fontSize: 15, fontWeight: FontWeight.bold,
                  color: Colors.white, letterSpacing: 1,
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

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 22, height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF667EEA).withOpacity(0.3),
          border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.6)),
        ),
        child: Center(
          child: Text(number, style: const TextStyle(
            fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold,
          )),
        ),
      ),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(fontSize: 13, color: Colors.white70)),
    ],
  );
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoTile(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: TextStyle(
        fontSize: 9, color: color.withOpacity(0.6),
        letterSpacing: 2, fontWeight: FontWeight.bold,
      )),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(
        fontSize: 20, fontWeight: FontWeight.bold, color: color,
      )),
    ],
  );
}

class _SummaryTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _SummaryTile(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: Colors.greenAccent.withOpacity(0.7), size: 24),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(
        fontSize: 22, fontWeight: FontWeight.bold, color: Colors.greenAccent,
      )),
      Text(label, style: TextStyle(
        fontSize: 11, color: Colors.greenAccent.withOpacity(0.6),
      )),
    ],
  );
}

class _GyroBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _GyroBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final filled = (value.clamp(-3.0, 3.0) + 3.0) / 6.0;
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold,
              )),
              Text(value.toStringAsFixed(2), style: TextStyle(
                color: color.withOpacity(0.7), fontSize: 10,
                fontFamily: 'monospace',
              )),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: filled,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Candy Crush Icon Widget ──────────────────────────────────────────────────

class _CandyCrushIcon extends StatelessWidget {
  const _CandyCrushIcon();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circles — candy pattern
          Positioned(top: -8, left: -8,
            child: _Circle(size: 40, color: const Color(0xFFFF9ECD))),
          Positioned(bottom: -8, right: -8,
            child: _Circle(size: 40, color: const Color(0xFFFF6BAE))),
          Positioned(top: 10, right: 5,
            child: _Circle(size: 20, color: const Color(0xFFFFC0DC))),

          // Center candy
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lollipop
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFFF3CAC)],
                    stops: [0.3, 1.0],
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.5),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: const Center(
                  child: Text('🍭', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(height: 2),
              // Candy bar
              Container(
                width: 28, height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFFFB347)],
                  ),
                ),
              ),
            ],
          ),

          // Stars
          const Positioned(top: 8, left: 8,
            child: Text('✨', style: TextStyle(fontSize: 12))),
          const Positioned(bottom: 10, left: 12,
            child: Text('⭐', style: TextStyle(fontSize: 10))),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _ValueBox extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _ValueBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(
            fontSize: 11, color: color,
            fontWeight: FontWeight.bold, letterSpacing: 2,
          )),
          const SizedBox(height: 4),
          Text(
            value.toStringAsFixed(3),
            style: TextStyle(
              fontSize: 16, color: color,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}