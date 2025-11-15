import 'package:flutter/foundation.dart';
// Conditional imports for web-only libraries
import 'package:flutter_grocery/helper/web_stub.dart' if (dart.library.html) 'dart:html' as html;
import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter_grocery/helper/js_stub.dart' if (dart.library.html) 'dart:js' as js;

class DeviceHelper {
  /// Check if running on web platform
  static bool get isWeb => kIsWeb;

  /// Check if running on mobile platform (Android/iOS native)
  static bool get isMobile => !kIsWeb;

  /// Check if running in mobile browser (web on mobile device)
  static bool get isMobileBrowser {
    if (!kIsWeb) return false;

    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      return _isMobileUserAgent(userAgent);
    } catch (e) {
      debugPrint('Error checking mobile browser: $e');
      return false;
    }
  }

  /// Check if running on desktop browser
  static bool get isDesktopBrowser {
    if (!kIsWeb) return false;
    return !isMobileBrowser;
  }

  /// Check if running within Telebirr SuperApp context
  static bool get isTelebirrSuperAppContext {
    if (!kIsWeb) return false;

    try {
      // Check for Telebirr SuperApp JavaScript bridge
      return js.context.hasProperty('consumerapp') &&
             js.context['consumerapp'] != null;
    } catch (e) {
      debugPrint('Error checking Telebirr SuperApp context: $e');
      return false;
    }
  }

  /// Get device type as string
  static String get deviceType {
    if (!kIsWeb) return 'mobile_native';
    if (isTelebirrSuperAppContext) return 'telebirr_superapp';
    if (isMobileBrowser) return 'mobile_browser';
    if (isDesktopBrowser) return 'desktop_browser';
    return 'unknown';
  }

  /// Check if device supports Telebirr deep linking
  static bool get supportsDeepLinking {
    if (!kIsWeb) return true; // Native mobile apps support deep linking
    if (isTelebirrSuperAppContext) return true; // SuperApp supports H5 integration
    if (isMobileBrowser) return true; // Mobile browsers support URL schemes
    return false; // Desktop browsers don't support deep linking
  }

  /// Get user agent string (web only)
  static String get userAgent {
    if (!kIsWeb) return 'native_app';

    try {
      return html.window.navigator.userAgent;
    } catch (e) {
      debugPrint('Error getting user agent: $e');
      return 'unknown';
    }
  }

  /// Get platform name
  static String get platformName {
    if (!kIsWeb) return 'native';

    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();

      if (userAgent.contains('android')) return 'android';
      if (userAgent.contains('iphone') || userAgent.contains('ipad')) return 'ios';
      if (userAgent.contains('windows')) return 'windows';
      if (userAgent.contains('macintosh')) return 'macos';
      if (userAgent.contains('linux')) return 'linux';

      return 'web';
    } catch (e) {
      debugPrint('Error getting platform name: $e');
      return 'unknown';
    }
  }

  /// Check if device is Android
  static bool get isAndroid {
    if (!kIsWeb) return defaultTargetPlatform == TargetPlatform.android;

    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      return userAgent.contains('android');
    } catch (e) {
      return false;
    }
  }

  /// Check if device is iOS
  static bool get isIOS {
    if (!kIsWeb) return defaultTargetPlatform == TargetPlatform.iOS;

    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      return userAgent.contains('iphone') || userAgent.contains('ipad');
    } catch (e) {
      return false;
    }
  }

  /// Get recommended payment method based on device context
  static String get recommendedPaymentMethod {
    if (isTelebirrSuperAppContext) return 'h5_integration';
    if (isMobileBrowser) return 'deep_linking';
    if (isDesktopBrowser) return 'qr_code';
    if (isMobile) return 'native_integration';
    return 'fallback';
  }

  /// Check if user agent indicates mobile device
  static bool _isMobileUserAgent(String userAgent) {
    final mobileKeywords = [
      'mobile',
      'android',
      'iphone',
      'ipad',
      'ipod',
      'blackberry',
      'windows phone',
      'opera mini',
      'iemobile',
      'mobile safari',
    ];

    return mobileKeywords.any((keyword) => userAgent.contains(keyword));
  }

  /// Get screen size category (web only)
  static String get screenSizeCategory {
    if (!kIsWeb) return 'mobile';

    try {
      final width = html.window.screen?.width ?? 0;

      if (width >= 1200) return 'desktop';
      if (width >= 768) return 'tablet';
      return 'mobile';
    } catch (e) {
      debugPrint('Error getting screen size: $e');
      return 'unknown';
    }
  }

  /// Check if device supports touch
  static bool get supportsTouch {
    if (!kIsWeb) return isMobile;

    try {
      return (html.window.navigator.maxTouchPoints ?? 0) > 0;
    } catch (e) {
      return false;
    }
  }

  /// Generate Telebirr deep link URL
  static String generateTelebirrDeepLink({
    required String appId,
    required String shortCode,
    required String receiveCode,
  }) {
    return 'telebirr://pay?appId=$appId&shortCode=$shortCode&receiveCode=$receiveCode';
  }

  /// Generate Telebirr app download URL based on platform
  static String get telebirrDownloadUrl {
    if (isAndroid) {
      return 'https://play.google.com/store/apps/details?id=com.ethiotelecom.telebirr';
    } else if (isIOS) {
      return 'https://apps.apple.com/app/telebirr/id1596507090';
    } else {
      return 'https://www.ethiotelecom.et/telebirr/';
    }
  }

  /// Get device info summary for debugging
  static Map<String, dynamic> get deviceInfo {
    return {
      'isWeb': isWeb,
      'isMobile': isMobile,
      'isMobileBrowser': isMobileBrowser,
      'isDesktopBrowser': isDesktopBrowser,
      'isTelebirrSuperAppContext': isTelebirrSuperAppContext,
      'deviceType': deviceType,
      'platformName': platformName,
      'supportsDeepLinking': supportsDeepLinking,
      'recommendedPaymentMethod': recommendedPaymentMethod,
      'screenSizeCategory': screenSizeCategory,
      'supportsTouch': supportsTouch,
      'userAgent': userAgent,
    };
  }
}
