import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'duo_colors.dart';

class DuoAmount extends StatelessWidget {
  final double value;
  final String? label;
  final String? prefix;
  final bool showSign;
  final bool compact;
  final TextAlign textAlign;
  final Color? color;
  final double? amountFontSize;

  const DuoAmount({
    super.key,
    required this.value,
    this.label,
    this.prefix,
    this.showSign = false,
    this.compact = false,
    this.textAlign = TextAlign.left,
    this.color,
    this.amountFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );

    final formattedValue = formatter.format(value.abs());
    final sign = showSign
        ? value > 0
            ? '+ '
            : value < 0
                ? '- '
                : ''
        : value < 0
            ? '- '
            : '';

    final resolvedColor = color ??
        (showSign
            ? value > 0
                ? DuoColors.success
                : value < 0
                    ? DuoColors.error
                    : DuoColors.textPrimary
            : DuoColors.textPrimary);

    return Column(
      crossAxisAlignment: _crossAxisAlignment,
      children: [
        if (label != null) ...[
          Text(
            label!,
            textAlign: textAlign,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DuoColors.textSecondary,
              letterSpacing: .1,
            ),
          ),
          SizedBox(height: compact ? 6 : 10),
        ],
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: _alignment,
          child: Text(
            '${prefix ?? ''}$sign$formattedValue',
            textAlign: textAlign,
            maxLines: 1,
            style: TextStyle(
              fontSize: amountFontSize ?? (compact ? 24 : 38),
              fontWeight: FontWeight.w800,
              color: resolvedColor,
              letterSpacing: compact ? -.7 : -1.3,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }

  CrossAxisAlignment get _crossAxisAlignment {
    switch (textAlign) {
      case TextAlign.center:
        return CrossAxisAlignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return CrossAxisAlignment.end;
      default:
        return CrossAxisAlignment.start;
    }
  }

  Alignment get _alignment {
    switch (textAlign) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }
}