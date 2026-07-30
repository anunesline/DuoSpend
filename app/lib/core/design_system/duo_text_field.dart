import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'duo_colors.dart';

class DuoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? helperText;
  final String? prefixText;
  final IconData? icon;
  final bool readOnly;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  const DuoTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.helperText,
    this.prefixText,
    this.icon,
    this.readOnly = false,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = enabled && !readOnly;

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
        TextField(
          controller: controller,
          readOnly: readOnly,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          onTap: onTap,
          style: TextStyle(
            color: enabled
                ? DuoColors.textPrimary
                : DuoColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          cursorColor: DuoColors.primaryLight,
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            prefixText: prefixText,
            prefixIcon: icon == null
                ? null
                : Icon(
                    icon,
                    size: 20,
                    color: effectiveEnabled
                        ? DuoColors.primaryLight
                        : DuoColors.textSecondary,
                  ),
            filled: true,
            fillColor: readOnly
                ? DuoColors.primary.withValues(alpha: .07)
                : DuoColors.surface,
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
            prefixStyle: const TextStyle(
              color: DuoColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            counterStyle: const TextStyle(
              color: DuoColors.textSecondary,
              fontSize: 11,
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
        ),
      ],
    );
  }
}
