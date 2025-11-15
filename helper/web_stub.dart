// Stub implementation for dart:html APIs on non-web platforms
// This file provides empty implementations to prevent compilation errors

class Window {
  Location get location => Location();
  Navigator get navigator => Navigator();
  Screen? get screen => Screen();
  
  void open(String url, String target) {
    // No-op on non-web platforms
  }
}

class Location {
  String get origin => 'https://localhost';
  String get href => 'https://localhost';
  set href(String value) {
    // No-op on non-web platforms
  }
}

class Navigator {
  String get userAgent => 'Flutter Mobile App';
  int get maxTouchPoints => 0;
  Clipboard? get clipboard => Clipboard();
}

class Screen {
  int get width => 375; // Default mobile width
}

class Clipboard {
  Future<void> writeText(String text) async {
    // No-op on non-web platforms
  }
}

// Global window instance
final Window window = Window();
