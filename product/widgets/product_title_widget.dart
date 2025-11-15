import 'package:flutter/material.dart';
import 'package:flutter_grocery/common/models/product_model.dart';
import 'package:flutter_grocery/helper/price_converter_helper.dart';
import 'package:flutter_grocery/helper/responsive_helper.dart';
import 'package:flutter_grocery/localization/language_constraints.dart';
import 'package:flutter_grocery/common/providers/product_provider.dart';
import 'package:flutter_grocery/utill/color_resources.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/utill/styles.dart';
import 'package:flutter_grocery/common/widgets/custom_directionality_widget.dart';
import 'package:flutter_grocery/common/widgets/wish_button_widget.dart';
import 'package:provider/provider.dart';

class ProductTitleWidget extends StatelessWidget {
  final Product? product;
  final int? stock;
  final int? cartIndex;
  const ProductTitleWidget({super.key, required this.product, required this.stock,required this.cartIndex});

  @override
  Widget build(BuildContext context) {
    double? startingPrice;
    double? startingPriceWithDiscount;
    double? startingPriceWithCategoryDiscount;
    double? endingPrice;
    double? endingPriceWithDiscount;
    double? endingPriceWithCategoryDiscount;
    if(product!.variations!.isNotEmpty) {
      List<double?> priceList = [];
      for (var variation in product!.variations!) {
        priceList.add(variation.price);
      }
      priceList.sort((a, b) => a!.compareTo(b!));
      startingPrice = priceList[0];
      if(priceList[0]! < priceList[priceList.length-1]!) {
        endingPrice = priceList[priceList.length-1];
      }
    }else {
      startingPrice = product!.price;
    }

    if(product!.categoryDiscount != null) {
      startingPriceWithCategoryDiscount = PriceConverterHelper.convertWithDiscount(
        startingPrice, product!.categoryDiscount!.discountAmount, product!.categoryDiscount!.discountType,
        maxDiscount: product!.categoryDiscount!.maximumAmount,
      );

      if(endingPrice != null){
        endingPriceWithCategoryDiscount = PriceConverterHelper.convertWithDiscount(
          endingPrice, product!.categoryDiscount!.discountAmount, product!.categoryDiscount!.discountType,
          maxDiscount: product!.categoryDiscount!.maximumAmount,
        );
      }
    }
    startingPriceWithDiscount = PriceConverterHelper.convertWithDiscount(startingPrice, product!.discount, product!.discountType);

    if(endingPrice != null) {
      endingPriceWithDiscount = PriceConverterHelper.convertWithDiscount(endingPrice, product!.discount, product!.discountType);
    }

    if(startingPriceWithCategoryDiscount != null &&
        startingPriceWithCategoryDiscount > 0 &&
        startingPriceWithCategoryDiscount < startingPriceWithDiscount!) {
      startingPriceWithDiscount = startingPriceWithCategoryDiscount;
      endingPriceWithDiscount = endingPriceWithCategoryDiscount;
    }

    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        return Padding(
          padding: EdgeInsets.only(
            right: ResponsiveHelper.isDesktop(context)
                ? Dimensions.paddingSizeSmall
                : Dimensions.paddingSizeLarge,
            top: ResponsiveHelper.isDesktop(context)
                ? 0
                : Dimensions.paddingSizeLarge,
            left: ResponsiveHelper.isDesktop(context)
                ? 0
                : Dimensions.paddingSizeLarge,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Product name with wishlist button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(product?.name ?? '', style: poppinsSemiBold.copyWith(
                    fontSize: ResponsiveHelper.isDesktop(context) ? Dimensions.fontSizeOverLarge : Dimensions.fontSizeLarge,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                WishButtonWidget(
                  product: product,
                  edgeInset: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeDefault),

            // Rating, Stock Status, and Prescription Badge in one row
            Row(children: [
              product?.rating != null ? Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: ColorResources.ratingColor.withValues(alpha: 0.1),
                ),
                child: Row(mainAxisSize : MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Icon(Icons.star_rounded, color: ColorResources.ratingColor, size: Dimensions.paddingSizeDefault),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                  Text(
                    product!.rating!.isNotEmpty ? product!.rating![0].average!.toStringAsFixed(1) : '0.0',
                    style: poppinsMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.80), fontSize: Dimensions.fontSizeSmall),
                  ),
                ]),
              ) : const SizedBox(),

              SizedBox(width: product!.rating != null ? Dimensions.paddingSizeSmall : 0),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSizeLarge),
                  border: Border.all(width: 1, color: Theme.of(context).primaryColor),
                  color: Theme.of(context).primaryColor.withValues(alpha:0.05),
                ),
                child: Text(
                  getTranslated(product!.totalStock! > 0
                      ? 'in_stock' : 'stock_out', context),
                  style: poppinsSemiBold.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall),
                ),
              ),

              // Prescription badge in same row
              SizedBox(width: (product?.requiresPrescription ?? false) ? Dimensions.paddingSizeSmall : 0),
              (product?.requiresPrescription ?? false) ? Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSizeLarge),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.medical_services, color: Colors.orange[800], size: 12),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    Text(
                      (getTranslated('requires_prescription', context) != 'requires_prescription'
                          ? getTranslated('requires_prescription', context)
                          : 'This item requires prescription')!,
                      style: poppinsMedium.copyWith(
                        color: Colors.orange[800],
                        fontSize: Dimensions.fontSizeExtraSmall,
                      ),
                    ),
                  ],
                ),
              ) : const SizedBox(),
            ]),

          ]),
        );
      },
    );
  }
}