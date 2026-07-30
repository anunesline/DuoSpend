import 'package:flutter/material.dart';

import 'duo_colors.dart';

class DuoHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const DuoHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(24, 20, 24, 28),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DuoColors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: DuoColors.textPrimary,
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}