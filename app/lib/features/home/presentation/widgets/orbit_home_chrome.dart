import 'package:flutter/material.dart';

import 'orbit_home_primitives.dart';

class OrbitHomeBackdrop extends StatelessWidget {
  const OrbitHomeBackdrop({super.key});

  // Existing Home artwork. No generated assets, screenshot slicing or mockup
  // images are used by the implementation; gradients also work offline.
  static const landscapeUrl =
      'https://dimg.dreamflow.cloud/v1/image/dark%20landscape%20with%20distant%20mountains%20and%20sunset%20glow';

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      height: 340,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(.85, .12),
                radius: 1,
                colors: [Color(0xFF352338), OrbitHomeTokens.background],
                stops: [0, .9],
              ),
            ),
          ),
          Positioned(
            top: 112,
            left: 0,
            right: 0,
            height: 178,
            child: Opacity(
              opacity: .48,
              child: Image.network(
                landscapeUrl,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  OrbitHomeTokens.background,
                  Color(0xDD030B17),
                  Color(0x00030B17),
                  OrbitHomeTokens.background,
                ],
                stops: [0, .26, .57, 1],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class OrbitHomeAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;
  const OrbitHomeAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: const Color(0xFF29213E),
      child: Center(
        child: Text(
          name.trim().isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: TextStyle(
            color: OrbitHomeTokens.text,
            fontSize: size * .37,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    return Semantics(
      label: 'Perfil de $name',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: OrbitHomeTokens.border, width: 1.5),
        ),
        child: ClipOval(
          child: photoUrl?.trim().isNotEmpty == true
              ? Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : fallback,
                )
              : fallback,
        ),
      ),
    );
  }
}

class OrbitHomeHeader extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final String? partnerName;
  final String? partnerPhotoUrl;
  final bool valuesVisible;
  final bool hasPendingItems;
  final VoidCallback onPrivacy;
  final VoidCallback onNotifications;
  final VoidCallback? onProfile;
  final VoidCallback onWallets;
  const OrbitHomeHeader({
    super.key,
    required this.name,
    this.photoUrl,
    this.partnerName,
    this.partnerPhotoUrl,
    required this.valuesVisible,
    required this.hasPendingItems,
    required this.onPrivacy,
    required this.onNotifications,
    this.onProfile,
    required this.onWallets,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Semantics(
        button: true,
        label: 'Abrir configurações',
        child: InkWell(
          onTap: onProfile ?? onWallets,
          borderRadius: BorderRadius.circular(30),
          child: SizedBox(
            width: partnerName == null ? 43 : 59,
            height: 44,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (partnerName != null)
                  Positioned(
                    right: 0,
                    child: OrbitHomeAvatar(
                      name: partnerName!,
                      photoUrl: partnerPhotoUrl,
                      size: 36,
                    ),
                  ),
                OrbitHomeAvatar(name: name, photoUrl: photoUrl, size: 40),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      const Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OrbitMark(),
                  Text(
                    'rbit',
                    style: TextStyle(
                      color: OrbitHomeTokens.text,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.7,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Organize. Planeje. Conquiste.',
                style: TextStyle(
                  color: OrbitHomeTokens.muted,
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 6),
      SizedBox(
        width: 40,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: valuesVisible ? 'Ocultar valores' : 'Mostrar valores',
              onPressed: onPrivacy,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
              padding: EdgeInsets.zero,
              icon: Icon(
                valuesVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: OrbitHomeTokens.muted,
                size: 20,
              ),
            ),
            Stack(
              children: [
                IconButton(
                  tooltip: 'Ver pendências',
                  onPressed: onNotifications,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: OrbitHomeTokens.text,
                    size: 26,
                  ),
                ),
                if (hasPendingItems)
                  const Positioned(
                    top: 4,
                    right: 5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: OrbitHomeTokens.green,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 7, height: 7),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

class _OrbitMark extends StatelessWidget {
  const _OrbitMark();
  @override
  Widget build(BuildContext context) => Container(
    width: 33,
    height: 33,
    margin: const EdgeInsets.only(right: 2),
    padding: const EdgeInsets.all(6),
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: SweepGradient(
        colors: [
          Color(0xFFA77AFF),
          Color(0xFF9B57EA),
          Color(0xFF52B9DC),
          Color(0xFF4BFFA0),
          Color(0xFFA77AFF),
        ],
      ),
    ),
    child: const DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: OrbitHomeTokens.background,
      ),
    ),
  );
}

class OrbitHomeScopeSelector extends StatelessWidget {
  final bool shared;
  final VoidCallback onSolo;
  final VoidCallback onShared;
  const OrbitHomeScopeSelector({
    super.key,
    required this.shared,
    required this.onSolo,
    required this.onShared,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      color: OrbitHomeTokens.surface.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: OrbitHomeTokens.border),
    ),
    child: Row(
      children: [
        Expanded(
          child: _ScopeOption(
            label: 'Solo',
            icon: Icons.person_rounded,
            selected: !shared,
            onTap: onSolo,
          ),
        ),
        Expanded(
          child: _ScopeOption(
            label: 'Nós',
            icon: Icons.home_rounded,
            selected: shared,
            onTap: onShared,
          ),
        ),
      ],
    ),
  );
}

class _ScopeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ScopeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(25),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: selected ? OrbitHomeTokens.accentGradient : null,
          border: selected
              ? Border.all(color: OrbitHomeTokens.purple.withValues(alpha: .6))
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected
                      ? OrbitHomeTokens.text
                      : OrbitHomeTokens.muted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? OrbitHomeTokens.text
                        : OrbitHomeTokens.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class OrbitHomeNavigation extends StatelessWidget {
  final bool financeActive;
  final VoidCallback onHome;
  final VoidCallback onFinance;
  final VoidCallback onRoutines;
  final VoidCallback onAi;
  final VoidCallback? onCreate;
  const OrbitHomeNavigation({
    super.key,
    this.financeActive = false,
    required this.onHome,
    required this.onFinance,
    required this.onRoutines,
    required this.onAi,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final scaled = MediaQuery.textScalerOf(context).scale(11) > 16;
    final height = scaled ? 88.0 : 68.0;
    return SizedBox(
      height: height + 12 + bottom,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(top: 8, bottom: bottom + 5),
              height: height + bottom,
              decoration: BoxDecoration(
                color: OrbitHomeTokens.background.withValues(alpha: .98),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
                border: Border.all(color: OrbitHomeTokens.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _NavigationItem(
                      icon: Icons.home_rounded,
                      label: 'Início',
                      active: !financeActive,
                      onTap: onHome,
                    ),
                  ),
                  Expanded(
                    child: _NavigationItem(
                      icon: Icons.credit_card_rounded,
                      label: 'Finanças',
                      active: financeActive,
                      onTap: onFinance,
                    ),
                  ),
                  const SizedBox(width: 68),
                  Expanded(
                    child: _NavigationItem(
                      icon: Icons.edit_calendar_outlined,
                      label: 'Rotinas',
                      onTap: onRoutines,
                    ),
                  ),
                  Expanded(
                    child: _NavigationItem(
                      icon: Icons.auto_awesome_outlined,
                      label: 'IA',
                      onTap: onAi,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Semantics(
                button: true,
                label: 'Criar',
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: onCreate == null
                        ? null
                        : OrbitHomeTokens.greenGradient,
                    color: onCreate == null ? OrbitHomeTokens.border : null,
                    boxShadow: [
                      BoxShadow(
                        color: OrbitHomeTokens.green.withValues(alpha: .12),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onCreate,
                      customBorder: const CircleBorder(),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 32,
                        color: OrbitHomeTokens.background,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavigationItem({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    selected: active,
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 25,
            color: active ? OrbitHomeTokens.green : OrbitHomeTokens.muted,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              height: 1.2,
              fontSize: 10,
              color: active ? OrbitHomeTokens.green : OrbitHomeTokens.muted,
            ),
          ),
          const SizedBox(height: 0),
          Container(
            height: 2,
            width: 28,
            decoration: BoxDecoration(
              color: active ? OrbitHomeTokens.green : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    ),
  );
}
