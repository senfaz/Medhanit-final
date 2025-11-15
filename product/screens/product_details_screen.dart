import 'package:flutter/material.dart';
import 'package:flutter_grocery/common/enums/footer_type_enum.dart';
import 'package:flutter_grocery/common/models/cart_model.dart';
import 'package:flutter_grocery/common/providers/cart_provider.dart';
import 'package:flutter_grocery/common/providers/product_provider.dart';
import 'package:flutter_grocery/common/widgets/custom_button_widget.dart';
import 'package:flutter_grocery/common/widgets/custom_directionality_widget.dart';
import 'package:flutter_grocery/common/widgets/custom_image_widget.dart';
import 'package:flutter_grocery/common/widgets/custom_loader_widget.dart';
import 'package:flutter_grocery/common/widgets/custom_zoom_widget.dart';
import 'package:flutter_grocery/common/widgets/footer_web_widget.dart';
import 'package:flutter_grocery/common/widgets/web_app_bar_widget.dart';
import 'package:flutter_grocery/features/product/widgets/details_app_bar_widget.dart';
import 'package:flutter_grocery/features/product/widgets/product_description_widget.dart';
import 'package:flutter_grocery/features/product/widgets/product_image_widget.dart';
import 'package:flutter_grocery/features/product/widgets/product_title_widget.dart';
import 'package:flutter_grocery/features/product/widgets/quantity_button_widget.dart';
import 'package:flutter_grocery/features/product/widgets/selected_product_widget.dart';
import 'package:flutter_grocery/features/product/widgets/variation_widget.dart';
import 'package:flutter_grocery/features/splash/providers/splash_provider.dart';
import 'package:flutter_grocery/helper/cart_helper.dart';
import 'package:flutter_grocery/helper/custom_snackbar_helper.dart';
import 'package:flutter_grocery/helper/price_converter_helper.dart';
import 'package:flutter_grocery/helper/responsive_helper.dart';
import 'package:flutter_grocery/localization/app_localization.dart';
import 'package:flutter_grocery/localization/language_constraints.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/utill/styles.dart';
import 'package:flutter_grocery/helper/analytics_helper.dart';
import 'package:provider/provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String? productId;
  final bool? fromSearch;
  const ProductDetailsScreen({super.key, required this.productId, this.fromSearch = false});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>  with TickerProviderStateMixin {
  int _tabIndex = 0;
  bool showSeeMoreButton = false;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    final ProductProvider productProvider = Provider.of(context, listen: false);
    productProvider.getProductDetails('${widget.productId}', searchQuery: widget.fromSearch!);
    Provider.of<CartProvider>(context, listen: false).getCartData();
    Provider.of<CartProvider>(context, listen: false).onSelectProductStatus(0, false);

    productProvider.getProductReviews(id: widget.productId, offset: 1, isUpdate: false);

    // Track product view after product loads
    Future.delayed(const Duration(milliseconds: 500), () {
      if (productProvider.product != null) {
        AnalyticsHelper.logViewItem(
          itemId: productProvider.product!.id.toString(),
          itemName: productProvider.product!.name ?? '',
          itemCategory: productProvider.product!.categoryIds?.isNotEmpty == true
              ? productProvider.product!.categoryIds!.first.id ?? 'Unknown'
              : 'Unknown',
          value: productProvider.product!.price ?? 0,
          currency: 'ETB',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);

    return Scaffold(
      appBar: ResponsiveHelper.isDesktop(context) ? const PreferredSize(preferredSize: Size.fromHeight(120), child: WebAppBarWidget())  : DetailsAppBarWidget(key: UniqueKey(), title: 'product_details'.tr),

      body: Consumer<CartProvider>(builder: (context, cartProvider, child) {
        return  Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            double? priceWithQuantity = 0;
            CartModel? cartModel;

            if(productProvider.product != null) {


              cartModel = CartHelper.getCartModel(productProvider.product!, quantity: cartProvider.quantity, variationIndexList: cartProvider.variationIndex);

              cartProvider.setExistData(cartProvider.isExistInCart(cartModel));

              double? priceWithDiscount = PriceConverterHelper.convertWithDiscount(
                cartModel?.price, productProvider.product?.discount,
                productProvider.product?.discountType,
              );


              if(cartProvider.cartIndex != null) {
                priceWithQuantity = (priceWithDiscount ?? 0) * (cartProvider.cartList[cartProvider.cartIndex!].quantity!);

              }else {
                priceWithQuantity = (priceWithDiscount ?? 0) * cartProvider.quantity;

              }
            }

            return productProvider.product != null ? !ResponsiveHelper.isDesktop(context) ? Column(
              children: [
                Expanded(child: SingleChildScrollView(
                  controller: scrollController,
                  physics: ResponsiveHelper.isMobilePhone() ? const BouncingScrollPhysics() : null,
                  child: Center(
                    child: SizedBox(
                      width: Dimensions.webScreenWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          Column(children: [
                            ProductImageWidget(productModel: productProvider.product),

                            SizedBox(height: 60, child: productProvider.product?.image != null ? SelectedImageWidget(productModel: productProvider.product) : const SizedBox(),),

                            ProductTitleWidget(product: productProvider.product, stock: cartModel?.stock, cartIndex: cartProvider.cartIndex),

                            VariationWidget(product: productProvider.product),

                            // Conditional total amount display - only show when quantity > 1
                            if (cartProvider.quantity > 1 || (cartProvider.cartIndex != null && cartProvider.cartList[cartProvider.cartIndex!].quantity! > 1))
                              const SizedBox(height: 30),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeLarge),
                                child: Row(mainAxisAlignment : MainAxisAlignment.spaceBetween, children: [

                                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('${getTranslated('total_amount', context)}:', style: poppinsMedium.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.70),
                                    )),
                                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                    CustomDirectionalityWidget(child: Text(
                                      PriceConverterHelper.convertPrice(context, priceWithQuantity),
                                      style: poppinsBold.copyWith(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: Dimensions.fontSizeExtraLarge,
                                      ),
                                    )),
                                  ]),
                                  SizedBox(height: ResponsiveHelper.isDesktop(context) ? 45 : 0),

                                  Builder(
                                      builder: (context) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).disabledColor.withValues(alpha: 0.07),
                                            borderRadius: BorderRadius.circular(Dimensions.radiusSizeSmall),
                                          ),

                                          child: Row(children: [
                                            QuantityButtonWidget(
                                              isIncrement: false, quantity: cartProvider.quantity,
                                              stock: cartModel?.stock, cartIndex: cartProvider.cartIndex,
                                              maxOrderQuantity: productProvider.product!.maximumOrderQuantity,
                                            ),
                                            const SizedBox(width: 15),

                                            Text(
                                              cartProvider.cartIndex != null ? cartProvider.cartList[cartProvider.cartIndex!].quantity.toString() : cartProvider.quantity.toString(),
                                              style: poppinsBold.copyWith(color: Theme.of(context).primaryColor),
                                            ),
                                            const SizedBox(width: 15),

                                            QuantityButtonWidget(
                                              isIncrement: true, quantity: cartProvider.quantity,
                                              stock: cartModel?.stock, cartIndex: cartProvider.cartIndex,
                                              maxOrderQuantity: productProvider.product!.maximumOrderQuantity,
                                            ),
                                          ]),
                                        );
                                      }
                                  ),

                                ]),
                              ),

                            // Quantity selector when total amount is not shown
                            if (!(cartProvider.quantity > 1 || (cartProvider.cartIndex != null && cartProvider.cartList[cartProvider.cartIndex!].quantity! > 1)))
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeLarge),
                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  // Add price information on the left
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${productProvider.product!.capacity} ${productProvider.product!.unit} ',
                                            style: poppinsMedium.copyWith(
                                              color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.70),
                                              fontSize: Dimensions.fontSizeDefault,
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'Price ',
                                            style: poppinsMedium.copyWith(
                                              color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.70),
                                              fontSize: Dimensions.fontSizeDefault,
                                            ),
                                          ),
                                          // Show original price first if there's a discount (scratched)
                                          if (cartModel != null && cartModel.price != null && productProvider.product?.discount != null &&
                                              PriceConverterHelper.convertWithDiscount(cartModel.price, productProvider.product!.discount, productProvider.product!.discountType)! < cartModel.price!) ...[
                                            TextSpan(
                                              text: PriceConverterHelper.convertPrice(context, cartModel.price),
                                              style: poppinsRegular.copyWith(
                                                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                                                fontSize: Dimensions.fontSizeDefault,
                                                decoration: TextDecoration.lineThrough,
                                                decorationColor: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                                                decorationThickness: 1.5,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' - ',
                                              style: poppinsMedium.copyWith(
                                                color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.70),
                                                fontSize: Dimensions.fontSizeDefault,
                                              ),
                                            ),
                                          ],
                                          TextSpan(
                                            text: PriceConverterHelper.convertPrice(context, PriceConverterHelper.convertWithDiscount(
                                              cartModel?.price, productProvider.product?.discount, productProvider.product?.discountType,
                                            )),
                                            style: poppinsBold.copyWith(
                                              color: Theme.of(context).primaryColor,
                                              fontSize: Dimensions.fontSizeLarge,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Keep the existing quantity buttons
                                  Builder(
                                      builder: (context) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).disabledColor.withValues(alpha: 0.07),
                                            borderRadius: BorderRadius.circular(Dimensions.radiusSizeSmall),
                                          ),

                                          child: Row(children: [
                                            QuantityButtonWidget(
                                              isIncrement: false, quantity: cartProvider.quantity,
                                              stock: cartModel?.stock, cartIndex: cartProvider.cartIndex,
                                              maxOrderQuantity: productProvider.product!.maximumOrderQuantity,
                                            ),
                                            const SizedBox(width: 15),

                                            Text(
                                              cartProvider.cartIndex != null ? cartProvider.cartList[cartProvider.cartIndex!].quantity.toString() : cartProvider.quantity.toString(),
                                              style: poppinsBold.copyWith(color: Theme.of(context).primaryColor),
                                            ),
                                            const SizedBox(width: 15),

                                            QuantityButtonWidget(
                                              isIncrement: true, quantity: cartProvider.quantity,
                                              stock: cartModel?.stock, cartIndex: cartProvider.cartIndex,
                                              maxOrderQuantity: productProvider.product!.maximumOrderQuantity,
                                            ),
                                          ]),
                                        );
                                      }
                                  ),
                                ]),
                              ),
                          ]),
                          SizedBox(height: ResponsiveHelper.isDesktop(context) ? Dimensions.fontSizeMaxLarge :  Dimensions.paddingSizeDefault),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                            child: ProductDescriptionWidget(
                              scrollController: scrollController,
                              showSeeMoreButton: showSeeMoreButton,
                              tabIndex: _tabIndex,
                              onTabChange: (int index) {
                                setState(() {
                                  _tabIndex = index;
                                });
                              },
                              onChangeButtonStatus: (bool status) {
                                setState(() {
                                  showSeeMoreButton = status;
                                });
                              },
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                )),

                Center(child: SizedBox(width: Dimensions.webScreenWidth, child: CustomButtonWidget(
                  icon: Icons.shopping_cart,
                  margin: Dimensions.paddingSizeSmall,
                  buttonText: getTranslated(cartProvider.cartIndex != null ? 'already_added' : (cartModel?.stock ?? 0) <= 0 ? 'out_of_stock' : 'add_to_card', context),
                  onPressed: (cartProvider.cartIndex == null && (cartModel?.stock ?? 0) > 0) ? () {
                    if (cartProvider.cartIndex == null && (cartModel?.stock ?? 0) > 0) {
                      cartProvider.addToCart(cartModel!);


                      showCustomSnackBarHelper(getTranslated('added_to_cart', context), isError: false);

                    } else {
                      showCustomSnackBarHelper(getTranslated('already_added', context));
                    }
                  } : null,
                ))),
              ],
            ) : CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(children: [
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Center(
                      child: SizedBox(
                        width: Dimensions.webScreenWidth,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Expanded(flex: 4, child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                                  child: Stack(
                                    children: [
                                      SizedBox(height: 400, width: double.maxFinite, child: CustomZoomWidget(
                                        image: ClipRRect(
                                          borderRadius: BorderRadius.circular(Dimensions.radiusSizeTen),
                                          child: CustomImageWidget(
                                            image: '${splashProvider.baseUrls?.productImageUrl}/${(productProvider.product?.image?.isNotEmpty ?? false)
                                                ? productProvider.product!.image![cartProvider.productSelect] : ''}',
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      )),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: Dimensions.paddingSizeSmall),

                                SizedBox(
                                  height: 70,
                                  child: productProvider.product!.image != null
                                      ? SelectedImageWidget(productModel: productProvider.product)
                                      : const SizedBox(),
                                ),
                              ],
                            )),
                            const SizedBox(width: 30),

                            Expanded(flex: 6,child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  ProductTitleWidget(product: productProvider.product, stock: cartModel?.stock, cartIndex: cartProvider.cartIndex),

                                  VariationWidget(product: productProvider.product),
                                  SizedBox(height: Dimensions.paddingSizeLarge),

                                  // Conditional total amount display for desktop - only show when quantity > 1
                                  if (cartProvider.quantity > 1 || (cartProvider.cartIndex != null && cartProvider.cartList[cartProvider.cartIndex!].quantity! > 1))
                                    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [
                                      Text('${getTranslated('total_amount', context)}:', style: poppinsMedium.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.70),
                                      )),
                                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                      CustomDirectionalityWidget(child: Text(
                                        PriceConverterHelper.convertPrice(context, priceWithQuantity),
                                        style: poppinsBold.copyWith(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: Dimensions.fontSizeMaxLarge,
                                        ),
                                      )),
                                    ]),
                                  SizedBox(height: (cartProvider.quantity > 1 || (cartProvider.cartIndex != null && cartProvider.cartList[cartProvider.cartIndex!].quantity! > 1)) ? 35 : 0),

                                  // WEB Price Row
                                  if (!(cartProvider.quantity > 1 || (cartProvider.cartIndex != null && cartProvider.cartList[cartProvider.cartIndex!].quantity! > 1)))
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${productProvider.product!.capacity} ${productProvider.product!.unit} ',
                                            style: poppinsMedium.copyWith(
                                              color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.70),
                                              fontSize: Dimensions.fontSizeDefault,
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'Price ',
                                            style: poppinsMedium.copyWith(
                                              color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.70),
                                              fontSize: Dimensions.fontSizeDefault,
                                            ),
                                          ),
                                          // Show original price first if there's a discount (scratched)
                                          if (cartModel != null && cartModel.price != null && productProvider.product?.discount != null &&
                                              PriceConverterHelper.convertWithDiscount(cartModel.price, productProvider.product!.discount, productProvider.product!.discountType)! < cartModel.price!) ...[
                                            TextSpan(
                                              text: PriceConverterHelper.convertPrice(context, cartModel.price),
                                              style: poppinsRegular.copyWith(
                                                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                                                fontSize: Dimensions.fontSizeDefault,
                                                decoration: TextDecoration.lineThrough,
                                                decorationColor: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                                                decorationThickness: 1.5,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' - ',
                                              style: poppinsMedium.copyWith(
                                                color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.70),
                                                fontSize: Dimensions.fontSizeDefault,
                                              ),
                                            ),
                                          ],
                                          TextSpan(
                                            text: PriceConverterHelper.convertPrice(context, PriceConverterHelper.convertWithDiscount(
                                              cartModel?.price, productProvider.product?.discount, productProvider.product?.discountType,
                                            )),
                                            style: poppinsBold.copyWith(
                                              color: Theme.of(context).primaryColor,
                                              fontSize: Dimensions.fontSizeLarge,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: Dimensions.paddingSizeDefault),

                                  Row(children: [

                                    Builder(
                                        builder: (context) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).disabledColor.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(Dimensions.radiusSizeSmall),
                                            ),

                                            child: Row(children: [
                                              QuantityButtonWidget(
                                                isIncrement: false, quantity: cartProvider.quantity,
                                                stock: cartModel?.stock, cartIndex: cartProvider.cartIndex,
                                                maxOrderQuantity: productProvider.product!.maximumOrderQuantity,
                                              ),
                                              const SizedBox(width: 15),

                                              Consumer<CartProvider>(builder: (context, cart, child) {
                                                return Text(cart.cartIndex != null ? cart.cartList[cart.cartIndex!].quantity.toString()
                                                    : cart.quantity.toString(), style: poppinsBold.copyWith(color: Theme.of(context).primaryColor)
                                                );
                                              }),
                                              const SizedBox(width: 15),

                                              QuantityButtonWidget(
                                                isIncrement: true, quantity: cartProvider.quantity,
                                                stock: cartModel?.stock, cartIndex: cartProvider.cartIndex,
                                                maxOrderQuantity: productProvider.product!.maximumOrderQuantity,
                                              ),
                                            ]),
                                          );
                                        }
                                    ),
                                    const SizedBox(width: Dimensions.paddingSizeDefault),

                                    Builder(
                                      builder: (context) => Center(
                                        child: SizedBox(
                                          width: 200,
                                          child: CustomButtonWidget(
                                            icon: Icons.shopping_cart,
                                            buttonText: getTranslated(cartProvider.cartIndex != null ? 'already_added' : (cartModel?.stock ?? 0) <= 0 ? 'out_of_stock' : 'add_to_card', context),
                                            onPressed: (cartProvider.cartIndex == null && (cartModel?.stock ?? 0) > 0) ? () {
                                              if (cartProvider.cartIndex == null && (cartModel?.stock ?? 0) > 0) {
                                                cartProvider.addToCart(cartModel!);

                                                showCustomSnackBarHelper(getTranslated('added_to_cart', context), isError: false);

                                              } else {
                                                showCustomSnackBarHelper(getTranslated('already_added', context));
                                              }
                                            } : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]),
                                ],
                              ),
                            ))
                          ],
                        ),
                      ),
                    ),
                    //Description
                    const SizedBox(height : Dimensions.paddingSizeExtraLarge),

                    Center(child: SizedBox(width: Dimensions.webScreenWidth, child: ProductDescriptionWidget(
                      scrollController: scrollController,
                      showSeeMoreButton: showSeeMoreButton,
                      tabIndex: _tabIndex,
                      onTabChange: (int index) {
                        setState(() {
                          _tabIndex = index;
                        });
                      },
                      onChangeButtonStatus: (bool status) {
                        setState(() {
                          showSeeMoreButton = status;
                        });
                      },
                    ))),
                    const SizedBox(height: Dimensions.paddingSizeDefault,),
                  ]),
                ),

                const FooterWebWidget(footerType: FooterType.sliver),
              ],
            ) : Center(child: CustomLoaderWidget(color: Theme.of(context).primaryColor));
          },
        );
      }),
    );
  }
}