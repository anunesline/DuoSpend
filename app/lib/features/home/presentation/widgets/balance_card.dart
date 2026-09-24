import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_amount.dart';
import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';

class BalanceCard extends StatefulWidget {
  final double balance;
  final double income;
  final double expense;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _valuesVisible = true;

  void _toggleValues() {
    setState(() => _valuesVisible = !_valuesVisible);
  }

  void _showDetails() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          decoration: BoxDecoration(
            color: DuoColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: DuoColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DuoColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Visão financeira',
                style: TextStyle(
                  color: DuoColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              _DetailAmountRow(
                label: 'Saldo atual',
                value: widget.balance,
                visible: _valuesVisible,
                icon: Icons.account_balance_wallet_rounded,
                accentColor: DuoColors.primaryLight,
              ),
              const SizedBox(height: 12),
              _DetailAmountRow(
                label: 'Entradas no mês',
                value: widget.income,
                visible: _valuesVisible,
                icon: Icons.arrow_upward_rounded,
                accentColor: DuoColors.success,
              ),
              const SizedBox(height: 12),
              _DetailAmountRow(
                label: 'Saídas no mês',
                value: widget.expense,
                visible: _valuesVisible,
                icon: Icons.arrow_downward_rounded,
                accentColor: DuoColors.error,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir detalhes da visão financeira',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _showDetails,
        child: DuoCard(
          glow: true,
          borderRadius: 28,
          gradient: DuoColors.heroGradient,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Visão financeira',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: DuoColors.primaryLight,
                            letterSpacing: .2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _AvailableLabel(
                          valuesVisible: _valuesVisible,
                          onToggle: _toggleValues,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: DuoColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: DuoColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _AmountValue(
                value: widget.balance,
                visible: _valuesVisible,
                amountFontSize: 34,
              ),
              const SizedBox(height: 22),
              Container(
                height: 1,
                color: DuoColors.divider,
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _FlowStat(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Entradas no mês',
                      value: widget.income,
                      visible: _valuesVisible,
                      accentColor: DuoColors.success,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 34,
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    color: DuoColors.divider,
                  ),
                  Expanded(
                    child: _FlowStat(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Saídas no mês',
                      value: widget.expense,
                      visible: _valuesVisible,
                      accentColor: DuoColors.error,
                      amountColor: DuoColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailableLabel extends StatelessWidget {
  final bool valuesVisible;
  final VoidCallback onToggle;

  const _AvailableLabel({
    required this.valuesVisible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Saldo atual',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DuoColors.textSecondary,
            letterSpacing: .1,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: valuesVisible ? 'Ocultar valores' : 'Mostrar valores',
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: onToggle,
          icon: Icon(
            valuesVisible
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            size: 16,
            color: DuoColors.textHint,
          ),
        ),
      ],
    );
  }
}

class _AmountValue extends StatelessWidget {
  final double value;
  final bool visible;
  final bool compact;
  final double amountFontSize;
  final Color? color;

  const _AmountValue({
    required this.value,
    required this.visible,
    this.compact = false,
    required this.amountFontSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (visible) {
      return DuoAmount(
        value: value,
        compact: compact,
        amountFontSize: amountFontSize,
        color: color,
      );
    }

    return Text(
      'R\$ ••••••',
      style: TextStyle(
        color: color ?? DuoColors.textPrimary,
        fontSize: amountFontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: compact ? -.2 : -.8,
      ),
    );
  }
}

class _FlowStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final bool visible;
  final Color accentColor;
  final Color? amountColor;

  const _FlowStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.visible,
    required this.accentColor,
    this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: accentColor),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _AmountValue(
          value: value,
          visible: visible,
          compact: true,
          amountFontSize: 16,
          color: amountColor ?? accentColor,
        ),
      ],
    );
  }
}

class _DetailAmountRow extends StatelessWidget {
  final String label;
  final double value;
  final bool visible;
  final IconData icon;
  final Color accentColor;

  const _DetailAmountRow({
    required this.label,
    required this.value,
    required this.visible,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DuoColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DuoColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: DuoColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _AmountValue(
            value: value,
            visible: visible,
            compact: true,
            amountFontSize: 16,
            color: DuoColors.textPrimary,
          ),
        ],
      ),
    );
  }
}
