/// errors : [{"code":"l_name","message":"The last name field is required."},{"code":"password","message":"The password field is required."}]
library;

class ErrorResponseModel {
  List<Errors>? _errors;
  String? _message;
  dynamic _code;

  List<Errors>? get errors => _errors;
  String? get message => _message;
  dynamic get code => _code;

  ErrorResponseModel({
    List<Errors>? errors,
    String? message,
    dynamic code}){
    _errors = errors;
    _message = message;
    _code = code;
  }

  ErrorResponseModel.fromJson(Map<String, dynamic> json) {
    _errors = [];
    if(json['errors'] != null) {
      json['errors'].forEach((v) {
        _errors!.add(Errors.fromJson(v));
      });
    }
    _message = json['message'];
    // Fix type casting issue - handle both String and int types
    if (json['code'] != null) {
      _code = json['code'] is String ? int.tryParse(json['code']) ?? 0 : json['code'];
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    if (_errors != null) {
      map["errors"] = _errors!.map((v) => v.toJson()).toList();
    }
    map["message"] = _message;
    map["code"] = _code;
    return map;
  }
}

/// code : "l_name"
/// message : "The last name field is required."

class Errors {
  String? _code;
  String? _message;

  String? get code => _code;
  String? get message => _message;

  Errors({
    String? code,
    String? message}){
    _code = code;
    _message = message;
  }

  Errors.fromJson(dynamic json) {
    _code = json["code"];
    _message = json["message"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["code"] = _code;
    map["message"] = _message;
    return map;
  }

}