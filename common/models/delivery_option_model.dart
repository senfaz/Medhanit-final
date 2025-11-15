class DeliveryOptionModel {
  final String type;
  final String title;
  final String description;
  final double charge;
  final DateTime estimatedDeliveryTime;
  final bool available;
  final String icon;
  final String availabilityMessage;
  final int? timeLimitHours;
  final AvailabilityWindow? availabilityWindow;
  final bool? eligible;
  final double? threshold;
  final int? deliveryDays;
  final double? remainingAmount;

  DeliveryOptionModel({
    required this.type,
    required this.title,
    required this.description,
    required this.charge,
    required this.estimatedDeliveryTime,
    required this.available,
    required this.icon,
    required this.availabilityMessage,
    this.timeLimitHours,
    this.availabilityWindow,
    this.eligible,
    this.threshold,
    this.deliveryDays,
    this.remainingAmount,
  });

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory DeliveryOptionModel.fromJson(Map<String, dynamic> json) {
    return DeliveryOptionModel(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      charge: (json['charge'] ?? 0).toDouble(),
      estimatedDeliveryTime: DateTime.parse(json['estimated_delivery_time'] ?? DateTime.now().toIso8601String()),
      available: json['available'] ?? false,
      icon: json['icon'] ?? '',
      availabilityMessage: json['availability_message'] ?? '',
      timeLimitHours: _parseInt(json['time_limit_hours']),
      availabilityWindow: json['availability_window'] != null
          ? AvailabilityWindow.fromJson(json['availability_window'])
          : null,
      eligible: json['eligible'],
      threshold: json['threshold']?.toDouble(),
      deliveryDays: _parseInt(json['delivery_days']),
      remainingAmount: json['remaining_amount']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'charge': charge,
      'estimated_delivery_time': estimatedDeliveryTime.toIso8601String(),
      'available': available,
      'icon': icon,
      'availability_message': availabilityMessage,
      'time_limit_hours': timeLimitHours,
      'availability_window': availabilityWindow?.toJson(),
      'eligible': eligible,
      'threshold': threshold,
      'delivery_days': deliveryDays,
      'remaining_amount': remainingAmount,
    };
  }

  bool get isFastDelivery => type == 'fast';
  bool get isStandardDelivery => type == 'standard';
  bool get isFreeDelivery => type == 'free';

  bool get isAvailable => available;
  bool get isEligibleForFree => eligible ?? false;
  bool get hasRemainingAmount => (remainingAmount ?? 0) > 0;

  String get formattedCharge {
    if (charge == 0) return 'Free';
    return '\$${charge.toStringAsFixed(2)}';
  }

  String get deliveryTypeIcon {
    switch (type) {
      case 'fast':
        return 'assets/svg/fast_delivery.svg';
      case 'standard':
        return 'assets/svg/standard_delivery.svg';
      case 'free':
        return 'assets/svg/free_delivery.svg';
      default:
        return 'assets/svg/delivery.svg';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryOptionModel &&
        other.type == type &&
        other.title == title &&
        other.description == description &&
        other.charge == charge &&
        other.available == available &&
        other.icon == icon;
  }

  @override
  int get hashCode {
    return type.hashCode ^
        title.hashCode ^
        description.hashCode ^
        charge.hashCode ^
        available.hashCode ^
        icon.hashCode;
  }

  DeliveryOptionModel copyWith({
    String? type,
    String? title,
    String? description,
    double? charge,
    DateTime? estimatedDeliveryTime,
    bool? available,
    String? icon,
    String? availabilityMessage,
    int? timeLimitHours,
    AvailabilityWindow? availabilityWindow,
    bool? eligible,
    double? threshold,
    int? deliveryDays,
    double? remainingAmount,
  }) {
    return DeliveryOptionModel(
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      charge: charge ?? this.charge,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      available: available ?? this.available,
      icon: icon ?? this.icon,
      availabilityMessage: availabilityMessage ?? this.availabilityMessage,
      timeLimitHours: timeLimitHours ?? this.timeLimitHours,
      availabilityWindow: availabilityWindow ?? this.availabilityWindow,
      eligible: eligible ?? this.eligible,
      threshold: threshold ?? this.threshold,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      remainingAmount: remainingAmount ?? this.remainingAmount,
    );
  }
}

class AvailabilityWindow {
  final String start;
  final String end;

  AvailabilityWindow({
    required this.start,
    required this.end,
  });

  factory AvailabilityWindow.fromJson(Map<String, dynamic> json) {
    return AvailabilityWindow(
      start: json['start'] ?? '',
      end: json['end'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
    };
  }

  String get formattedWindow => '$start - $end';
}

class DeliveryOptionsResponse {
  final bool success;
  final List<DeliveryOptionModel> deliveryOptions;
  final bool amazonDeliveryEnabled;
  final int? branchId;
  final double? orderAmount;
  final String? message;

  DeliveryOptionsResponse({
    required this.success,
    required this.deliveryOptions,
    required this.amazonDeliveryEnabled,
    this.branchId,
    this.orderAmount,
    this.message,
  });

  factory DeliveryOptionsResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryOptionsResponse(
      success: json['success'] ?? false,
      deliveryOptions: json['delivery_options'] != null
          ? (json['delivery_options'] as List)
              .map((option) => DeliveryOptionModel.fromJson(option))
              .toList()
          : [],
      amazonDeliveryEnabled: json['amazon_delivery_enabled'] ?? false,
      branchId: json['branch_id'],
      orderAmount: json['order_amount']?.toDouble(),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'delivery_options': deliveryOptions.map((option) => option.toJson()).toList(),
      'amazon_delivery_enabled': amazonDeliveryEnabled,
      'branch_id': branchId,
      'order_amount': orderAmount,
      'message': message,
    };
  }

  bool get hasDeliveryOptions => deliveryOptions.isNotEmpty;
  bool get hasAvailableOptions => deliveryOptions.any((option) => option.available);

  List<DeliveryOptionModel> get availableOptions =>
      deliveryOptions.where((option) => option.available).toList();

  DeliveryOptionModel? get fastDeliveryOption {
    try {
      return deliveryOptions.firstWhere((option) => option.isFastDelivery);
    } catch (e) {
      return null;
    }
  }

  DeliveryOptionModel? get standardDeliveryOption {
    try {
      return deliveryOptions.firstWhere((option) => option.isStandardDelivery);
    } catch (e) {
      return null;
    }
  }

  DeliveryOptionModel? get freeDeliveryOption {
    try {
      return deliveryOptions.firstWhere((option) => option.isFreeDelivery);
    } catch (e) {
      return null;
    }
  }
}
