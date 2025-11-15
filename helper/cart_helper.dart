import 'package:flutter_grocery/common/models/cart_model.dart';
import 'package:flutter_grocery/common/models/product_model.dart';
import 'package:flutter_grocery/helper/price_converter_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CartHelper {
  
  /// Check if any items in the cart require a prescription
  static bool cartRequiresPrescription(List<CartModel> cartList) {
    return cartList.any((cartItem) => cartItem.product?.requiresPrescription == true);
  }

  /// Validate if prescription is uploaded when required
  static bool isPrescriptionValid(List<CartModel> cartList, List<dynamic>? imageFiles) {
    // If no items require prescription, validation passes
    if (!cartRequiresPrescription(cartList)) {
      return true;
    }
    
    // If items require prescription, check if images are uploaded
    return imageFiles != null && imageFiles.isNotEmpty;
  }

  static CartModel? getCartModel(Product product, {List<int>? variationIndexList, int? quantity}){
    CartModel? cartModel;
    Variations? variation;

    int? stock = 0;
    List variationList = [];

    double? price = product.price;
    stock = product.totalStock;
    double? categoryDiscountAmount;
    double? priceWithDiscount;

    for(int index = 0; index < (product.choiceOptions?.length ?? 0); index++) {
      if(product.choiceOptions?[index].options?.isNotEmpty ?? false) {

        if((product.choiceOptions?[index].options?.length ?? 0) > index) {
          if(variationIndexList != null) {
            variationList.add(product.choiceOptions?[index].options?[variationIndexList[index]].replaceAll(' ', ''));

          }else{
            variationList.add(product.choiceOptions?[index].options?[index].replaceAll(' ', ''));
          }
        }
      }
    }

    String variationType = '';
    bool isFirst = true;
    for (var variation in variationList) {
      if(isFirst) {
        variationType = '$variationType$variation';
        isFirst = false;

      }else {
        variationType = '$variationType-$variation';

      }
    }

    for(Variations variationValue in product.variations ?? []) {
      if(variationValue.type == variationType) {
        price = variationValue.price;
        variation = variationValue;
        stock = variationValue.stock;
        break;
      }
    }

    priceWithDiscount = PriceConverterHelper.convertWithDiscount(price, product.discount, product.discountType);

    if(product.categoryDiscount != null) {

      categoryDiscountAmount = PriceConverterHelper.convertWithDiscount(
        price, product.categoryDiscount?.discountAmount, product.categoryDiscount?.discountType,
        maxDiscount: product.categoryDiscount?.maximumAmount,
      );
    }

    if((categoryDiscountAmount ?? 0) > 0 && (categoryDiscountAmount ?? 0)  < (priceWithDiscount ?? 0)) {
      priceWithDiscount = categoryDiscountAmount;
    }

    cartModel = CartModel(
      product.id,
      (product.image?.isNotEmpty ?? false) ? product.image![0] : '',
      product.name,  price,
      priceWithDiscount,
      quantity, variation,
      (price! - priceWithDiscount!),
      (price- PriceConverterHelper.convertWithDiscount(price, product.tax, product.taxType)!),
      product.capacity, product.unit, stock, product,
    );


    return cartModel;
  }


  static double weightCalculation (List<CartModel> cartList){
    double sum = 0.0;
    for(CartModel item in cartList){
      sum += (item.product?.weight?.toDouble() ?? 0.0) * (item.quantity?.toInt() ?? 1.0);
    }
    return sum;
  }


}