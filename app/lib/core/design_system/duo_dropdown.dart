import 'package:flutter/material.dart';

import 'duo_colors.dart';

class DuoDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  final String? helperText;
  final IconData? icon;
  final bool enabled;

  const DuoDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.helperText,
    this.icon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final canInteract =
        enabled && onChanged != null && items.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: DuoColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: DuoColors.textSecondary,
          ),
          dropdownColor: DuoColors.surface,
          borderRadius: BorderRadius.circular(18),
          style: TextStyle(
            color: canInteract
                ? DuoColors.textPrimary
                : DuoColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            prefixIcon: icon == null
                ? null
                : Icon(
                    icon,
                    size: 20,
                    color: canInteract
                        ? DuoColors.primaryLight
                        : DuoColors.textSecondary,
                  ),
            filled: true,
            fillColor: canInteract
                ? DuoColors.surface
                : DuoColors.primary.withValues(alpha: .06),
            hintStyle: const TextStyle(
              color: DuoColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            helperStyle: const TextStyle(
              color: DuoColors.textSecondary,
              fontSize: 11,
              height: 1.35,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: DuoColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: DuoColors.primaryLight,
                width: 1.4,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: DuoColors.border.withValues(alpha: .65),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: DuoColors.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: DuoColors.error,
                width: 1.4,
              ),
            ),
          ),
          items: items,
          onChanged: canInteract ? onChanged : null,
        ),
      ],
    );
  }
}
