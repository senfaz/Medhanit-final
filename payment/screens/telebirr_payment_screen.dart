import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grocery/common/widgets/custom_asset_image_widget.dart';
import 'package:flutter_grocery/common/widgets/custom_button_widget.dart';
import 'package:flutter_grocery/common/providers/cart_provider.dart';
import 'package:flutter_grocery/features/order/providers/order_provider.dart';
import 'package:flutter_grocery/helper/custom_snackbar_helper.dart';
import 'package:flutter_grocery/helper/route_helper.dart';
import 'package:flutter_grocery/localization/language_constraints.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/utill/images.dart';
import 'package:flutter_grocery/utill/styles.dart';
import 'package:flutter_grocery/services/telebirr_service.dart';
import 'package:provider/provider.dart';

class TelebirrPaymentScreen extends StatefulWidget {
  final String? orderId;
  final double amount;

  const TelebirrPaymentScreen({
    Key? key,
    required this.amount,
    this.orderId,
  }) : super(key: key);

  @override
  State<TelebirrPaymentScreen> createState() => _TelebirrPaymentScreenState();
}

class _TelebirrPaymentScreenState extends State<TelebirrPaymentScreen> {
  bool _isLoading = false;
  bool _paymentProcessing = false;
  String _statusMessage = 'Ready to process payment';
  Timer? _paymentMonitorTimer;
  int _monitoringAttempts = 0;
  static const int _maxMonitoringAttempts = 30; // 5 minutes with 10-second intervals

  @override
  void initState() {
    super.initState();
    print('TelebirrPaymentScreen initialized with amount: ${widget.amount}');
  }

  @override
  void dispose() {
    _paymentMonitorTimer?.cancel();
    super.dispose();
  }

  Future<void> _processNativePayment() async {
    try {
      setState(() {
        _isLoading = true;
        _paymentProcessing = true;
        _statusMessage = 'Initializing Telebirr payment...';
      });

      print('Starting C2B payment process...');
      print('Amount: ${widget.amount}');

      // Generate order ID for this payment attempt
      final orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
      print('Generated Order ID: $orderId');

      // Use our implemented TelebirrService for real C2B integration
      final paymentResult = await TelebirrService.processC2BPayment(
        amount: widget.amount,
        orderId: orderId,
        title: 'Grocery Order Payment',
        description: 'Payment for grocery order #$orderId',
      );

      print('Payment result: ${paymentResult.success}');
      print('Payment message: ${paymentResult.message}');

      if (paymentResult.success) {
        setState(() {
          _statusMessage = 'Payment launched successfully. Complete payment in Telebirr app...';
          _isLoading = false;
        });

        // Start monitoring payment status
        _startPaymentMonitoring(orderId);
      } else {
        throw TelebirrException(paymentResult.message);
      }
    } catch (e) {
      print('Payment error: $e');
      setState(() {
        _statusMessage = 'Payment failed: ${e.toString()}';
        _isLoading = false;
        _paymentProcessing = false;
      });

      // Show error for 3 seconds then return to previous screen
      await Future.delayed(Duration(seconds: 3));
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _startPaymentMonitoring(String orderId) {
    print('Starting payment monitoring for order: $orderId');
    _monitoringAttempts = 0;
    
    _paymentMonitorTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      _monitoringAttempts++;
      print('Payment monitoring attempt: $_monitoringAttempts/$_maxMonitoringAttempts');
      
      setState(() {
        _statusMessage = 'Checking payment status... (Attempt $_monitoringAttempts/$_maxMonitoringAttempts)';
      });

      if (_monitoringAttempts >= _maxMonitoringAttempts) {
        print('Payment monitoring timeout reached');
        timer.cancel();
        setState(() {
          _statusMessage = 'Payment timeout. Please check your Telebirr app or try again.';
          _paymentProcessing = false;
        });
        return;
      }

      try {
        // Query payment status
        final status = await TelebirrService.queryOrderStatus(orderId);

        if (status.isSuccess) {
          print('Payment confirmed successful!');
          timer.cancel();
          await _handlePaymentSuccess(orderId);
        } else if (status.isFailed) {
          print('Payment confirmed failed');
          timer.cancel();
          setState(() {
            _statusMessage = 'Payment failed. Please try again.';
            _paymentProcessing = false;
          });
        }
        // If pending, continue monitoring
      } catch (e) {
        print('Error checking payment status: $e');
        // Continue monitoring on error
      }
    });
  }

  Future<void> _handlePaymentSuccess(String orderId) async {
    print('Handling payment success for order: $orderId');
    setState(() {
      _statusMessage = 'Payment successful! Creating order...';
      _paymentProcessing = false;
    });

    try {
      // Get order data from route arguments
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final orderData = args?['orderData'];
      
      if (orderData != null) {
        print('Creating order with data: ${orderData.toString()}');
        
        // Create the order after successful payment
        await Provider.of<OrderProvider>(context, listen: false).placeOrder(orderData, _onOrderPlaced);
        
        setState(() {
          _statusMessage = 'Order created successfully!';
        });
      } else {
        print('No order data found in arguments');
        setState(() {
          _statusMessage = 'Payment successful but order data missing!';
        });
      }
    } catch (e) {
      print('Error creating order: $e');
      setState(() {
        _statusMessage = 'Payment successful but order creation failed: ${e.toString()}';
      });
    }

    if (mounted) {
      showCustomSnackBarHelper('Payment completed successfully!');
      
      // Clear cart on successful payment
      Provider.of<CartProvider>(context, listen: false).clearCartList();
      
      // Navigate to success screen
      await Future.delayed(Duration(seconds: 2));
      Navigator.pushReplacementNamed(
        context, 
        '${RouteHelper.orderSuccessful}/$orderId/success'
      );
    }
  }

  void _onOrderPlaced(bool isSuccess, String message, String orderID, int addressID) {
    print('Order placement callback: success=$isSuccess, message=$message, orderID=$orderID');
    if (isSuccess) {
      print('Order created successfully with ID: $orderID');
    } else {
      print('Order creation failed: $message');
    }
  }

  void _cancelPayment() {
    print('Payment cancelled by user');
    _paymentMonitorTimer?.cancel();
    setState(() {
      _paymentProcessing = false;
      _statusMessage = 'Payment cancelled';
    });
    
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        title: Text(getTranslated('telebirr_payment', context) ?? 'Telebirr Payment'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        leading: _paymentProcessing
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(
            children: [
              // Payment Amount Display
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      getTranslated('payment_amount', context) ?? 'Payment Amount',
                      style: poppinsRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    SizedBox(height: Dimensions.paddingSizeSmall),
                    Text(
                      '${widget.amount.toStringAsFixed(2)} ETB',
                      style: poppinsBold.copyWith(
                        fontSize: Dimensions.fontSizeExtraLarge,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: Dimensions.paddingSizeLarge),
              
              // Telebirr Logo
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
                  border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
                  child: CustomAssetImageWidget(
                    Images.telebirrPayment,
                    height: 80,
                    width: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              
              SizedBox(height: Dimensions.paddingSizeLarge),
              
              // Payment Status
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_isLoading || _paymentProcessing)
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    
                    SizedBox(height: Dimensions.paddingSizeDefault),
                    
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: poppinsRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    
                    if (_paymentProcessing) ...[
                      SizedBox(height: Dimensions.paddingSizeDefault),
                      Text(
                        'Payment is being processed. Please wait.',
                        style: poppinsRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              Spacer(),
              
              // Action Buttons
              if (!_paymentProcessing && !_isLoading) ...[
                CustomButtonWidget(
                  buttonText: getTranslated('pay_with_telebirr', context) ?? 'Pay with Telebirr',
                  onPressed: _processNativePayment,
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                SizedBox(height: Dimensions.paddingSizeDefault),
                CustomButtonWidget(
                  buttonText: getTranslated('cancel', context) ?? 'Cancel',
                  onPressed: () => Navigator.pop(context),
                  backgroundColor: Colors.grey,
                ),
              ] else if (_paymentProcessing) ...[
                CustomButtonWidget(
                  buttonText: getTranslated('cancel_payment', context) ?? 'Cancel Payment',
                  onPressed: _cancelPayment,
                  backgroundColor: Colors.red,
                ),
              ],
              
              SizedBox(height: Dimensions.paddingSizeDefault),
            ],
          ),
        ),
      ),
    );
  }
}
