import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/purchase/services/financial_split_service.dart';

class FinancialSplitSection extends StatelessWidget {
  final bool enabled;

  final bool showPartnerOptions;

  final bool payerIsCurrentUser;

  final String purchaseFor;

  final ValueChanged<bool> onPayerChanged;

  final ValueChanged<String> onPurchaseForChanged;

  const FinancialSplitSection({
    super.key,
    required this.enabled,
    required this.showPartnerOptions,
    required this.payerIsCurrentUser,
    required this.purchaseFor,
    required this.onPayerChanged,
    required this.onPurchaseForChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!showPartnerOptions) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Divisão financeira',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              'Quem pagou?',
              style: Theme.of(context).textTheme.titleSmall,
            ),

            RadioListTile<bool>(
              dense: true,
              value: true,
              groupValue: payerIsCurrentUser,
              onChanged: enabled
                  ? (value) => onPayerChanged(true)
                  : null,
              title: const Text('Eu'),
            ),

            RadioListTile<bool>(
              dense: true,
              value: false,
              groupValue: payerIsCurrentUser,
              onChanged: enabled
                  ? (value) => onPayerChanged(false)
                  : null,
              title: const Text('Parceiro'),
            ),

            const Divider(height: AppSpacing.xl),

            Text(
              'Compra para',
              style: Theme.of(context).textTheme.titleSmall,
            ),

            RadioListTile<String>(
              dense: true,
              value: FinancialSplitService.purchaseForSelf,
              groupValue: purchaseFor,
              onChanged: enabled
                  ? (value) {
                      if (value != null) {
                        onPurchaseForChanged(value);
                      }
                    }
                  : null,
              title: const Text('Eu'),
            ),

            RadioListTile<String>(
              dense: true,
              value: FinancialSplitService.purchaseForPartner,
              groupValue: purchaseFor,
              onChanged: enabled
                  ? (value) {
                      if (value != null) {
                        onPurchaseForChanged(value);
                      }
                    }
                  : null,
              title: const Text('Parceiro'),
            ),

            RadioListTile<String>(
              dense: true,
              value: FinancialSplitService.purchaseForBoth,
              groupValue: purchaseFor,
              onChanged: enabled
                  ? (value) {
                      if (value != null) {
                        onPurchaseForChanged(value);
                      }
                    }
                  : null,
              title: const Text('Ambos'),
            ),
          ],
        ),
      ),
    );
  }
}