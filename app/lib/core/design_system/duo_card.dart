import 'dart:ui';

import 'package:flutter/material.dart';

import 'duo_colors.dart';

class DuoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool glass;
  final bool glow;
  final Gradient? gradient;
  final double borderRadius;

  const DuoCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.glass = false,
    this.glow = false,
    this.gradient,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: glass ? 10 : 0,
          sigmaY: glass ? 10 : 0,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: margin,
          padding: padding ??
              const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
          decoration: BoxDecoration(
            gradient: gradient ?? DuoColors.cardGradient,
            color: glass ? DuoColors.glass : null,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: DuoColors.border,
            ),
            boxShadow: [
              ...DuoColors.softShadow,
              if (glow) ...DuoColors.primaryGlow,
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}