import 'dart:convert' as convert;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grocery/common/models/cart_model.dart';
import 'package:flutter_grocery/common/models/config_model.dart';
import 'package:flutter_grocery/common/models/place_order_model.dart';
import 'package:flutter_grocery/common/providers/cart_provider.dart';
import 'package:flutter_grocery/common/widgets/custom_loader_widget.dart';
import 'package:flutter_grocery/common/widgets/custom_asset_image_widget.dart';
import 'package:flutter_grocery/common/widgets/custom_button_widget.dart';
import 'package:flutter_grocery/features/address/providers/location_provider.dart';
import 'package:flutter_grocery/features/checkout/domain/models/check_out_model.dart';
import 'package:flutter_grocery/features/checkout/widgets/offline_payment_widget.dart';
import 'package:flutter_grocery/features/checkout/widgets/payment_button_widget.dart';
import 'package:flutter_grocery/features/coupon/providers/coupon_provider.dart';
import 'package:flutter_grocery/features/order/domain/models/offline_payment_model.dart';
import 'package:flutter_grocery/features/order/providers/image_note_provider.dart';
import 'package:flutter_grocery/features/order/providers/order_provider.dart';
import 'package:flutter_grocery/features/order/widgets/bring_change_input_widget.dart';
import 'package:flutter_grocery/features/wallet_and_loyalty/widgets/add_fund_dialogue_widget.dart';
import 'package:flutter_grocery/helper/cart_helper.dart';
import 'package:flutter_grocery/helper/checkout_helper.dart';
import 'package:flutter_grocery/helper/custom_snackbar_helper.dart';
import 'package:flutter_grocery/helper/price_converter_helper.dart';
import 'package:flutter_grocery/helper/responsive_helper.dart';
import 'package:flutter_grocery/helper/route_helper.dart';
import 'package:flutter_grocery/localization/language_constraints.dart';
import 'package:flutter_grocery/features/auth/providers/auth_provider.dart';
import 'package:flutter_grocery/features/profile/providers/profile_provider.dart';
import 'package:flutter_grocery/features/splash/providers/splash_provider.dart';
import 'package:flutter_grocery/main.dart';
import 'package:flutter_grocery/utill/app_constants.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/utill/images.dart';
import 'package:flutter_grocery/utill/styles.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;

class PaymentMethodBottomSheetWidget extends StatefulWidget {
  final double totalPrice;
  final double? weight;
  final String? orderId;
  final bool isAlreadyPartialApplied;
  const PaymentMethodBottomSheetWidget({super.key, required this.totalPrice, this.weight, this.orderId,  this.isAlreadyPartialApplied = false});

  @override
  State<PaymentMethodBottomSheetWidget> createState() => _PaymentMethodBottomSheetWidgetState();
}

class _PaymentMethodBottomSheetWidgetState extends State<PaymentMethodBottomSheetWidget> {

  String partialPaymentCombinator = "all";
  final JustTheController? toolTip = JustTheController();
  TextEditingController? _bringAmountController;
  List<PaymentMethod> paymentList = [];
  int? _paymentMethodIndex;
  double? _partialAmount;
  PaymentMethod? _paymentMethod;
  OfflinePaymentModel? _selectedOfflineMethod;
  List<Map<String, String>>? _selectedOfflineValue;


  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ProfileProvider profileProvider  = Provider.of<ProfileProvider>(context, listen: false);
    // Listen to SplashProvider so UI rebuilds when config refreshes
    final SplashProvider splashProvider = Provider.of<SplashProvider>(context);
    final ConfigModel? configModel = splashProvider.configModel;

    // If config is not yet available, show a lightweight loader inside the sheet
    if (configModel == null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(child: SizedBox(height: 36, width: 36, child: CircularProgressIndicator(color: Theme.of(context).primaryColor))),
      );
    }

    // Note: Telebirr visibility no longer depends on backend toggle (reverted behavior)

    return SingleChildScrollView(
      child: Center(child: SizedBox(width: 550, child: Column(mainAxisSize: MainAxisSize.min, children: [
        SafeArea(
          bottom: !kIsWeb && Platform.isAndroid,
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
            width: 550,
            margin: const EdgeInsets.only(top: kIsWeb ? 0 : 30),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: ResponsiveHelper.isMobile() ? const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSizeLarge))
                  :  BorderRadius.all(Radius.circular(Dimensions.radiusSizeDefault)),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: Dimensions.paddingSizeExtraSmall,
            ),
            child: SafeArea(
              child: Consumer<OrderProvider>(
                  builder: (ctx, orderProvider, _) {

                    double bottomPadding = MediaQuery.of(context).padding.bottom;

                    double walletBalance = profileProvider.userInfoModel?.walletBalance ?? 0;
                    bool isPartialPayment = widget.totalPrice > walletBalance;
                    bool isWalletSelectAndNotPartial = _paymentMethodIndex == 0 && !isPartialPayment;

                    bool hideCOD = isWalletSelectAndNotPartial
                        || (_partialAmount !=null && (partialPaymentCombinator == "digital_payment" || partialPaymentCombinator == "offline_payment"));

                    bool hideDigital = isWalletSelectAndNotPartial
                        || (_partialAmount !=null && (partialPaymentCombinator == "cod" || partialPaymentCombinator == "offline_payment"));

                    bool hideOffline = isWalletSelectAndNotPartial
                        || (_partialAmount !=null && (partialPaymentCombinator == "cod" || partialPaymentCombinator == "digital_payment"));


                    return Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [

                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      !ResponsiveHelper.isDesktop(context) ? Align(
                        alignment: Alignment.center,
                        child: Container(
                          height: 4, width: 35,
                          decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
                        ),
                      ) : const SizedBox(),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(Icons.clear, size: 20,),
                          ),
                        ),
                      ),

                      Text(getTranslated('choose_payment_method', context), style: poppinsSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Text(getTranslated('total_bill', context), style: poppinsRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7)
                      )),
                      Text(PriceConverterHelper.convertPrice(context,widget.totalPrice), style: poppinsBold.copyWith(fontSize: Dimensions.fontSizeLarge)),

                      const SizedBox(height:  Dimensions.paddingSizeDefault),

                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height * 0.2,
                          maxHeight: MediaQuery.of(context).size.height * 0.5,
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge * (ResponsiveHelper.isDesktop(context) ? 2 : 1),),
                            child: Column(children: [

                              configModel.walletStatus! && authProvider.isLoggedIn() && walletBalance > 0 && !widget.isAlreadyPartialApplied ? PaymentButtonWidget(
                                icon: Images.walletIcon,
                                isWallet: true,
                                title: getTranslated('pay_via_wallet', context),
                                isSelected: _paymentMethodIndex == 0,
                                hidePaymentMethod: false ,
                                walletBalance: walletBalance,
                                totalPrice: widget.totalPrice,
                                partialAmount: _partialAmount,
                                chooseAnyPayment:  _paymentMethodIndex != null || _paymentMethod != null,
                                callBack: ({int? paymentMethodIndex, double? partialAmount}){
                                  setState(() {
                                    _paymentMethodIndex = paymentMethodIndex;
                                    _paymentMethod = null; // Clear other payment method selection
                                    _partialAmount = partialAmount;
                                    _selectedOfflineMethod = null; // Clear offline selection
                                    _selectedOfflineValue = null; // Clear offline values
                                    _bringAmountController?.text = "";
                                    orderProvider.updateBringChangeInputOptionStatus(false, isUpdate: false);
                                    orderProvider.setBringChangeAmount();
                                  });
                                },
                              ) : const SizedBox(),

                              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                              configModel.cashOnDelivery! ? PaymentButtonWidget(
                                icon: Images.cashOnDelivery,
                                title: getTranslated('cash_on_delivery', context),
                                walletBalance: walletBalance,
                                hidePaymentMethod: hideCOD,
                                totalPrice: widget.totalPrice,
                                isSelected: _paymentMethodIndex == 1,
                                chooseAnyPayment: _paymentMethodIndex != null || _paymentMethod != null,
                                callBack: ({int? paymentMethodIndex, double? partialAmount}){
                                  setState(() {
                                    _paymentMethodIndex = paymentMethodIndex;
                                    _paymentMethod = null; // Clear other payment method selection
                                    _partialAmount = null; // Clear partial amount
                                    _selectedOfflineValue = null;
                                    _selectedOfflineMethod = null;
                                    _bringAmountController?.text = "";
                                    orderProvider.updateBringChangeInputOptionStatus(false, isUpdate: false);
                                    orderProvider.setBringChangeAmount();
                                  });
                                },
                              ) : const SizedBox(),

                              if(configModel.cashOnDelivery! )
                                BringChangeInputWidget(amountController: _bringAmountController, hidePaymentMethod: hideCOD,),

                              if(_isTelebirrEnabled(configModel))
                                _TelebirrPaymentWidget(
                                    isSelected: _paymentMethodIndex == 2,
                                    chooseAnyPayment: _paymentMethodIndex != null || _paymentMethod != null,
                                    callBack: ({int? paymentMethodIndex, double? partialAmount}){
                                      setState(() {
                                        _paymentMethodIndex = 2; // Telebirr is always index 2
                                        _paymentMethod = null; // Clear other payment method selection
                                        _partialAmount = null; // Clear partial amount
                                        _selectedOfflineValue = null;
                                        _selectedOfflineMethod = null;
                                        _bringAmountController?.text = "";
                                        orderProvider.updateBringChangeInputOptionStatus(false, isUpdate: false);
                                        orderProvider.setBringChangeAmount();
                                      });
                                    },
                                  ),

                              if(configModel.isOfflinePayment == true && splashProvider.offlinePaymentModelList != null)
                                ...splashProvider.offlinePaymentModelList!.map((offlineMethod) {
                                  if(offlineMethod == null) return const SizedBox();
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                                    child: InkWell(
                                      onTap: hideOffline ? null : () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext dialogContext) {
                                            return AlertDialog(
                                              title: Text(offlineMethod.methodName ?? 'Bank Transfer'),
                                              content: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Make your transfer to:',
                                                      style: poppinsSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                                                    ),
                                                    const SizedBox(height: Dimensions.paddingSizeDefault),
                                                    
                                                    // Display bank account details with clean formatting
                                                    if(offlineMethod.methodFields != null)
                                                      ...offlineMethod.methodFields!.map((field) {
                                                        return Padding(
                                                          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                                                          child: RichText(
                                                            text: TextSpan(
                                                              style: poppinsRegular.copyWith(
                                                                fontSize: Dimensions.fontSizeDefault,
                                                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                                              ),
                                                              children: [
                                                                TextSpan(
                                                                  text: '• ${field.fieldName}: ',
                                                                  style: poppinsMedium,
                                                                ),
                                                                TextSpan(
                                                                  text: field.fieldData ?? '',
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                    
                                                    const SizedBox(height: Dimensions.paddingSizeDefault),
                                                    
                                                    // Payment instructions with professional text
                                                    Container(
                                                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                                        borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
                                                      ),
                                                      child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Icon(Icons.info_outline, size: 20, color: Theme.of(context).primaryColor),
                                                          const SizedBox(width: Dimensions.paddingSizeSmall),
                                                          Expanded(
                                                            child: Text(
                                                              'Make sure the name on your bank account matches the name on your Medhanit Online accoun.',
                                                              style: poppinsRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                                  child: Text(getTranslated('cancel', context)),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.of(dialogContext).pop();
                                                    setState(() {
                                                      _paymentMethodIndex = null;
                                                      _paymentMethod = PaymentMethod(
                                                        getWay: 'offline_payment',
                                                        getWayTitle: offlineMethod.methodName,
                                                        type: 'offline_payment',
                                                      );
                                                      _partialAmount = null;
                                                      _selectedOfflineMethod = offlineMethod;
                                                      _selectedOfflineValue = null; // Empty - no customer input needed
                                                      _bringAmountController?.text = "";
                                                      orderProvider.updateBringChangeInputOptionStatus(false, isUpdate: false);
                                                      orderProvider.setBringChangeAmount();
                                                    });
                                                  },
                                                  child: Text(getTranslated('confirm', context)),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Opacity(
                                        opacity: hideOffline ? 0.4 : 1,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: Dimensions.paddingSizeDefault,
                                            horizontal: Dimensions.paddingSizeSmall
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSizeDefault)),
                                            border: Border.all(
                                              color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                                              width: 0.3
                                            ),
                                          ),
                                          child: Row(children: [
                                            const SizedBox(width: Dimensions.paddingSizeSmall),
                                            Icon(Icons.account_balance, size: 20, color: Theme.of(context).primaryColor),
                                            const SizedBox(width: Dimensions.paddingSizeSmall),
                                            Expanded(
                                              child: Text(
                                                offlineMethod.methodName ?? 'Offline Payment',
                                                style: poppinsRegular.copyWith(
                                                  overflow: TextOverflow.ellipsis,
                                                  fontSize: Dimensions.fontSizeDefault,
                                                )
                                              ),
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.transparent,
                                                border: Border.all(
                                                  color: _selectedOfflineMethod?.id == offlineMethod.id
                                                      ? Theme.of(context).primaryColor
                                                      : Theme.of(context).disabledColor,
                                                  width: 2
                                                )
                                              ),
                                              padding: const EdgeInsets.all(2),
                                              child: Icon(
                                                Icons.circle,
                                                color: _selectedOfflineMethod?.id == offlineMethod.id
                                                    ? Theme.of(context).primaryColor
                                                    : Colors.transparent,
                                                size: 10
                                              ),
                                            ),
                                            const SizedBox(width: Dimensions.paddingSizeSmall),
                                          ]),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),

                              const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                            ]),
                          ),
                        ),
                      ),


                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge * (ResponsiveHelper.isDesktop(context) ? 2 : 1),),
                        child: orderProvider.isLoading   ? CustomLoaderWidget(color: Theme.of(context).primaryColor) : CustomButtonWidget(
                          buttonText: getTranslated('proceed', context),
                          onPressed: _paymentMethodIndex == null
                              && _paymentMethod == null
                              || (_paymentMethod != null && _paymentMethod?.type == 'offline' && _selectedOfflineMethod == null)
                              ? null : () {

                            if(_paymentMethod?.type == 'offline' && _selectedOfflineValue == null || (widget.orderId !=null && widget.orderId != "null" && orderProvider.selectedOfflineValue != null)){

                              if(widget.orderId !=null && widget.orderId != "null" && _selectedOfflineMethod != null){

                                ResponsiveHelper().showDialogOrBottomSheet(
                                  context, isScrollControlled: true,
                                  OfflinePaymentWidget(
                                    totalAmount: widget.totalPrice,
                                    selectedOfflineMethod: _selectedOfflineMethod,
                                    partialAmount: isPartialPayment && _partialAmount != null ? (widget.totalPrice - walletBalance) : widget.totalPrice,
                                    orderId: widget.orderId,
                                  ),
                                );
                              }else{
                                _placeOfflineOrder(orderProvider: orderProvider, weight: widget.weight, context: context);
                              }

                            }else{
                              if(_paymentMethodIndex == 1){
                                orderProvider.setBringChangeAmount(amountController: _bringAmountController);
                              }
                              orderProvider.savePaymentMethod(
                                index: _paymentMethodIndex ?? 0,
                                method: _paymentMethod,
                                partialAmount: _partialAmount,
                                selectedOfflineValue: _selectedOfflineValue != null ? [{'method': _selectedOfflineValue.toString()}] : null,
                                selectedOfflineMethod: _selectedOfflineMethod
                              );

                              /// Switch payment method for existing order
                              if(widget.orderId !=null && widget.orderId != "null"){
                                String paymentMethod = orderProvider.selectedOfflineValue != null
                                    ? 'offline_payment' : orderProvider.selectedPaymentMethod!.getWay!;

                                if(paymentMethod == 'wallet_payment' || paymentMethod == 'cash_on_delivery' || paymentMethod == 'offline_payment'){
                                  orderProvider.switchPaymentMethod(
                                    orderId: widget.orderId!,
                                    paymentMethod:  orderProvider.selectedPaymentMethod!.getWay!,
                                    isPartial: _partialAmount !=null && _partialAmount! > 0 ? 1 : 0,
                                    bringChangeAmount: double.tryParse(_bringAmountController?.text ?? "0"),
                                  );
                                }else{
                                  _switchOfflineToDigital(orderAmount: widget.totalPrice, paymentMethod: paymentMethod, partialAmount: _partialAmount, orderId: widget.orderId ?? "");
                                }

                              }else{
                                Navigator.of(context).pop();
                              }

                            }
                          },
                        ),
                      ),

                      SizedBox(height: bottomPadding> 0 ? 0 : Dimensions.paddingSizeDefault,)

                    ]);
                  }
              ),
            ),
          ),
        ),
      ]))),
    );
  }

  bool _isTelebirrEnabled(ConfigModel configModel) {
    // Enhanced debugging for Telebirr visibility issue
    print('=== TELEBIRR DEBUG START ===');
    print('DEBUG: configModel.activePaymentMethodList: ${configModel.activePaymentMethodList?.map((m) => '${m.getWay}/${m.getWayTitle}/${m.type}').join(', ') ?? 'NULL'}');
    
    // Use CheckOutHelper to get the processed payment list that includes force-added Telebirr
    final processedPaymentList = CheckOutHelper.getActivePaymentList(configModel: configModel);
    print('DEBUG: processedPaymentList length: ${processedPaymentList.length}');
    print('DEBUG: processedPaymentList details: ${processedPaymentList.map((m) => 'way=${m.getWay}, title=${m.getWayTitle}, type=${m.type}').join(' | ')}');

    // Check if Telebirr exists in the processed list
    final telebirrMethods = processedPaymentList
        .where((method) {
          final way = method.getWay?.toLowerCase() ?? '';
          final title = method.getWayTitle?.toLowerCase() ?? '';
          final type = method.type?.toLowerCase() ?? '';
          print('DEBUG: Checking method - way: "$way", title: "$title", type: "$type"');
          return way.contains('telebirr') || title.contains('telebirr') || type == 'telebirr';
        });

    final telebirrFound = telebirrMethods.isNotEmpty;
    print('DEBUG: Telebirr methods found: ${telebirrMethods.length}');
    print('DEBUG: Telebirr found in processed list: $telebirrFound');
    print('=== TELEBIRR DEBUG END ===');

    return telebirrFound;
  }

  @override
  void initState() {
    super.initState();

    _bringAmountController = TextEditingController();

    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);
    splashProvider.getOfflinePaymentMethod(false);

    // Use default until config is available; build() guards on null
    partialPaymentCombinator = splashProvider.configModel?.partialPaymentCombineWith?.toLowerCase() ?? "all";

    _initializeData();
  }


  _initializeData (){
    final OrderProvider orderProvider =  Provider.of<OrderProvider>(context, listen: false);
    _paymentMethodIndex = null;
    _partialAmount = null;
    _paymentMethod = null;
    _selectedOfflineMethod = null;
    _selectedOfflineValue = null;

    orderProvider.setBringChangeAmount(isUpdate: false);
    orderProvider.updateBringChangeInputOptionStatus(false, isUpdate: false);
  }

  _placeOfflineOrder({required OrderProvider orderProvider, required  double? weight, required BuildContext context}){

    CheckOutModel? checkOutData = orderProvider.getCheckOutData;
    final bool isSelfPickup = CheckOutHelper.isSelfPickup(orderType: checkOutData?.orderType);
    final configModel = Provider.of<SplashProvider>(context, listen: false).configModel;
    List<CartModel> cartList = Provider.of<CartProvider>(context, listen: false).cartList;
    List<Cart> carts = [];
    
    for (int index = 0; index < cartList.length; index++) {
      CartModel cart = cartList[index];
      
      carts.add(Cart(
        productId: cart.product!.id, 
        price: cart.product!.price, 
        discountAmount: PriceConverterHelper.convertWithDiscount(cart.product!.price, cart.product!.discount, cart.product!.discountType)!,
        variant: '', 
        variation: [Variation(type: cart.product!.variations != null ? cart.product!.variations![0].type : '')],
        quantity: cart.quantity, 
        taxAmount: cart.product!.tax,
      ));
    }

    PlaceOrderModel placeOrderBody = PlaceOrderModel(
      cart: carts, 
      orderType: checkOutData?.orderType,
      couponCode: checkOutData?.couponCode,
      orderNote: checkOutData?.orderNote,
      couponDiscountAmount: Provider.of<CouponProvider>(context, listen: false).discount,
      couponDiscountTitle: '',
      deliveryAddressId: !isSelfPickup
          ? Provider.of<LocationProvider>(context, listen: false).addressList![orderProvider.addressIndex].id
          : 0,
      deliveryDate: orderProvider.getDateList()[orderProvider.selectDateSlot],
      timeSlotId: orderProvider.timeSlots![orderProvider.selectTimeSlot].id,
      orderAmount: (checkOutData?.amount ?? 0) + (orderProvider.deliveryCharge ?? 0) + (weight ?? 0),
      distance: isSelfPickup ? 0 : orderProvider.distance,
      branchId: configModel!.branches![orderProvider.branchIndex].id,
      selectedDeliveryArea: orderProvider.selectedAreaID,
      paymentMethod: _paymentMethod?.getWay ?? 'cash_on_delivery',
      isPartial: _partialAmount != null && _partialAmount! > 0 ? '1' : '0',
      bringChangeAmount: orderProvider.bringChangeAmount,
      // Include Amazon delivery option data if selected
      deliveryOptionType: orderProvider.selectedDeliveryOption?.type,
      deliveryOptionCharge: orderProvider.selectedDeliveryOption?.charge,
      deliveryOptionTitle: orderProvider.selectedDeliveryOption?.title,
      deliveryOptionDescription: orderProvider.selectedDeliveryOption?.description,
      estimatedDeliveryTime: orderProvider.selectedDeliveryOption?.estimatedDeliveryTime?.toString(),
    );
    orderProvider.placeOrder(placeOrderBody, _callback);
  }

  void _callback(bool isSuccess, String message, String orderID, ) async {
    if (isSuccess) {
      Provider.of<OrderProvider>(Get.context!, listen: false).stopLoader();
      Provider.of<CartProvider>(Get.context!, listen: false).clearCartList();
      double walletBalance =  Provider.of<ProfileProvider>(Get.context!, listen: false).userInfoModel?.walletBalance ?? 0;
      bool isPartialPayment = widget.totalPrice > walletBalance;
      Navigator.of(context).pop();

      ResponsiveHelper().showDialogOrBottomSheet(
        context, isScrollControlled: true, isDismissible: false, enableDrag: false,
        OfflinePaymentWidget(
          totalAmount: widget.totalPrice,
          selectedOfflineMethod: _selectedOfflineMethod,
          partialAmount: isPartialPayment && _partialAmount != null ? (widget.totalPrice - walletBalance) : widget.totalPrice,
          orderId: orderID,
          fromCheckout: true,
        ),
      );
      showFlutterCustomToaster(
        "now_pay_you_bill_using_the_payment_method",
        toasterTitle: "your_order_has_placed_successfully",
        context: context, type: ToasterMessageType.success,
        duration: 4
      );
    } else {
      showFlutterCustomToaster(message.replaceAll("_", " "), context: context);
    }
  }

  _switchOfflineToDigital({required String paymentMethod, required double orderAmount, double? partialAmount, required  String orderId}){

    String? hostname = html.window.location.hostname;
    String protocol = html.window.location.protocol;
    String port = html.window.location.port;

    final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ProfileProvider profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    String url = "customer_id=${profileProvider.userInfoModel?.id ?? authProvider.getGuestId()}&&is_guest=${authProvider.getGuestId() != null ? '1' :'0'}"
        "&&callback=${AppConstants.baseUrl}${RouteHelper.orderDetails}&&order_amount=$orderAmount";

    String webUrl = "customer_id=${profileProvider.userInfoModel?.id ?? authProvider.getGuestId()}&&is_guest=${authProvider.getGuestId() != null ? '1' :'0'}"
        "&&callback=$protocol//$hostname${kDebugMode ? ':$port' : ''}${RouteHelper.orderDetails}&&order_amount=$orderAmount&&status=";

    String tokenUrl = convert.base64Encode(convert.utf8.encode(ResponsiveHelper.isWeb() ? webUrl : url));
    String selectedUrl = '${AppConstants.baseUrl}/payment-mobile?token=$tokenUrl&&payment_method=$paymentMethod&&payment_platform=${kIsWeb ? 'web' : 'app'}&&is_partial=${partialAmount == null ? '0' : '1'}&&order_id=$orderId&&switch_offline_to_digital=1';

    if(ResponsiveHelper.isWeb()){
      html.window.open(selectedUrl,"_self");

    }else{
      Navigator.pushReplacementNamed(Get.context!, RouteHelper.getPaymentRoute(
        url: selectedUrl,
        id: orderId
      ));

    }
  }
}

class _TelebirrPaymentWidget extends StatelessWidget {
  final bool isSelected;
  final bool chooseAnyPayment;
  final Function({int? paymentMethodIndex, double? partialAmount}) callBack;

  const _TelebirrPaymentWidget({Key? key, required this.isSelected, required this.chooseAnyPayment, required this.callBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: InkWell(
        onTap: () {
          callBack(paymentMethodIndex: 2); // Pass correct index for Telebirr
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault, horizontal: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSizeDefault)),
            border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.3), width: 0.3),
          ),
          child: Row(children: [
            const SizedBox(width: Dimensions.paddingSizeSmall),
            CustomAssetImageWidget(Images.telebirrPayment, height: 20, width: 20),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Text('Telebirr', style: poppinsRegular.copyWith(
                overflow: TextOverflow.ellipsis, fontSize: Dimensions.fontSizeDefault,
              )),
            ),
            Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Colors.transparent,
                  border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor, width: 2)
              ),
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.circle, color: isSelected ? Theme.of(context).primaryColor : Colors.transparent, size: 10),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
          ]),
        ),
      ),
    );
  }
}
