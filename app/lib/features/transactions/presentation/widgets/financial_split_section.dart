import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../domain/financial_split/financial_split_configuration.dart';
import '../../domain/financial_split/financial_split_rules.dart';

class FinancialSplitSection extends StatelessWidget {
  final bool enabled;
  final FinancialSplitConfiguration configuration;
  final String selectedPayerMemberId;
  final String selectedPurchaseDestination;
  final String selectedSplitType;
  final double currentUserPercent;
  final String? partnerDisplayName;
  final ValueChanged<String> onPayerChanged;
  final ValueChanged<String> onPurchaseDestinationChanged;
  final ValueChanged<String> onSplitTypeChanged;
  final ValueChanged<double> onCurrentUserPercentChanged;

  const FinancialSplitSection({
    super.key,
    required this.enabled,
    required this.configuration,
    required this.selectedPayerMemberId,
    required this.selectedPurchaseDestination,
    required this.selectedSplitType,
    required this.currentUserPercent,
    this.partnerDisplayName,
    required this.onPayerChanged,
    required this.onPurchaseDestinationChanged,
    required this.onSplitTypeChanged,
    required this.onCurrentUserPercentChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!configuration.isFinancialSplitAvailable) {
      return const SizedBox.shrink();
    }

    final payer = configuration.resolvePayerMemberId(selectedPayerMemberId);
    final destination =
        configuration.resolvePurchaseDestination(selectedPurchaseDestination);
    final partnerPercent = 100 - currentUserPercent;

    return DuoCard(
      borderRadius: 26,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: DuoColors.primaryLight,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Divisão financeira',
                  style: TextStyle(
                    color: DuoColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Quem consumiu e quem assume o valor são escolhas separadas.',
            style: TextStyle(
              color: DuoColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (configuration.canSelectPayer) ...[
            const SizedBox(height: 24),
            const _FieldLabel('Quem pagou?'),
            const SizedBox(height: 10),
            ...configuration.allowedPayerMemberIds.map(
              (memberId) => _OptionTile(
                enabled: enabled,
                selected: payer == memberId,
                title: _resolvePayerLabel(memberId),
                icon: Icons.person_rounded,
                onTap: () => onPayerChanged(memberId),
              ),
            ),
          ],
          if (configuration.canSelectPurchaseDestination) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Divider(color: DuoColors.border, height: 1),
            ),
            const _FieldLabel('Compra para'),
            const SizedBox(height: 10),
            ...configuration.allowedPurchaseDestinations.map(
              (value) => _OptionTile(
                enabled: enabled,
                selected: destination == value,
                title: _resolvePurchaseDestinationLabel(value),
                icon: Icons.group_rounded,
                onTap: () => onPurchaseDestinationChanged(value),
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(color: DuoColors.border, height: 1),
          ),
          const _FieldLabel('Como dividir o valor?'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SplitChoice(
                label: 'Sem divisão',
                selected: selectedSplitType == FinancialSplitRules.splitTypeNone,
                enabled: enabled,
                onTap: () => onSplitTypeChanged(
                  FinancialSplitRules.splitTypeNone,
                ),
              ),
              _SplitChoice(
                label: '50 / 50',
                selected: selectedSplitType == FinancialSplitRules.splitTypeEqual,
                enabled: enabled,
                onTap: () => onSplitTypeChanged(
                  FinancialSplitRules.splitTypeEqual,
                ),
              ),
              _SplitChoice(
                label: 'Personalizada',
                selected: selectedSplitType == FinancialSplitRules.splitTypeCustom,
                enabled: enabled,
                onTap: () => onSplitTypeChanged(
                  FinancialSplitRules.splitTypeCustom,
                ),
              ),
            ],
          ),
          if (selectedSplitType == FinancialSplitRules.splitTypeCustom) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Eu ${currentUserPercent.round()}%',
                    style: const TextStyle(
                      color: DuoColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$_resolvedPartnerLabel ${partnerPercent.round()}%',
                  style: const TextStyle(
                    color: DuoColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Slider(
              value: currentUserPercent.clamp(0, 100),
              min: 0,
              max: 100,
              divisions: 20,
              label: '${currentUserPercent.round()} / ${partnerPercent.round()}',
              onChanged: enabled ? onCurrentUserPercentChanged : null,
            ),
            const Text(
              'Ex.: ajuste para 70% / 30%. O total sempre permanece em 100%.',
              style: TextStyle(
                color: DuoColors.textHint,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _resolvePayerLabel(String memberId) {
    if (memberId.trim() == configuration.currentUserMemberId.trim()) {
      return 'Eu';
    }
    return _resolvedPartnerLabel;
  }

  String get _resolvedPartnerLabel {
    final normalizedName = partnerDisplayName?.trim();
    if (normalizedName == null || normalizedName.isEmpty) {
      return 'Parceiro';
    }
    return normalizedName;
  }

  String _resolvePurchaseDestinationLabel(String value) {
    switch (value) {
      case FinancialSplitRules.purchaseForSelf:
        return 'Eu';
      case FinancialSplitRules.purchaseForPartner:
        return _resolvedPartnerLabel;
      case FinancialSplitRules.purchaseForBoth:
        return 'Ambos';
      default:
        return 'Outro';
    }
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: DuoColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SplitChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _SplitChoice({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: enabled ? (_) => onTap() : null,
    );
  }
}

class _OptionTile extends StatelessWidget {
  final bool enabled;
  final bool selected;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _OptionTile({
    required this.enabled,
    required this.selected,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? DuoColors.primary.withValues(alpha: .12)
                : DuoColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? DuoColors.primaryLight : DuoColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? DuoColors.primaryLight
                    : DuoColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: DuoColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? DuoColors.primaryLight
                    : DuoColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
