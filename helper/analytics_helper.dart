import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsHelper {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Screen tracking
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      if (kDebugMode) {
        print('Analytics: Screen view logged - $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Failed to log screen view - $e');
      }
    }
  }

  // E-commerce events
  static Future<void> logPurchase({
    required String transactionId,
    required double value,
    required String currency,
    List<AnalyticsEventItem>? items,
  }) async {
    try {
      await _analytics.logPurchase(
        transactionId: transactionId,
        value: value,
        currency: currency,
        items: items,
      );
      if (kDebugMode) {
        print('Analytics: Purchase logged - $transactionId, $value $currency');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Failed to log purchase - $e');
      }
    }
  }

  static Future<void> logAddToCart({
    required String currency,
    required double value,
    List<AnalyticsEventItem>? items,
  }) async {
    try {
      await _analytics.logAddToCart(
        currency: currency,
        value: value,
        items: items,
      );
      if (kDebugMode) {
        print('Analytics: Add to cart logged - $value $currency');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Failed to log add to cart - $e');
      }
    }
  }

  static Future<void> logRemoveFromCart({
    required String currency,
    required double value,
    List<AnalyticsEventItem>? items,
  }) async {
    try {
      await _analytics.logRemoveFromCart(
        currency: currency,
        value: value,
        items: items,
      );
      if (kDebugMode) {
        print('Analytics: Remove from cart logged - $value $currency');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Failed to log remove from cart - $e');
      }
    }
  }

  static Future<void> logViewItem({
    required String itemId,
    required String itemName,
    required String itemCategory,
    required double value,
    required String currency,
  }) async {
    try {
      await _analytics.logViewItem(
        currency: currency,
        value: value,
        items: [
          AnalyticsEventItem(
            itemId: itemId,
            itemName: itemName,
            itemCategory: itemCategory,
            price: value,
          ),
        ],
      );
      if (kDebugMode) {
        print('Analytics: View item logged - $itemName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Failed to log view item - $e');
      }
    }
  }

  // User engagement events
  static Future<void> logLogin({String? loginMethod}) async {
    try {
      await _analytics.logLogin(loginMethod: loginMethod);
      if (kDebugMode) {
        print('Analytics: Login logged - ${loginMethod ?? 'unknown'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Failed to log login - $e');
      }
    }
  }

  static Future<void> logSignUp({String? signUpMethod}) async {
    try {
      await _analytics.logSignUp(signUpMethod: signUpMethod ?? 'unknown');
      if (kDebugMode) {
        print('Analytics: Sign up logged - ${signUpMethod ?? 'unknown'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Failed to log sign up - $e');
      }
    }
  }

  static Future<void> logSearch({required String searchTerm}) async {
    try {
      await _analytics.logSearch(searchTerm: searchTerm);
      if (kDebugMode) {
        print('Analytics: Search logged - $searchTerm');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Failed to log search - $e');
      }
    }
  }

  // Custom events for pharmacy-specific actions
  static Future<void> logPrescriptionUpload({
    required String orderId,
    required int imageCount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'prescription_upload',
        parameters: {
          'order_id': orderId,
          'image_count': imageCount,
        },
      );
      if (kDebugMode) {
        print('Analytics: Prescription upload logged - Order: $orderId, Images: $imageCount');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Failed to log prescription upload - $e');
      }
    }
  }

  static Future<void> logTelebirrPayment({
    required String orderId,
    required double amount,
    required String status, // 'initiated', 'completed', 'failed'
  }) async {
    try {
      await _analytics.logEvent(
        name: 'telebirr_payment',
        parameters: {
          'order_id': orderId,
          'amount': amount,
          'status': status,
          'payment_method': 'telebirr',
        },
      );
      if (kDebugMode) {
        print('Analytics: Telebirr payment logged - Order: $orderId, Amount: $amount, Status: $status');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Failed to log Telebirr payment - $e');
      }
    }
  }

  static Future<void> logDeliveryTracking({
    required String orderId,
    required String status,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'delivery_tracking',
        parameters: {
          'order_id': orderId,
          'delivery_status': status,
        },
      );
      if (kDebugMode) {
        print('Analytics: Delivery tracking logged - Order: $orderId, Status: $status');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Failed to log delivery tracking - $e');
      }
    }
  }

  // User properties
  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      if (kDebugMode) {
        print('Analytics: User property set - $name: $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Failed to set user property - $e');
      }
    }
  }

  static Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      if (kDebugMode) {
        print('Analytics: User ID set - $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Failed to set user ID - $e');
      }
    }
  }

  // Generic event logging
  static Future<void> logCustomEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
      if (kDebugMode) {
        print('Analytics: Custom event logged - $eventName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: Failed to log custom event - $e');
      }
    }
  }
}
