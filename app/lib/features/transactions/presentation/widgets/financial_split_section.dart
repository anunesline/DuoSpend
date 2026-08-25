import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/financial_split/financial_split_configuration.dart';
import '../../domain/financial_split/financial_split_rules.dart';

class FinancialSplitSection extends StatelessWidget {
  final bool enabled;
  final FinancialSplitConfiguration configuration;
  final String selectedPayerMemberId;
  final String selectedPurchaseDestination;
  final String? partnerDisplayName;
  final ValueChanged<String> onPayerChanged;
  final ValueChanged<String> onPurchaseDestinationChanged;

  const FinancialSplitSection({
    super.key,
    required this.enabled,
    required this.configuration,
    required this.selectedPayerMemberId,
    required this.selectedPurchaseDestination,
    this.partnerDisplayName,
    required this.onPayerChanged,
    required this.onPurchaseDestinationChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!configuration.isFinancialSplitAvailable) {
      return const SizedBox.shrink();
    }

    final payer = configuration.resolvePayerMemberId(selectedPayerMemberId);
    final destination = configuration.resolvePurchaseDestination(selectedPurchaseDestination);

    return DuoCard(
      borderRadius: 26,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded,color:DuoColors.primaryLight),
              SizedBox(width:10),
              Expanded(
                child: Text(
                  'Divisão financeira',
                  style: TextStyle(
                    color:DuoColors.textPrimary,
                    fontSize:18,
                    fontWeight:FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height:6),
          const Text(
            'Defina quem pagou e para quem a compra foi realizada.',
            style: TextStyle(color:DuoColors.textSecondary,fontSize:12),
          ),
          if (configuration.canSelectPayer) ...[
            const SizedBox(height:24),
            const Text('Quem pagou?',
                style: TextStyle(
                    color:DuoColors.textPrimary,
                    fontWeight:FontWeight.w700)),
            const SizedBox(height:10),
            ...configuration.allowedPayerMemberIds.map((m)=>_OptionTile(
              enabled: enabled,
              selected: payer==m,
              title:_resolvePayerLabel(m),
              icon: Icons.person_rounded,
              onTap:()=>onPayerChanged(m),
            )),
          ],
          if(configuration.canSelectPurchaseDestination)...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical:18),
              child: Divider(color:DuoColors.border,height:1),
            ),
            const Text('Compra para',
                style: TextStyle(
                    color:DuoColors.textPrimary,
                    fontWeight:FontWeight.w700)),
            const SizedBox(height:10),
            ...configuration.allowedPurchaseDestinations.map((d)=>_OptionTile(
              enabled: enabled,
              selected: destination==d,
              title:_resolvePurchaseDestinationLabel(d),
              icon: Icons.group_rounded,
              onTap:()=>onPurchaseDestinationChanged(d),
            )),
          ]
        ],
      ),
    );
  }

  String _resolvePayerLabel(String memberId) {
    if (memberId.trim() ==
        configuration.currentUserMemberId.trim()) {
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

class _OptionTile extends StatelessWidget{
  final bool enabled;
  final bool selected;
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _OptionTile({required this.enabled,required this.selected,required this.title,required this.icon,required this.onTap});

  @override
  Widget build(BuildContext context){
    return Padding(
      padding: const EdgeInsets.only(bottom:10),
      child: InkWell(
        onTap: enabled?onTap:null,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds:180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:selected?DuoColors.primary.withValues(alpha:.12):DuoColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color:selected?DuoColors.primaryLight:DuoColors.border),
          ),
          child: Row(
            children:[
              Icon(icon,color:selected?DuoColors.primaryLight:DuoColors.textSecondary),
              const SizedBox(width:12),
              Expanded(child:Text(title,style:const TextStyle(color:DuoColors.textPrimary,fontWeight:FontWeight.w700))),
              Icon(selected?Icons.check_circle_rounded:Icons.radio_button_unchecked_rounded,
                color:selected?DuoColors.primaryLight:DuoColors.textSecondary)
            ],
          ),
        ),
      ),
    );
  }
}
