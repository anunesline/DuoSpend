import 'package:flutter/material.dart';

import 'duo_colors.dart';

class DuoSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const DuoSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: 28),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: DuoColors.textPrimary,
                        letterSpacing: -.4,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: DuoColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}