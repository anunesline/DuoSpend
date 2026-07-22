import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/financial_split/financial_split_configuration.dart';
import '../../domain/financial_split/financial_split_rules.dart';

class FinancialSplitSection extends StatelessWidget {
  final bool enabled;

  final FinancialSplitConfiguration configuration;

  final String selectedPayerMemberId;

  final String selectedPurchaseDestination;

  final ValueChanged<String> onPayerChanged;

  final ValueChanged<String> onPurchaseDestinationChanged;

  const FinancialSplitSection({
    super.key,
    required this.enabled,
    required this.configuration,
    required this.selectedPayerMemberId,
    required this.selectedPurchaseDestination,
    required this.onPayerChanged,
    required this.onPurchaseDestinationChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!configuration.isFinancialSplitAvailable) {
      return const SizedBox.shrink();
    }

    final resolvedPayerMemberId =
        configuration.resolvePayerMemberId(
      selectedPayerMemberId,
    );

    final resolvedPurchaseDestination =
        configuration.resolvePurchaseDestination(
      selectedPurchaseDestination,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Divisão Financeira',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            if (configuration.canSelectPayer) ...[
              Text(
                'Quem pagou?',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              ...configuration.allowedPayerMemberIds.map(
                (memberId) {
                  return RadioListTile<String>(
                    dense: true,
                    value: memberId,
                    groupValue: resolvedPayerMemberId,
                    onChanged: enabled
                        ? (value) {
                            if (value != null) {
                              onPayerChanged(value);
                            }
                          }
                        : null,
                    title: Text(
                      _resolvePayerLabel(memberId),
                    ),
                  );
                },
              ),
            ],
            if (configuration.canSelectPayer &&
                configuration
                    .canSelectPurchaseDestination)
              const Divider(height: AppSpacing.xl),
            if (configuration
                .canSelectPurchaseDestination) ...[
              Text(
                'Compra para',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              ...configuration.allowedPurchaseDestinations.map(
                (purchaseDestination) {
                  return RadioListTile<String>(
                    dense: true,
                    value: purchaseDestination,
                    groupValue:
                        resolvedPurchaseDestination,
                    onChanged: enabled
                        ? (value) {
                            if (value != null) {
                              onPurchaseDestinationChanged(
                                value,
                              );
                            }
                          }
                        : null,
                    title: Text(
                      _resolvePurchaseDestinationLabel(
                        purchaseDestination,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _resolvePayerLabel(String memberId) {
    if (memberId == configuration.currentUserMemberId) {
      return 'Eu';
    }

    if (memberId == configuration.partnerMemberId) {
      return 'Parceiro';
    }

    return 'Membro';
  }

  String _resolvePurchaseDestinationLabel(
    String purchaseDestination,
  ) {
    switch (purchaseDestination) {
      case FinancialSplitRules.purchaseForSelf:
        return 'Eu';

      case FinancialSplitRules.purchaseForPartner:
        return 'Parceiro';

      case FinancialSplitRules.purchaseForBoth:
        return 'Ambos';

      default:
        return 'Outro';
    }
  }
}