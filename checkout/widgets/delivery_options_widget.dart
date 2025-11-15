import 'package:flutter/material.dart';
import 'package:flutter_grocery/common/models/delivery_option_model.dart';
import 'package:flutter_grocery/features/order/providers/order_provider.dart';
import 'package:flutter_grocery/helper/price_converter_helper.dart';
import 'package:flutter_grocery/localization/language_constraints.dart';
import 'package:flutter_grocery/utill/color_resources.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/utill/styles.dart';
import 'package:provider/provider.dart';

class DeliveryOptionsWidget extends StatelessWidget {
  final int branchId;
  final double orderAmount;
  final bool isEnabled;

  const DeliveryOptionsWidget({
    Key? key,
    required this.branchId,
    required this.orderAmount,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {

        if (orderProvider.isLoadingDeliveryOptions) {
          return Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (orderProvider.deliveryOptions == null || orderProvider.deliveryOptions!.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Text(
                  getTranslated('delivery_options', context),
                  style: poppinsMedium.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orderProvider.deliveryOptions!.length,
                itemBuilder: (context, index) {
                  final deliveryOption = orderProvider.deliveryOptions![index];
                  final isSelected = orderProvider.selectedDeliveryOption?.type == deliveryOption.type;
                  return _buildDeliveryOptionTile(
                    context,
                    deliveryOption,
                    isSelected,
                    isEnabled,
                        () {
                      if (deliveryOption.available) {
                        orderProvider.selectDeliveryOption(deliveryOption);
                      }
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryOptionTile(
      BuildContext context,
      DeliveryOptionModel option,
      bool isSelected,
      bool isEnabled,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isEnabled
              ? (isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.white)
              : Colors.grey.shade100,
        ),
        child: Row(
          children: [
            // Delivery type icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getDeliveryTypeColor(option.type).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getDeliveryTypeIcon(option.type),
                color: _getDeliveryTypeColor(option.type),
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Delivery option details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isEnabled ? Colors.black : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),

            // Price and selection indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (option.charge > 0)
                  Text(
                    PriceConverterHelper.convertPrice(context, option.charge),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isEnabled ? Colors.green : Colors.grey,
                    ),
                  )
                else
                  Text(
                    'FREE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isEnabled ? Colors.green : Colors.grey,
                    ),
                  ),

                const SizedBox(height: 8),

                // Selection indicator
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDeliveryTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'fast':
        return Icons.flash_on;
      case 'standard':
        return Icons.local_shipping;
      case 'free':
        return Icons.card_giftcard;
      default:
        return Icons.local_shipping;
    }
  }

  Color _getDeliveryTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fast':
        return Colors.orange;
      case 'standard':
        return Colors.blue;
      case 'free':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}