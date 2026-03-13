import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _overlayChannel = MethodChannel('gyroscope_plugin/overlay');

class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  bool _loading = true;
  Map<String, dynamic> _info = {};

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    setState(() => _loading = true);
    try {
      final info = await _overlayChannel.invokeMethod('getDeviceInfo', {});
      setState(() {
        _info = Map<String, dynamic>.from(info);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('❌ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Device Info', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF667EEA)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Device ID Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [const Color(0xFF667EEA).withOpacity(0.15), const Color(0xFF764BA2).withOpacity(0.08)],
                      ),
                      border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.fingerprint, color: const Color(0xFF667EEA).withOpacity(0.6), size: 48),
                        const SizedBox(height: 12),
                        const Text('DEVICE ID', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SelectableText(
                          _info['deviceId']?.toString() ?? 'N/A',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace', letterSpacing: 1),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _info['deviceId']?.toString() ?? ''));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: const Text('Device ID copied!'), backgroundColor: Colors.green.shade700, duration: const Duration(seconds: 1)),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.copy, color: const Color(0xFF667EEA).withOpacity(0.6), size: 14),
                              const SizedBox(width: 6),
                              Text('Tap to copy', style: TextStyle(color: const Color(0xFF667EEA).withOpacity(0.6), fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Location Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.green.withOpacity(0.06),
                      border: Border.all(color: Colors.green.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.location_on, color: Colors.green.withOpacity(0.6), size: 40),
                        const SizedBox(height: 12),
                        const Text('LOCATION', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _LocationValue('Latitude', _info['latitude']?.toString() ?? '0.0')),
                            const SizedBox(width: 12),
                            Expanded(child: _LocationValue('Longitude', _info['longitude']?.toString() ?? '0.0')),
                          ],
                        ),
                        if ((_info['latitude'] ?? 0.0) == 0.0 && (_info['longitude'] ?? 0.0) == 0.0) ...[
                          const SizedBox(height: 12),
                          Text('Location not available — check permissions', style: TextStyle(color: Colors.orange.withOpacity(0.6), fontSize: 11)),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                 
                   
                ],
              ),
            ),
    );
  }
}

class _LocationValue extends StatelessWidget {
  final String label;
  final String value;
  const _LocationValue(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.green.withOpacity(0.08),
        border: Border.all(color: Colors.green.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.green.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.green, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          Text(value.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}