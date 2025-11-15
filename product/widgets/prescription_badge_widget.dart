import 'package:flutter/material.dart';
import 'package:flutter_grocery/localization/language_constraints.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/utill/styles.dart';

class PrescriptionBadgeWidget extends StatelessWidget {
  final bool requiresPrescription;

  const PrescriptionBadgeWidget({
    super.key,
    required this.requiresPrescription,
  });

  @override
  Widget build(BuildContext context) {
    if (!requiresPrescription) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall
      ),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.medical_services, color: Colors.orange[800], size: 16),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Text(
            getTranslated('requires_prescription', context) ?? 'This item requires prescription',
            style: poppinsMedium.copyWith(
              color: Colors.deepOrange[800], // Darker orange for better contrast
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
        ],
      ),
    );
  }
}