import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _overlayChannel = MethodChannel('gyroscope_plugin/overlay');

class AddTransactionScreen extends StatefulWidget {
  final String backendUrl;
  const AddTransactionScreen({super.key, required this.backendUrl});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _hashCtrl = TextEditingController();
  final _receiverCtrl = TextEditingController();
  final _senderCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _chainCtrl = TextEditingController();

  bool _sending = false;

  // Future<void> _submit() async {
  //   if (_sending) return;

  //   final prefs = await SharedPreferences.getInstance();
  //   final deviceId = prefs.getString('persistent_device_id') ?? '';

  //   // Step 1: SDK validates
  //   setState(() => _sending = true);

  //   try {
  //     final validated = await _overlayChannel.invokeMethod('validateTransaction', {
  //       'fields': {
  //         'transaction_hash': _hashCtrl.text.trim(),
  //         'receiver_wallet': _receiverCtrl.text.trim(),
  //         'sender_wallet': _senderCtrl.text.trim(),
  //         'amount': _amountCtrl.text.trim(),
  //         'chain': _chainCtrl.text.trim(),
  //         'device_id': deviceId,
  //       },
  //     });

  //     if (validated['validated'] != true) {
  //       _showSnack(validated['error']?.toString() ?? 'Validation failed', Colors.red.shade700);
  //       setState(() => _sending = false);
  //       return;
  //     }

  //     // Step 2: API call
  //     final response = await http.post(
  //       Uri.parse('${widget.backendUrl}/transaction/save'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(validated),
  //     ).timeout(const Duration(seconds: 30));

  //     setState(() => _sending = false);

  //     if (response.statusCode >= 200 && response.statusCode < 300) {
  //       _showSnack('Transaction saved!', Colors.green.shade700);
  //       if (mounted) Navigator.pop(context, true); // true = refresh list
  //     } else {
  //       _showSnack('Server error: ${response.statusCode}', Colors.red.shade700);
  //     }
  //   } catch (e) {
  //     setState(() => _sending = false);
  //     _showSnack('Error: $e', Colors.red.shade700);
  //   }
  // }


Future<void> _submit() async {
    if (_sending) return;

    // final info = await _overlayChannel.invokeMethod('getDeviceInfo', {});
    // final deviceId = info['deviceId'] ?? '';
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('persistent_device_id') ?? '';

    setState(() => _sending = true);

    try {
      final validated = await _overlayChannel.invokeMethod('validateTransaction', {
        'fields': {
          'transaction_hash': _hashCtrl.text.trim(),
          'receiver_wallet': _receiverCtrl.text.trim(),
          'sender_wallet': _senderCtrl.text.trim(),
          'amount': _amountCtrl.text.trim(),
          'chain': _chainCtrl.text.trim(),
          'device_id': deviceId,
        },
      });

      if (validated['validated'] != true) {
        _showSnack(validated['error']?.toString() ?? 'Validation failed', Colors.red.shade700);
        setState(() => _sending = false);
        return;
      }

      // API call with extra fields

      final response = await http.post(
        Uri.parse('${widget.backendUrl}/transaction/record'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          ...Map<String, dynamic>.from(validated),
          'organization_id': '1',
          'product_id': '1',
          'token_symbol': 'usdt',
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint("respinse ${response.body}{}");

      setState(() => _sending = false);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSnack('Transaction saved!', Colors.green.shade700);
        if (mounted) Navigator.pop(context, true);
      } else {
        _showSnack('Server error: ${response.statusCode}', Colors.red.shade700);
      }
    } catch (e) {
      setState(() => _sending = false);
      _showSnack('Error: $e', Colors.red.shade700);
    }
  }
  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {TextInputType? keyboard, String? hint, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboard,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint ?? 'Enter $label',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF667EEA), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _hashCtrl.dispose();
    _receiverCtrl.dispose();
    _senderCtrl.dispose();
    _amountCtrl.dispose();
    _chainCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Add Transaction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildField('Transaction Hash', _hashCtrl, hint: '0xabc123...'),
            _buildField('Sender Wallet', _senderCtrl, hint: '0xSender...'),
            _buildField('Receiver Wallet', _receiverCtrl, hint: '0xReceiver...'),
            _buildField('Amount', _amountCtrl, keyboard: const TextInputType.numberWithOptions(decimal: true), hint: '0.5'),
            _buildField('Chain', _chainCtrl, hint: 'ethereum, polygon, solana...'),

            const SizedBox(height: 8),

            // Send Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _sending ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  disabledBackgroundColor: const Color(0xFF667EEA).withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text(
                        'SEND TRANSACTION',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}