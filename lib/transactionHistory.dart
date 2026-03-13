// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:gyroscope/addTransaction.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
 
 
// class TransactionHistoryScreen extends StatefulWidget {
//   final String backendUrl;
//   const TransactionHistoryScreen({super.key, required this.backendUrl});

//   @override
//   State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
// }

// class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
//   List<Map<String, dynamic>> _transactions = [];
//   bool _loading = true;
//   String _error = '';
//  static const _overlayChannel = MethodChannel('gyroscope_plugin/overlay');

//   @override
//   void initState() {
//     super.initState();
//     _fetchTransactions();
//   }
// Future<void> _fetchTransactions() async {
//     setState(() { _loading = true; _error = ''; });
//     try {
//       final info = await _overlayChannel.invokeMethod('getDeviceInfo', {});
//       final deviceId = info['deviceId'] ?? '';

//       final response = await http.get(
//         Uri.parse('${widget.backendUrl}/transaction/$deviceId?organization_id=2&product_id=1'),
//         headers: {'Content-Type': 'application/json'},
//       ).timeout(const Duration(seconds: 15));
// debugPrint("reposne ${response.body}");
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final list = data['data'] as List? ?? [];
//         setState(() {
//           _transactions = list.map((e) => Map<String, dynamic>.from(e)).toList();
//           _loading = false;
//         });
//       } else {
//         setState(() { _error = 'Server error: ${response.statusCode}'; _loading = false; });
//       }
//     } catch (e) {
//       setState(() { _error = 'Failed to load transactions'; _loading = false; });
//     }
//   }
//   // Future<void> _fetchTransactions() async {
//   //   setState(() { _loading = true; _error = ''; });
//   //   try {
//   //     final prefs = await SharedPreferences.getInstance();
//   //     final deviceId = prefs.getString('persistent_device_id') ?? '';

//   //     final response = await http.get(
//   //       Uri.parse('${widget.backendUrl}/transaction/list?device_id=$deviceId'),
//   //       headers: {'Content-Type': 'application/json'},
//   //     ).timeout(const Duration(seconds: 15));

//   //     if (response.statusCode == 200) {
//   //       final data = jsonDecode(response.body);
//   //       final list = data['data'] as List? ?? [];
//   //       setState(() {
//   //         _transactions = list.map((e) => Map<String, dynamic>.from(e)).toList();
//   //         _loading = false;
//   //       });
//   //     } else {
//   //       setState(() { _error = 'Server error: ${response.statusCode}'; _loading = false; });
//   //     }
//   //   } catch (e) {
//   //     setState(() { _error = 'Failed to load transactions'; _loading = false; });
//   //   }
//   // }

//   String _formatDate(String? dateStr) {
//     if (dateStr == null || dateStr.isEmpty) return '';
//     try {
//       final date = DateTime.parse(dateStr);
//       return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
//     } catch (_) {
//       return dateStr;
//     }
//   }

//   String _getActivityLabel(Map<String, dynamic> tx) {
//     final type = (tx['type'] ?? tx['activity'] ?? 'Transaction').toString();
//     final chain = (tx['chain'] ?? '').toString().toUpperCase();
//     return '$type $chain'.trim();
//   }

//   void _showDetail(Map<String, dynamic> tx) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (_) => Container(
//         decoration: const BoxDecoration(
//           color: Color(0xFF1A1A2E),
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text('Activity Details', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
//                 GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: const Icon(Icons.close, color: Colors.white54, size: 24),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             _detailRow('Status', tx['status'] ?? 'Complete', Colors.greenAccent),
//             _detailRow('Network', (tx['chain'] ?? '').toString().toUpperCase(), Colors.white70),
//             _detailRow('Amount', tx['amount']?.toString() ?? '', Colors.greenAccent),
//             _detailRow('Transaction Hash', tx['transaction_hash'] ?? '', const Color(0xFF667EEA)),
//             _detailRow('Sender', tx['sender_wallet'] ?? '', Colors.white54),
//             _detailRow('Receiver', tx['receiver_wallet'] ?? '', Colors.white54),
//             const SizedBox(height: 16),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _detailRow(String label, String value, Color valueColor) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: const TextStyle(color: Colors.white60, fontSize: 14)),
//           const SizedBox(width: 16),
//           Flexible(
//             child: Text(
//               value.length > 24 ? '${value.substring(0, 24)}...' : value,
//               style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.w600),
//               textAlign: TextAlign.end,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF050510),
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: const Text('Transactions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add_circle_outline, color: Color(0xFF667EEA)),
//             onPressed: () async {
//               final result = await Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => AddTransactionScreen(backendUrl: widget.backendUrl)),
//               );
//               if (result == true) _fetchTransactions();
//             },
//           ),
//         ],
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator(color: Color(0xFF667EEA)))
//           : _error.isNotEmpty
//               ? Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(_error, style: const TextStyle(color: Colors.white54)),
//                       const SizedBox(height: 12),
//                       ElevatedButton(
//                         onPressed: _fetchTransactions,
//                         style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA)),
//                         child: const Text('Retry', style: TextStyle(color: Colors.white)),
//                       ),
//                     ],
//                   ),
//                 )
//               : _transactions.isEmpty
//                   ? const Center(child: Text('No transactions yet', style: TextStyle(color: Colors.white38, fontSize: 16)))
//                   : RefreshIndicator(
//                       onRefresh: _fetchTransactions,
//                       color: const Color(0xFF667EEA),
//                       child: Column(
//                         children: [
//                           // Header
//                           Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                             child: Row(
//                               children: const [
//                                 Expanded(flex: 3, child: Text('Activity', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1))),
//                                 Expanded(flex: 2, child: Text('Amount', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1), textAlign: TextAlign.center)),
//                                 Expanded(flex: 2, child: Text('Date', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1), textAlign: TextAlign.end)),
//                               ],
//                             ),
//                           ),
//                           // List
//                           Expanded(
//                             child: ListView.builder(
//                               padding: const EdgeInsets.symmetric(horizontal: 16),
//                               itemCount: _transactions.length,
//                               itemBuilder: (_, i) {
//                                 final tx = _transactions[i];
//                                 return GestureDetector(
//                                   onTap: () => _showDetail(tx),
//                                   child: Container(
//                                     margin: const EdgeInsets.only(bottom: 10),
//                                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                                     decoration: BoxDecoration(
//                                       color: Colors.white.withOpacity(0.04),
//                                       borderRadius: BorderRadius.circular(12),
//                                       border: Border.all(color: Colors.white.withOpacity(0.08)),
//                                     ),
//                                     child: Row(
//                                       children: [
//                                         // Icon
//                                         Container(
//                                           width: 36, height: 36,
//                                           decoration: BoxDecoration(
//                                             shape: BoxShape.circle,
//                                             color: const Color(0xFF667EEA).withOpacity(0.15),
//                                           ),
//                                           child: Icon(
//                                             (tx['type'] ?? '').toString().toLowerCase().contains('receive')
//                                                 ? Icons.arrow_downward_rounded
//                                                 : Icons.arrow_upward_rounded,
//                                             color: (tx['type'] ?? '').toString().toLowerCase().contains('receive')
//                                                 ? Colors.greenAccent
//                                                 : Colors.orangeAccent,
//                                             size: 18,
//                                           ),
//                                         ),
//                                         const SizedBox(width: 12),
//                                         // Activity
//                                         Expanded(
//                                           flex: 3,
//                                           child: Text(
//                                             _getActivityLabel(tx),
//                                             style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
//                                             overflow: TextOverflow.ellipsis,
//                                           ),
//                                         ),
//                                         // Amount
//                                         Expanded(
//                                           flex: 2,
//                                           child: Text(
//                                             tx['amount']?.toString() ?? '',
//                                             style: const TextStyle(color: Colors.white70, fontSize: 14),
//                                             textAlign: TextAlign.center,
//                                           ),
//                                         ),
//                                         // Date
//                                         Expanded(
//                                           flex: 2,
//                                           child: Text(
//                                             _formatDate(tx['created_at'] ?? tx['date'] ?? ''),
//                                             style: const TextStyle(color: Colors.white38, fontSize: 13),
//                                             textAlign: TextAlign.end,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gyroscope/addTransaction.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
 

const _overlayChannel = MethodChannel('gyroscope_plugin/overlay');

class TransactionHistoryScreen extends StatefulWidget {
  final String backendUrl;
  const TransactionHistoryScreen({super.key, required this.backendUrl});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() { _loading = true; _error = ''; });
    try {
       final prefs = await SharedPreferences.getInstance();
      // final info = await _overlayChannel.invokeMethod('getDeviceInfo', {});final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('persistent_device_id') ?? '';
      //final deviceId = info['deviceId'] ?? '';

      final response = await http.get(
        Uri.parse('${widget.backendUrl}/transaction/$deviceId?organization_id=1&product_id=1'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data']?['transactions'] as List? ?? [];
        setState(() {
          _transactions = list.map((e) => Map<String, dynamic>.from(e)).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = 'Server error: ${response.statusCode}'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Failed to load transactions'; _loading = false; });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
    } catch (_) {
      return dateStr;
    }
  }

  String _getActivityLabel(Map<String, dynamic> tx) {
    final type = (tx['transaction_type'] ?? 'send').toString();
    final symbol = (tx['token_symbol'] ?? '').toString().toUpperCase();
    final label = type[0].toUpperCase() + type.substring(1);
    return '$label $symbol'.trim();
  }

  void _showDetail(Map<String, dynamic> tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Activity Details', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white54, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // _detailRow('Status', (tx['status'] ?? '').toString().toUpperCase(),
            //     tx['status'] == 'pending' ? Colors.orangeAccent : Colors.greenAccent),
            _detailRow('Network', (tx['chain'] ?? '').toString().toUpperCase(), Colors.white70),
            _detailRow('Type', (tx['transaction_type'] ?? '').toString().toUpperCase(), Colors.white70),
            _detailRow('Amount', '${tx['amount'] ?? ''} ${(tx['token_symbol'] ?? '').toString().toUpperCase()}', Colors.greenAccent),
            _detailRow('Transaction Hash', tx['transaction_hash'] ?? '', const Color(0xFF667EEA)),
            _detailRow('Sender', tx['sender_wallet'] ?? '', Colors.white54),
            _detailRow('Receiver', tx['receiver_wallet'] ?? '', Colors.white54),
            if (tx['gas_fee'] != null)
              _detailRow('Gas Fee', tx['gas_fee'].toString(), Colors.white54),
            if (tx['block_number'] != null)
              _detailRow('Block', tx['block_number'].toString(), Colors.white54),
            _detailRow('Date', _formatDate(tx['createdAt'] ?? ''), Colors.white38),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 14)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value.length > 24 ? '${value.substring(0, 24)}...' : value,
              style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Transactions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF667EEA)),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddTransactionScreen(backendUrl: widget.backendUrl)),
              );
              if (result == true) _fetchTransactions();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF667EEA)))
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error, style: const TextStyle(color: Colors.white54)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchTransactions,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA)),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : _transactions.isEmpty
                  ? const Center(child: Text('No transactions yet', style: TextStyle(color: Colors.white38, fontSize: 16)))
                  : RefreshIndicator(
                      onRefresh: _fetchTransactions,
                      color: const Color(0xFF667EEA),
                      child: Column(
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              children: const [
                                Expanded(flex: 3, child: Text('Activity', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1))),
                                Expanded(flex: 2, child: Text('Amount', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1), textAlign: TextAlign.center)),
                                Expanded(flex: 2, child: Text('Date', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1), textAlign: TextAlign.end)),
                              ],
                            ),
                          ),
                          // List
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _transactions.length,
                              itemBuilder: (_, i) {
                                final tx = _transactions[i];
                                return GestureDetector(
                                  onTap: () => _showDetail(tx),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                                    ),
                                    child: Row(
                                      children: [
                                        // Icon
                                        Container(
                                          width: 36, height: 36,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF667EEA).withOpacity(0.15),
                                          ),
                                          child: Icon(
                                            (tx['transaction_type'] ?? '').toString().toLowerCase() == 'receive'
                                                ? Icons.arrow_downward_rounded
                                                : Icons.arrow_upward_rounded,
                                            color: (tx['transaction_type'] ?? '').toString().toLowerCase() == 'receive'
                                                ? Colors.greenAccent
                                                : Colors.orangeAccent,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Activity
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            _getActivityLabel(tx),
                                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Amount + symbol
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '${tx['amount'] ?? ''}  ${(tx['token_symbol'] ?? '').toString().toUpperCase()}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        // Date
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            _formatDate(tx['createdAt'] ?? ''),
                                            style: const TextStyle(color: Colors.white38, fontSize: 13),
                                            textAlign: TextAlign.end,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}