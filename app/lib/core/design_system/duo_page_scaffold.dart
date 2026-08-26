import 'package:flutter/material.dart';

import 'duo_colors.dart';

/// Shared shell for Orbit screens. It owns visual chrome only; feature pages
/// keep their controllers, navigation and domain behaviour.
class DuoPageScaffold extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final List<Widget> actions;
  final Widget body;
  final Widget? bottomNavigationBar;
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  const DuoPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.eyebrow,
    this.actions = const [],
    this.bottomNavigationBar,
    this.scrollable = true,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 32),
  });

  @override
  Widget build(BuildContext context) {
    final content = scrollable
        ? SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: padding,
            child: body,
          )
        : Padding(padding: padding, child: body);

    return Scaffold(
      backgroundColor: DuoColors.background,
      appBar: AppBar(
        backgroundColor: DuoColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (eyebrow != null)
              Text(
                eyebrow!.toUpperCase(),
                style: const TextStyle(
                  color: DuoColors.primaryLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            Text(
              title,
              style: const TextStyle(
                color: DuoColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -.35,
              ),
            ),
          ],
        ),
        actions: actions,
      ),
      body: SafeArea(top: false, child: content),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
