import 'package:flutter/material.dart';

import 'duo_colors.dart';

class DuoPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final bool useSuccessStyle;
  final double height;

  const DuoPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.useSuccessStyle = false,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    final button = AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isEnabled ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: useSuccessStyle
              ? DuoColors.successGradient
              : DuoColors.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isEnabled
              ? useSuccessStyle
                  ? DuoColors.successGlow
                  : DuoColors.primaryGlow
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: fullWidth ? double.infinity : null,
              height: height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  mainAxisSize:
                      fullWidth ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: isLoading
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 21,
                              height: 21,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  DuoColors.textPrimary,
                                ),
                              ),
                            )
                          : Row(
                              key: const ValueKey('content'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (icon != null) ...[
                                  Icon(
                                    icon,
                                    size: 21,
                                    color: DuoColors.textPrimary,
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: DuoColors.textPrimary,
                                    letterSpacing: -.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}