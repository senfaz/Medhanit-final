import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_grocery/helper/custom_snackbar_helper.dart';

class TelebirrService {
  static const MethodChannel _channel = MethodChannel('com.medhanit.online/telebirr');
  static StreamController<Map<String, dynamic>>? _paymentResultController;

  static Stream<Map<String, dynamic>> get paymentResultStream {
    _paymentResultController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _paymentResultController!.stream;
  }

  static Future<void> initialize() async {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPaymentResult':
        final result = Map<String, dynamic>.from(call.arguments);
        _paymentResultController?.add(result);
        break;
      default:
        if (kDebugMode) {
          print('Unknown method call: ${call.method}');
        }
    }
  }

  /// Initiate Telebirr payment using the official SDK
  static Future<Map<String, dynamic>> initiateTelebirrPayment({
    required String appId,
    required String shortCode,
    required String receiveCode,
  }) async {
    try {
      if (kDebugMode) {
        print('TelebirrService: Initiating payment with receiveCode: $receiveCode');
      }

      final result = await _channel.invokeMethod('initiateTelebirrPayment', {
        'appId': appId,
        'shortCode': shortCode,
        'receiveCode': receiveCode,
      });

      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('TelebirrService error: ${e.message}');
      }

      return {
        'status': 'error',
        'message': e.message ?? 'Unknown error occurred',
        'code': e.code,
      };
    } catch (e) {
      if (kDebugMode) {
        print('TelebirrService unexpected error: $e');
      }

      return {
        'status': 'error',
        'message': 'Unexpected error: $e',
      };
    }
  }

  /// Create order and get receiveCode from backend
  static Future<String?> createTelebirrOrder({
    required String orderId,
    required double amount,
    required String appId,
    required String accessToken,
  }) async {
    try {
      // This would typically call your Laravel backend to create the order
      // and get the receiveCode from Telebirr API

      // For now, we'll simulate this - you'll need to implement the actual backend call
      if (kDebugMode) {
        print('TelebirrService: Creating order for orderId: $orderId, amount: $amount');
      }

      // TODO: Replace with actual backend API call
      // Example backend call:
      // final response = await http.post(
      //   Uri.parse('${AppConstants.baseUrl}/api/v1/telebirr/create-order'),
      //   headers: {'Authorization': 'Bearer $accessToken'},
      //   body: {
      //     'order_id': orderId,
      //     'amount': amount.toString(),
      //     'app_id': appId,
      //   },
      // );

      // For testing, return a properly formatted receiveCode as per official docs
      // Format: TELEBIRR$BUYGOODS$shortCode$amount$prepayId$timeout
      // In production, this would come from your backend after calling Telebirr API
      final prepayId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      final testReceiveCode = 'TELEBIRR\$BUYGOODS\$245431\$${amount.toStringAsFixed(2)}\$${prepayId}\$120m';

      if (kDebugMode) {
        print('TelebirrService: Generated test receiveCode: $testReceiveCode');
      }

      return testReceiveCode;

    } catch (e) {
      if (kDebugMode) {
        print('TelebirrService: Error creating order: $e');
      }
      return null;
    }
  }

  /// Get return app configuration for Telebirr
  static String getReturnAppConfig() {
    return jsonEncode({
      "activity": "com.medhanit.online.MainActivity",
      "packageName": "com.medhanit.online"
    });
  }
  
  /// Dispose resources
  static void dispose() {
    _paymentResultController?.close();
    _paymentResultController = null;
  }
}
