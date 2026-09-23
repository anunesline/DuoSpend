import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../home/presentation/widgets/orbit_home_primitives.dart';
import '../../data/repositories/firestore_consumption_event_repository.dart';
import '../../domain/interactions/consumption_interaction.dart';
import '../controllers/orbit_intelligence_controller.dart';
import '../../../../shared/knowledge/products/product_repository.dart';
import '../../../household_routines/data/repositories/firestore_household_list_repository.dart';
import '../../../household_routines/domain/services/intelligent_shopping_list_service.dart';
import '../../../orbit_intelligence/domain/orbit_intelligence_item.dart';

class OrbitIntelligencePage extends StatefulWidget {
  const OrbitIntelligencePage({
    super.key,
    required this.userId,
    required this.scopeId,
    required this.products,
    this.controller,
  });
  final String userId;
  final String scopeId;
  final ProductRepository products;

  /// Allows the presentation to be exercised with an already controlled state.
  /// Production callers leave this null and retain the Firestore-backed flow.
  final OrbitIntelligenceController? controller;
  @override
  State<OrbitIntelligencePage> createState() => _OrbitIntelligencePageState();
}

class _OrbitIntelligencePageState extends State<OrbitIntelligencePage> {
  late final OrbitIntelligenceController controller;
  late final bool _ownsController;
  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    controller =
        widget.controller ??
        (OrbitIntelligenceController(
          userId: widget.userId,
          scopeId: widget.scopeId,
          products: widget.products,
          events: FirestoreConsumptionEventRepository(),
        ));
    controller.addListener(_markPresentedWhenLoaded);
    if (_ownsController) _initialize();
  }

  Future<void> _initialize() async {
    await controller.loadPersonality();
    await controller.load();
  }

  void _markPresentedWhenLoaded() {
    if (!controller.isLoading &&
        controller.errorMessage == null &&
        controller.centralItems.isNotEmpty) {
      controller.markCentralItemsPresented();
    }
  }

  @override
  void dispose() {
    controller.removeListener(_markPresentedWhenLoaded);
    if (_ownsController) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, _) => Scaffold(
      backgroundColor: OrbitHomeTokens.background,
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: 12,
        title: const Row(
          children: [
            OrbitHomeIcon(
              icon: Icons.auto_awesome_rounded,
              color: OrbitHomeTokens.purple,
              size: 38,
            ),
            SizedBox(width: 12),
            Text('IA'),
          ],
        ),
        backgroundColor: OrbitHomeTokens.background,
        foregroundColor: OrbitHomeTokens.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: OrbitHomeTokens.text,
          fontSize: 30,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: DefaultTextStyle.merge(
        style: const TextStyle(
          color: OrbitHomeTokens.muted,
          fontSize: 15,
          height: 1.45,
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _CentralBackdrop()),
            Positioned.fill(
              child: controller.isLoading
                  ? const _StatusCard(
                      icon: Icons.auto_awesome_rounded,
                      message: 'O Orbit está reunindo seus aprendizados.',
                      loading: true,
                    )
                  : controller.errorMessage != null
                  ? _StatusCard(
                      icon: Icons.cloud_off_rounded,
                      message: controller.errorMessage!,
                      action: OutlinedButton(
                        onPressed: controller.load,
                        style: _buttonStyle(),
                        child: const Text('Tentar novamente'),
                      ),
                    )
                  : _content(),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _content() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        const _Introduction(),
        const _Heading('O que precisa de mim?'),
        if (controller.centralActions.isEmpty)
          const _InformativeCard(
            icon: Icons.inventory_2_outlined,
            color: OrbitHomeTokens.purple,
            title: 'Nada por enquanto',
            message:
                'Quando o Orbit precisar confirmar algo com você — como se um produto acabou ou se uma compra foi fora do padrão — vai aparecer aqui.',
          )
        else
          ...controller.centralActions.map(_centralCard),
        const _Heading('O que o Orbit percebeu?'),
        if (controller.centralInsights.isEmpty)
          const _InformativeCard(
            icon: Icons.visibility_outlined,
            color: OrbitHomeTokens.green,
            title: 'Ainda observando suas compras',
            message:
                'Conforme seu histórico crescer, o Orbit poderá perceber mudanças de preço, oportunidades e compras fora do seu padrão.',
          )
        else
          ...controller.centralInsights.map(_centralCard),
        const _Heading('O que o Orbit aprendeu?'),
        if (controller.centralLearned.isEmpty)
          const _InformativeCard(
            icon: Icons.repeat_rounded,
            color: OrbitHomeTokens.cyan,
            title: 'Construindo sua memória de consumo',
            message:
                'Com compras recorrentes, o Orbit começa a entender seu ritmo, frequência e padrões de consumo.',
          )
        else
          ...controller.centralLearned.map(_centralCard),
      ],
    );
  }

  Widget _centralCard(OrbitIntelligenceItem item) {
    if (item.domain == OrbitIntelligenceDomain.financial) {
      return _CentralCard(
        child: _CardLead(
          icon: Icons.account_balance_wallet_outlined,
          color: OrbitHomeTokens.green,
          title: item.content.title,
          child: Text(item.content.detail),
        ),
      );
    }
    final entry = item.source as OrbitIntelligenceEntry;
    return switch (item.kind) {
      OrbitIntelligenceKind.action => _actionCard(item, entry),
      OrbitIntelligenceKind.insight => _insightCard(item, entry),
      OrbitIntelligenceKind.learned => _learnedCard(item, entry),
    };
  }

  Widget _actionCard(OrbitIntelligenceItem item, OrbitIntelligenceEntry entry) {
    final interaction = entry.interaction!;
    final responses = interaction.allowedResponses.take(3).toList();
    return _CentralCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardLead(
            icon: Icons.inventory_2_outlined,
            color: OrbitHomeTokens.purple,
            title: item.content.title,
            child: Text(item.content.detail),
          ),
          if (interaction.type ==
              ConsumptionInteractionType.offerAddToShoppingList) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _addToList(entry),
                style: _buttonStyle(primary: true),
                child: const Text(
                  'Adicionar à lista',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
          if (responses.isNotEmpty) ...[
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
                final inline =
                    constraints.maxWidth >= responses.length * 108 * scale;
                final width = inline
                    ? (constraints.maxWidth - (responses.length - 1) * 8) /
                          responses.length
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final response in responses)
                      SizedBox(
                        width: width,
                        child: OutlinedButton(
                          onPressed: () =>
                              controller.respond(interaction, response),
                          style: _buttonStyle(
                            primary:
                                response ==
                                    ConsumptionInteractionResponse.finished ||
                                response ==
                                    ConsumptionInteractionResponse
                                        .confirmExceptionalPurchase,
                          ),
                          child: Text(
                            _responseLabel(response),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addToList(OrbitIntelligenceEntry entry) async {
    final item =
        await IntelligentShoppingListService(
          FirestoreHouseholdListRepository(),
        ).addKnownProduct(
          scopeId: widget.scopeId,
          productId: entry.productId,
          displayName: entry.productName,
          addedBy: widget.userId,
          at: DateTime.now(),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          item == null
              ? 'Não foi possível adicionar à lista agora.'
              : 'Adicionado à lista.',
        ),
      ),
    );
  }

  Widget _insightCard(
    OrbitIntelligenceItem item,
    OrbitIntelligenceEntry entry,
  ) {
    final metrics = entry.result.metrics;
    return _CentralCard(
      child: _CardLead(
        icon: Icons.shopping_cart_outlined,
        color: OrbitHomeTokens.green,
        title: item.content.title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (metrics.lastUnitPrice != null)
              Text(
                orbitMoney(metrics.lastUnitPrice!),
                style: const TextStyle(
                  color: OrbitHomeTokens.green,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            Text(item.content.detail),
          ],
        ),
      ),
    );
  }

  Widget _learnedCard(
    OrbitIntelligenceItem item,
    OrbitIntelligenceEntry entry,
  ) => _CentralCard(
    child: _CardLead(
      icon: Icons.repeat_rounded,
      color: OrbitHomeTokens.cyan,
      title: item.content.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.content.detail),
          if (entry.result.metrics.lastPurchase != null)
            Text(
              'Última compra: ${DateFormat('dd/MM/yyyy').format(entry.result.metrics.lastPurchase!.purchasedAt)}',
            ),
        ],
      ),
    ),
  );

  String _responseLabel(ConsumptionInteractionResponse response) =>
      switch (response) {
        ConsumptionInteractionResponse.stillHave => 'Ainda tenho',
        ConsumptionInteractionResponse.finished => 'Acabou',
        ConsumptionInteractionResponse.externalPurchase => 'Comprei fora',
        ConsumptionInteractionResponse.discontinued => 'Não consumo mais',
        ConsumptionInteractionResponse.pause => 'Pausar',
        ConsumptionInteractionResponse.confirmExceptionalPurchase =>
          'Confirmar',
      };
}

ButtonStyle _buttonStyle({bool primary = false}) => OutlinedButton.styleFrom(
  foregroundColor: OrbitHomeTokens.text,
  backgroundColor: primary ? const Color(0xFF782ADD) : Colors.transparent,
  side: BorderSide(
    color: primary ? OrbitHomeTokens.purple : const Color(0xFF77689E),
  ),
  minimumSize: const Size(48, 48),
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
);

/// Decorative only: full-viewport gradients avoid a cropped network banner.
class _CentralBackdrop extends StatelessWidget {
  const _CentralBackdrop();
  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(1, -.85),
          radius: 1.25,
          colors: [Color(0xFF282039), OrbitHomeTokens.background],
          stops: [0, 1],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              OrbitHomeTokens.background,
              Color(0x00030B17),
              Color(0x99030B17),
              OrbitHomeTokens.background,
            ],
            stops: [0, .18, .6, 1],
          ),
        ),
      ),
    ),
  );
}

/// Section-local explanation; never becomes a controller entry or an action.
class _InformativeCard extends StatelessWidget {
  const _InformativeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => _CentralCard(
    child: _CardLead(
      icon: icon,
      color: color,
      title: title,
      child: Text(message),
    ),
  );
}

class _Introduction extends StatelessWidget {
  const _Introduction();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 4, bottom: 16),
    child: Text(
      'O Orbit aprende com sua rotina e seu dinheiro.',
      style: TextStyle(
        color: OrbitHomeTokens.text,
        fontSize: 18,
        height: 1.5,
        fontWeight: FontWeight.w400,
        letterSpacing: .15,
      ),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 12),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(
          color: OrbitHomeTokens.text,
          fontSize: 21,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _CentralCard extends StatelessWidget {
  const _CentralCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: OrbitHomeSurface(
      padding: const EdgeInsets.all(16),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          color: OrbitHomeTokens.muted,
          fontSize: 15,
          height: 1.45,
        ),
        child: child,
      ),
    ),
  );
}

class _CardLead extends StatelessWidget {
  const _CardLead({
    required this.icon,
    required this.color,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final Color color;
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExcludeSemantics(
        child: OrbitHomeIcon(icon: icon, color: color, size: 46),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: OrbitHomeTokens.text,
                fontSize: 17,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    ],
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.message,
    this.loading = false,
    this.action,
  });
  final IconData icon;
  final String message;
  final bool loading;
  final Widget? action;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Introduction(),
        const SizedBox(height: 24),
        _CentralCard(
          child: Column(
            children: [
              OrbitHomeIcon(
                icon: icon,
                color: OrbitHomeTokens.purple,
                size: 64,
              ),
              const SizedBox(height: 20),
              Text(message, textAlign: TextAlign.center),
              if (loading) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(color: OrbitHomeTokens.purple),
              ],
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ],
    ),
  );
}
