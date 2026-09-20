import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Scoped to the Home until the next screens adopt the approved visual system.
abstract final class OrbitHomeTokens {
  static const background = Color(0xFF030B17);
  static const surface = Color(0xFF0D1626);
  static const border = Color(0xFF273047);
  static const text = Color(0xFFF5F3FC);
  static const muted = Color(0xFFBEB9D4);
  static const purple = Color(0xFFBB6CFF);
  static const green = Color(0xFF08EC87);
  static const cyan = Color(0xFF00B9FF);
  static const amber = Color(0xFFFFA21A);
  static const red = Color(0xFFFF718B);
  static const gap = 9.0;
  static const radius = 16.0;
  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xEC111B2C), Color(0xF508111F)],
  );
  static const accentGradient = LinearGradient(
    colors: [Color(0xFF9B51FF), Color(0xFF782ADD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const greenGradient = LinearGradient(
    colors: [Color(0xFF59FFA3), Color(0xFF00D976)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static Color balanceColor(double value) => value > 0
      ? green
      : value < 0
      ? red
      : muted;
}

String orbitMoney(double value, {bool visible = true}) => visible
    ? NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value)
    : 'R\$ ••••';

class OrbitHomeSurface extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  const OrbitHomeSurface({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(12),
    this.radius = OrbitHomeTokens.radius,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: OrbitHomeTokens.cardGradient,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: OrbitHomeTokens.border.withValues(alpha: .85),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    ),
  );
}

class OrbitHomeIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const OrbitHomeIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withValues(alpha: .22), color.withValues(alpha: .06)],
      ),
      border: Border.all(color: color.withValues(alpha: .16)),
    ),
    child: Icon(icon, color: color, size: size * .58),
  );
}

class OrbitHomeProgress extends StatelessWidget {
  final double? value;
  final List<Color> colors;
  final double height;
  const OrbitHomeProgress({
    super.key,
    required this.value,
    this.colors = const [OrbitHomeTokens.green, Color(0xFF00BE78)],
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: SizedBox(
      height: height,
      child: Stack(
        children: [
          const Positioned.fill(
            child: ColoredBox(color: OrbitHomeTokens.border),
          ),
          if (value != null)
            FractionallySizedBox(
              widthFactor: value!.clamp(0, 1),
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class OrbitHomeAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool outlined;
  const OrbitHomeAction({
    super.key,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: MediaQuery.sizeOf(context).width * .44,
    ),
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: OrbitHomeTokens.purple,
        minimumSize: const Size(44, 40),
        padding: EdgeInsets.symmetric(horizontal: outlined ? 10 : 4),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
          side: outlined
              ? BorderSide(color: OrbitHomeTokens.purple.withValues(alpha: .22))
              : BorderSide.none,
        ),
        backgroundColor: outlined
            ? OrbitHomeTokens.purple.withValues(alpha: .045)
            : null,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label, maxLines: 2, textAlign: TextAlign.center),
          ),
          if (outlined) const Icon(Icons.chevron_right_rounded, size: 17),
        ],
      ),
    ),
  );
}

class OrbitHomeSectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color color;
  final String action;
  final VoidCallback onAction;
  const OrbitHomeSectionTitle({
    super.key,
    required this.title,
    this.icon,
    this.color = OrbitHomeTokens.purple,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (icon != null) ...[
        Icon(icon, color: color, size: 25),
        const SizedBox(width: 9),
      ],
      Expanded(
        child: Text(
          title,
          style: TextStyle(
            fontSize: icon == null ? 13 : 15,
            fontWeight: FontWeight.w600,
            color: OrbitHomeTokens.text,
          ),
        ),
      ),
      const SizedBox(width: 4),
      OrbitHomeAction(label: action, onTap: onAction),
    ],
  );
}

class OrbitHomeMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;
  final IconData icon;
  const OrbitHomeMessage({
    super.key,
    required this.message,
    this.onTap,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) => OrbitHomeSurface(
    onTap: onTap,
    child: Row(
      children: [
        Icon(icon, color: OrbitHomeTokens.muted, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: OrbitHomeTokens.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
        if (onTap != null)
          const Icon(
            Icons.chevron_right_rounded,
            color: OrbitHomeTokens.purple,
          ),
      ],
    ),
  );
}
