import 'package:flutter/material.dart';

import 'duo_colors.dart';

class DuoSegmentOption<T> {
  final T value;
  final String label;
  final IconData? icon;

  const DuoSegmentOption({
    required this.value,
    required this.label,
    this.icon,
  });
}

class DuoSegmentedButton<T> extends StatelessWidget {
  final List<DuoSegmentOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final double height;
  final EdgeInsetsGeometry padding;

  const DuoSegmentedButton({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.height = 52,
    this.padding = const EdgeInsets.all(4),
  });

  @override
  Widget build(BuildContext context) {
    assert(options.isNotEmpty);

    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: DuoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: DuoColors.border,
        ),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = option.value == selectedValue;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: option != options.last ? 4 : 0,
              ),
              child: _DuoSegmentItem<T>(
                option: option,
                isSelected: isSelected,
                onTap: () => onChanged(option.value),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DuoSegmentItem<T> extends StatelessWidget {
  final DuoSegmentOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  const _DuoSegmentItem({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: isSelected ? DuoColors.primaryGradient : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isSelected ? DuoColors.primaryGlow : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (option.icon != null) ...[
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      option.icon,
                      key: ValueKey(isSelected),
                      size: 19,
                      color: isSelected
                          ? DuoColors.textPrimary
                          : DuoColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? DuoColors.textPrimary
                          : DuoColors.textSecondary,
                      letterSpacing: -.1,
                    ),
                    child: Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}