// Stub implementation for dart:js APIs on non-web platforms
// This file provides empty implementations to prevent compilation errors

class JsObject {
  bool hasProperty(String property) => false;
  dynamic operator [](String property) => null;
  void operator []=(String property, dynamic value) {
    // No-op on non-web platforms
  }
  
  dynamic callMethod(String method, [List? args]) {
    // No-op on non-web platforms
    return null;
  }
  
  void deleteProperty(String property) {
    // No-op on non-web platforms
  }
}

// Global context object
final JsObject context = JsObject();

// allowInterop function stub
Function allowInterop(Function f) {
  // Return the function as-is on non-web platforms
  return f;
}
