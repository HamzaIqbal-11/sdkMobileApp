import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:gyroscope/gyroscopePlugin.dart';

const _overlayChannel = MethodChannel('gyroscope_plugin/overlay');

class AccelerometerScreen extends StatefulWidget {
  final double ax, ay, az;
  final double gx, gy, gz;
  final String backendUrl;
  final Stream<GyroData>? gyroStream;

  const AccelerometerScreen({
    super.key,
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
    required this.backendUrl,
    this.gyroStream,
  });

  @override
  State<AccelerometerScreen> createState() => _AccelerometerScreenState();
}

class _AccelerometerScreenState extends State<AccelerometerScreen> {
  late double _ax, _ay, _az;
  late double _gx, _gy, _gz;
  bool _sending = false;
  bool _sent = false;
  bool _isLive = false;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _ax = widget.ax;
    _ay = widget.ay;
    _az = widget.az;
    _gx = widget.gx;
    _gy = widget.gy;
    _gz = widget.gz;

    // Live update from sensor stream
    _sub = widget.gyroStream?.listen((data) {
      if (mounted) {
        setState(() {
          _ax = data.ax;
          _ay = data.ay;
          _az = data.az;
          _gx = data.x;
          _gy = data.y;
          _gz = data.z;
          _isLive = true;
          _sent = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _sendToBackend() async {
    if (_sending) return;
    setState(() { _sending = true; _sent = false; });

    try {
      final info = await _overlayChannel.invokeMethod('getDeviceInfo', {});
      final deviceId = info['deviceId'] ?? '';

      final response = await http.post(
        Uri.parse('${widget.backendUrl}/activity/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': deviceId,
          'organization_id': '1',
          'product_id': '1',
          'gyro_x': _gx,
          'gyro_y': _gy,
          'gyro_z': _gz,
          'accel_x': _ax,
          'accel_y': _ay,
          'accel_z': _az,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() => _sent = true);
        _showSnack('Accelerometer data sent!', Colors.green.shade700);
      } else {
        _showSnack('Server error: ${response.statusCode}', Colors.red.shade700);
      }
    } catch (e) {
      _showSnack('Failed: $e', Colors.red.shade700);
    }

    setState(() => _sending = false);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Accelerometer', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isLive)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
                  const SizedBox(width: 6),
                  const Text('LIVE', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Icon(Icons.speed, color: Colors.orangeAccent.withOpacity(0.3), size: 80),
            const SizedBox(height: 24),
            Text(
              _isLive ? 'LIVE VALUES' : 'LAST RECORDED VALUES',
              style: TextStyle(color: _isLive ? Colors.green : Colors.white38, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            _SensorCard('X-Axis', _ax, Colors.redAccent),
            const SizedBox(height: 14),
            _SensorCard('Y-Axis', _ay, Colors.greenAccent),
            const SizedBox(height: 14),
            _SensorCard('Z-Axis', _az, Colors.blueAccent),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _sending ? null : _sendToBackend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _sent ? Colors.green.shade700 : const Color(0xFF667EEA),
                  disabledBackgroundColor: const Color(0xFF667EEA).withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _sending
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_sent ? Icons.check : Icons.cloud_upload_outlined, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(_sent ? 'SENT TO BACKEND' : 'SEND TO BACKEND', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      ),
              ),
            ),
          
          ],
        ),
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _SensorCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withOpacity(0.06),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600)),
          Text(value.toStringAsFixed(4), style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}