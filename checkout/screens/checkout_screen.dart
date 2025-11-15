import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grocery/common/enums/footer_type_enum.dart';
import 'package:flutter_grocery/common/models/cart_model.dart';
import 'package:flutter_grocery/common/models/config_model.dart';
import 'package:flutter_grocery/common/models/delivery_info_model.dart';
import 'package:flutter_grocery/common/providers/localization_provider.dart';
import 'package:flutter_grocery/common/widgets/custom_app_bar_widget.dart';
import 'package:flutter_grocery/common/widgets/custom_loader_widget.dart';
import 'package:flutter_grocery/common/widgets/custom_shadow_widget.dart';
import 'package:flutter_grocery/common/widgets/custom_single_child_list_widget.dart';
import 'package:flutter_grocery/common/widgets/footer_web_widget.dart';
import 'package:flutter_grocery/common/widgets/not_login_widget.dart';
import 'package:flutter_grocery/common/widgets/web_app_bar_widget.dart';
import 'package:flutter_grocery/features/address/domain/models/address_model.dart';
import 'package:flutter_grocery/features/address/providers/location_provider.dart';
import 'package:flutter_grocery/features/auth/providers/auth_provider.dart';
import 'package:flutter_grocery/features/checkout/domain/models/check_out_model.dart';
import 'package:flutter_grocery/features/checkout/widgets/delivery_address_widget.dart';
import 'package:flutter_grocery/features/checkout/widgets/delivery_options_widget.dart';
import 'package:flutter_grocery/features/checkout/widgets/details_widget.dart';
import 'package:flutter_grocery/features/checkout/widgets/place_order_button_widget.dart';
import 'package:flutter_grocery/features/order/enums/delivery_charge_type.dart';
import 'package:flutter_grocery/features/order/providers/image_note_provider.dart';
import 'package:flutter_grocery/features/order/providers/order_provider.dart';
import 'package:flutter_grocery/features/splash/providers/splash_provider.dart';
import 'package:flutter_grocery/helper/checkout_helper.dart';
import 'package:flutter_grocery/helper/date_converter_helper.dart';
import 'package:flutter_grocery/helper/responsive_helper.dart';
import 'package:flutter_grocery/localization/language_constraints.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/utill/styles.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  final double amount;
  final double? discount;
  final String? couponCode;
  final String? orderType;
  final List<CartModel>? cartList;
  final String? freeDeliveryType;
  final double? couponDiscount;
  final double? tax;
  final double? weight;
  final bool iscouponVariation;

  const CheckoutScreen({
    super.key,
    required this.amount,
    required this.orderType,
    this.cartList,
    this.discount,
    this.couponCode,
    this.freeDeliveryType,
    this.couponDiscount,
    this.tax,
    this.weight,
    required this.iscouponVariation,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final FocusNode _noteNode = FocusNode();
  late bool _isLoggedIn;
  late List<PaymentMethod> _activePaymentList;
  final ScrollController scrollController = ScrollController();
  final GlobalKey<DropdownButton2State> dropDownKey = GlobalKey<DropdownButton2State>();
  bool selfPickup = false;

  @override
  void initState() {
    super.initState();
    initLoading();
  }

  void _loadDeliveryOptions() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final splashProvider = Provider.of<SplashProvider>(context, listen: false);
    final configModel = splashProvider.configModel;

    if (configModel != null && configModel.branches != null && configModel.branches!.isNotEmpty) {
      orderProvider.getDeliveryOptions(
        branchId: configModel.branches![orderProvider.branchIndex].id!,
        orderAmount: widget.amount,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDeliveryOptions();
    });

    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);
    final ConfigModel? configModel = splashProvider.configModel;
    final OrderProvider orderProvider = Provider.of<OrderProvider>(context, listen: false);
    double deliveryCharge = orderProvider.deliveryCharge ?? 0;
    double? weightCharge = CheckOutHelper.weightChargeCalculation(widget.weight, splashProvider.deliveryInfoModelList?[orderProvider.branchIndex]);

    return Scaffold(
      key: _scaffoldKey,
      appBar: (ResponsiveHelper.isDesktop(context)? const PreferredSize(preferredSize: Size.fromHeight(120), child: WebAppBarWidget())  : CustomAppBarWidget(title: getTranslated('checkout', context))) as PreferredSizeWidget?,
      body: _isLoggedIn || CheckOutHelper.isGuestCheckout() ? Column(
          children: [
            if(ResponsiveHelper.isDesktop(context))
              const SizedBox(height: Dimensions.paddingSizeLarge),

            Expanded(child: CustomScrollView(controller: scrollController, slivers: [
              SliverToBoxAdapter(child: Center(child: SizedBox(
                width: Dimensions.webScreenWidth,
                child: Consumer<LocationProvider>(
                  builder: (context, locationProvider, child) {
                    return Consumer<OrderProvider>(
                      builder: (context, orderProvider, child) => Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: ResponsiveHelper.isDesktop(context) ? 6 : 1,
                                  child: Column(
                                      children: [
                                        if(!selfPickup)
                                          Column(children: [
                                            const SizedBox(height: Dimensions.paddingSizeSmall),

                                            if(configModel != null && (CheckOutHelper.isKmWiseCharge(configModel: configModel) || CheckOutHelper.getDeliveryChargeType() == DeliveryChargeType.area.name))
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                                                child: Consumer<SplashProvider>(builder: (context, splashProvider, _) {
                                                  return Row(children: [
                                                    Text('${getTranslated('delivery_option', context)}: ', style: poppinsMedium),
                                                    Expanded(child: DropdownButtonHideUnderline(child: DropdownButton2<String>(
                                                      key: dropDownKey,
                                                      isExpanded: true,
                                                      value: orderProvider.orderType,
                                                      items: [
                                                        DropdownMenuItem(value: 'delivery', child: Text(getTranslated('delivery', context), style: poppinsRegular.copyWith(fontSize: Dimensions.fontSizeSmall))),
                                                        DropdownMenuItem(value: 'self_pickup', child: Text(getTranslated('self_pickup', context), style: poppinsRegular.copyWith(fontSize: Dimensions.fontSizeSmall))),
                                                      ],
                                                      onChanged: (String? value) {
                                                        orderProvider.setOrderType(value!);
                                                      },

                                                      buttonStyleData: ButtonStyleData(
                                                        decoration: BoxDecoration(
                                                          border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.5)),
                                                          borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
                                                        ),
                                                        padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                                                      ),

                                                    ))),
                                                  ]);
                                                }),
                                              ),
                                            const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                                          ]),

                                        if(orderProvider.orderType == DeliveryChargeType.area.name) Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                                          child: Consumer<SplashProvider>(builder: (context, splashProvider, _) {
                                            return Row(children: [
                                              Text('${getTranslated('select_your_area', context)}: ', style: poppinsMedium),
                                              Expanded(child: DropdownButtonHideUnderline(child: DropdownButton2<String>(
                                                key: dropDownKey,
                                                isExpanded: true,
                                                value: orderProvider.selectedAreaID == null ? null
                                                    : splashProvider.deliveryInfoModelList?[orderProvider.branchIndex].deliveryChargeByArea!.firstWhere((area) => area.id == orderProvider.selectedAreaID).id.toString(),

                                                items: splashProvider.deliveryInfoModelList?[orderProvider.branchIndex].deliveryChargeByArea?.map((item) {
                                                  return DropdownMenuItem<String>(
                                                    value: item.id.toString(),
                                                    child: Text(item.areaName!, style: poppinsRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                                                  );
                                                }).toList(),
                                                onChanged: (String? value) async {
                                                  orderProvider.setAreaID(areaID: int.parse(value!));
                                                  if(configModel != null) {
                                                    double deliveryCharge = await CheckOutHelper.getDeliveryCharge(
                                                      freeDeliveryType: widget.freeDeliveryType,
                                                      orderAmount: widget.amount,
                                                      distance: orderProvider.distance,
                                                      discount: widget.discount ?? 0,
                                                      configModel: configModel,
                                                    );
                                                    orderProvider.setDeliveryCharge(deliveryCharge);
                                                  }
                                                },

                                                dropdownSearchData: DropdownSearchData(
                                                  searchController: searchController,
                                                  searchInnerWidgetHeight: 50,
                                                  searchInnerWidget: Container(
                                                    height: 50,
                                                    padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall),
                                                    child: TextFormField(
                                                      controller: searchController,
                                                      expands: true,
                                                      maxLines: null,
                                                      decoration: InputDecoration(
                                                        isDense: true,
                                                        contentPadding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                                        hintText: getTranslated('search_zip_area_name', context),
                                                        hintStyle: const TextStyle(fontSize: Dimensions.fontSizeSmall),
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(Dimensions.radiusSizeSmall),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  searchMatchFn: (item, searchValue) {
                                                    return item.value.toString().contains(searchValue);
                                                  },
                                                ),
                                                onMenuStateChange: (isOpen) {
                                                  if (!isOpen) {
                                                    searchController.clear();
                                                  }
                                                },

                                                buttonStyleData: ButtonStyleData(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.5)),
                                                    borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
                                                  ),
                                                  padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                                                ),

                                              ))),
                                            ]);
                                          }),
                                        ),
                                        const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                                        DeliveryAddressWidget(selfPickup: selfPickup),

                                        Consumer<OrderProvider>(
                                          builder: (context, orderProvider, child) {
                                            final configModel = Provider.of<SplashProvider>(context, listen: false).configModel;

                                            // Always show DeliveryOptionsWidget, which will handle its own loading state.
                                            return DeliveryOptionsWidget(
                                              branchId: configModel != null && configModel.branches != null && configModel.branches!.isNotEmpty
                                                  ? configModel.branches![orderProvider.branchIndex].id!
                                                  : 0,
                                              orderAmount: widget.amount,
                                            );
                                          },
                                        ),

                                        // Show DetailsWidget for mobile devices
                                        if(!ResponsiveHelper.isDesktop(context))
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                            child: configModel != null ? DetailsWidget(
                                              orderType: widget.orderType,
                                              payableAmount: widget.amount,
                                              deliveryCharge: deliveryCharge,
                                              iscouponVariation: widget.iscouponVariation,
                                              couponAmount: widget.discount,
                                              freeDeliveryType: widget.freeDeliveryType,
                                              configModel: configModel,
                                              paymentList: _activePaymentList,
                                              noteController: _noteController,
                                            ) : const SizedBox(),
                                          ),

                                      ]),
                                ),

                                if(ResponsiveHelper.isDesktop(context))
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 1170,
                                          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                          child: DetailsWidget(
                                            paymentList: _activePaymentList,
                                            noteController: _noteController,
                                          ),
                                        ),

                                        const SizedBox(height: Dimensions.paddingSizeSmall),

                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                                          child: PlaceOrderButtonWidget(
                                            discount: widget.discount ?? 0.0,
                                            couponDiscount: widget.couponDiscount,
                                            tax: widget.tax,
                                            scrollController: scrollController,
                                            dropdownKey: dropDownKey,
                                            weight: weightCharge,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ]),
                    );
                  },
                ),
              ))),
              const FooterWebWidget(footerType: FooterType.sliver),
            ])),

            if(!ResponsiveHelper.isDesktop(context))
              Center(
                child: PlaceOrderButtonWidget(
                  discount: widget.discount ?? 0.0,
                  couponDiscount: widget.couponDiscount,
                  tax: widget.tax,
                  scrollController: scrollController,
                  dropdownKey: dropDownKey,
                  weight: weightCharge,
                ),
              ),
          ]) : const NotLoggedInWidget(),
    );
  }

  Future<void> initLoading() async {
    final OrderProvider orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);
    final LocationProvider locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);
    final OrderImageNoteProvider orderImageNoteProvider = Provider.of<OrderImageNoteProvider>(context, listen: false);

    orderProvider.clearPrevData();
    orderImageNoteProvider.onPickImage(true, isUpdate: false);
    splashProvider.getOfflinePaymentMethod(true);

    _isLoggedIn = authProvider.isLoggedIn();

    selfPickup = CheckOutHelper.isSelfPickup(orderType: widget.orderType ?? '');
    orderProvider.setOrderType(widget.orderType, notify: false);
    orderProvider.setAreaID(isUpdate: false, isReload: true);
    orderProvider.setDeliveryCharge(null, notify: false);

    orderProvider.setCheckOutData = CheckOutModel(
      orderType: widget.orderType,
      deliveryCharge: 0,
      freeDeliveryType: widget.freeDeliveryType,
      amount: widget.amount,
      placeOrderDiscount: widget.discount,
      couponCode: widget.couponCode,
      orderNote: null,
    );

    if(_isLoggedIn || CheckOutHelper.isGuestCheckout()) {
      orderProvider.setAddressIndex(-1, notify: false);
      orderProvider.initializeTimeSlot();
      if(splashProvider.configModel != null) {
        _activePaymentList = CheckOutHelper.getActivePaymentList(configModel: splashProvider.configModel);
        
        // Fetch Amazon delivery options
        if(splashProvider.configModel!.branches != null && splashProvider.configModel!.branches!.isNotEmpty) {
          int branchId = splashProvider.configModel!.branches![orderProvider.branchIndex].id!;
          await orderProvider.getDeliveryOptions(
            branchId: branchId,
            orderAmount: widget.amount,
          );
        }
      } else {
        _activePaymentList = [];
      }


      await locationProvider.initAddressList();
      AddressModel? lastOrderedAddress;

      if(_isLoggedIn && widget.orderType == 'delivery') {
        lastOrderedAddress = await  locationProvider.getLastOrderedAddress();
      }

      CheckOutHelper.selectDeliveryAddressAuto(orderType: widget.orderType, isLoggedIn: (_isLoggedIn || CheckOutHelper.isGuestCheckout()), lastAddress: lastOrderedAddress);
    }
  }
}