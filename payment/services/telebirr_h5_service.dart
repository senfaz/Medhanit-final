import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
// Conditional imports for web-only libraries
import 'package:flutter_grocery/helper/js_stub.dart' if (dart.library.html) 'dart:js' as js;
import 'package:flutter_grocery/helper/web_stub.dart' if (dart.library.html) 'dart:html' as html;
import '../../../helper/api_checker_helper.dart';
import '../../../utill/app_constants.dart';

class TelebirrH5Service {
  static final TelebirrH5Service _instance = TelebirrH5Service._internal();
  factory TelebirrH5Service() => _instance;
  TelebirrH5Service._internal();

  final StreamController<Map<String, dynamic>> _paymentResultController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get paymentResultStream =>
      _paymentResultController.stream;

  /// Check if running in H5 context (within Telebirr SuperApp)
  static bool get isH5Context {
    if (!kIsWeb) return false;

    try {
      return js.context.hasProperty('consumerapp') &&
             js.context['consumerapp'] != null;
    } catch (e) {
      debugPrint('Error checking H5 context: $e');
      return false;
    }
  }

  /// Create order for H5 payment via backend API
  Future<Map<String, dynamic>> createOrderWeb({
    required String amount,
    required String orderId,
    required String userId,
    required String customerName,
    required String customerPhone,
    String? description,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/payment/telebirr/create-order-web');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'merch_order_id': orderId,
          'user_id': userId,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'description': description ?? 'Payment for order $orderId',
          'return_url': '${html.window.location.origin}/payment-success',
          'notify_url': '${AppConstants.baseUrl}/payment/telebirr/webhook',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create order'
        };
      }
    } catch (e) {
      debugPrint('Error creating H5 order: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  /// Initiate H5 payment using JavaScript bridge
  Future<bool> initiateH5Payment({
    required String rawRequest,
    required String orderId,
  }) async {
    if (!isH5Context) {
      debugPrint('Not in H5 context, cannot initiate H5 payment');
      return false;
    }

    try {
      // Set up global callback function for Telebirr
      js.context['handleTelebirrCallback'] = js.allowInterop(_handlePaymentCallback);

      // Call Telebirr SuperApp payment function
      final paymentParams = {
        'functionName': 'js_fun_start_pay',
        'params': {
          'rawRequest': rawRequest,
          'functionCallBackName': 'handleTelebirrCallback'
        }
      };

      js.context['consumerapp'].callMethod('evaluate', [
        jsonEncode(paymentParams)
      ]);

      debugPrint('H5 payment initiated for order: $orderId');
      return true;
    } catch (e) {
      debugPrint('Error initiating H5 payment: $e');
      _paymentResultController.add({
        'status': 'error',
        'message': 'Failed to initiate payment: ${e.toString()}'
      });
      return false;
    }
  }

  /// Handle payment callback from Telebirr SuperApp
  void _handlePaymentCallback(dynamic result) {
    try {
      debugPrint('Received H5 payment callback: $result');

      Map<String, dynamic> paymentResult;

      if (result is String) {
        paymentResult = jsonDecode(result);
      } else if (result is Map) {
        paymentResult = Map<String, dynamic>.from(result);
      } else {
        paymentResult = {
          'status': 'error',
          'message': 'Invalid callback result format'
        };
      }

      // Process the payment result
      _processPaymentResult(paymentResult);
    } catch (e) {
      debugPrint('Error handling payment callback: $e');
      _paymentResultController.add({
        'status': 'error',
        'message': 'Failed to process payment result: ${e.toString()}'
      });
    }
  }

  /// Process payment result and emit to stream
  void _processPaymentResult(Map<String, dynamic> result) {
    try {
      // Normalize the result format
      final processedResult = <String, dynamic>{
        'status': _getPaymentStatus(result),
        'message': _getPaymentMessage(result),
        'transactionId': result['transactionId'] ?? result['transaction_id'],
        'orderId': result['orderId'] ?? result['order_id'],
        'amount': result['amount'],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'rawResult': result,
      };

      debugPrint('Processed H5 payment result: $processedResult');
      _paymentResultController.add(processedResult);
    } catch (e) {
      debugPrint('Error processing payment result: $e');
      _paymentResultController.add({
        'status': 'error',
        'message': 'Failed to process payment result: ${e.toString()}'
      });
    }
  }

  /// Extract payment status from result
  String _getPaymentStatus(Map<String, dynamic> result) {
    final status = result['status'] ?? result['result'] ?? result['code'];

    if (status == null) return 'error';

    final statusStr = status.toString().toLowerCase();

    if (statusStr.contains('success') || statusStr == '0' || statusStr == 'ok') {
      return 'success';
    } else if (statusStr.contains('cancel') || statusStr.contains('abort')) {
      return 'cancelled';
    } else if (statusStr.contains('fail') || statusStr.contains('error')) {
      return 'failed';
    } else {
      return 'unknown';
    }
  }

  /// Extract payment message from result
  String _getPaymentMessage(Map<String, dynamic> result) {
    return result['message'] ??
           result['msg'] ??
           result['description'] ??
           'Payment completed';
  }

  /// Query order status from backend
  Future<Map<String, dynamic>> queryOrderStatus(String orderId) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/payment/telebirr/query-order');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'order_id': orderId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to query order status'
        };
      }
    } catch (e) {
      debugPrint('Error querying order status: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  /// Clean up resources
  void dispose() {
    _paymentResultController.close();

    // Clean up global callback
    try {
      js.context.deleteProperty('handleTelebirrCallback');
    } catch (e) {
      debugPrint('Error cleaning up callback: $e');
    }
  }
}
