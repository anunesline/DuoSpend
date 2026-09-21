import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../data/repositories/firestore_consumption_event_repository.dart';
import '../../domain/interactions/consumption_interaction.dart';
import '../controllers/orbit_intelligence_controller.dart';
import '../../../../shared/knowledge/products/product_repository.dart';
import '../../../household_routines/data/repositories/firestore_household_list_repository.dart';
import '../../../household_routines/domain/services/intelligent_shopping_list_service.dart';

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
        )..load());
  }

  @override
  void dispose() {
    if (_ownsController) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, _) => Scaffold(
      backgroundColor: DuoColors.background,
      appBar: AppBar(title: const Text('Orbit IA')),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.errorMessage != null
          ? Center(
              child: ElevatedButton(
                onPressed: controller.load,
                child: const Text('Tentar novamente'),
              ),
            )
          : _content(),
    ),
  );

  Widget _content() {
    if (controller.entries.isEmpty ||
        (controller.actions.isEmpty &&
            controller.insights.isEmpty &&
            controller.learned.isEmpty)) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'O Orbit ainda está aprendendo seu ritmo.\nQuanto mais compras reais forem registradas, mais padrões poderão aparecer aqui.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (controller.actions.isNotEmpty) ...[
          const _Heading('O que precisa de mim?'),
          ...controller.actions.map(_actionCard),
        ],
        if (controller.insights.isNotEmpty) ...[
          const _Heading('O que o Orbit percebeu?'),
          ...controller.insights.map(_insightCard),
        ],
        if (controller.learned.isNotEmpty) ...[
          const _Heading('O que o Orbit aprendeu?'),
          ...controller.learned.map(_learnedCard),
        ],
      ],
    );
  }

  Widget _actionCard(OrbitIntelligenceEntry entry) {
    final interaction = entry.interaction!;
    final question = switch (interaction.type) {
      ConsumptionInteractionType.confirmStock =>
        'Ainda tem ${entry.productName}?',
      ConsumptionInteractionType.offerAddToShoppingList =>
        'Quer colocar ${entry.productName} na lista de compras?',
      ConsumptionInteractionType.confirmExceptionalPurchase =>
        'Essa compra foi fora do seu padrão?',
      ConsumptionInteractionType.acknowledgePriceOpportunity =>
        'O Orbit percebeu uma oportunidade de preço.',
    };
    return DuoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(_detail(entry)),
          if (interaction.type ==
              ConsumptionInteractionType.offerAddToShoppingList)
            OutlinedButton(
              onPressed: () => _addToList(entry),
              child: const Text('Adicionar à lista'),
            ),
          if (interaction.allowedResponses.isNotEmpty)
            Wrap(
              spacing: 8,
              children: [
                for (final response in interaction.allowedResponses.take(3))
                  OutlinedButton(
                    onPressed: () => controller.respond(interaction, response),
                    child: Text(_responseLabel(response)),
                  ),
              ],
            ),
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

  Widget _insightCard(OrbitIntelligenceEntry entry) => DuoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Você pagou menos que o habitual em ${entry.productName}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(_detail(entry)),
      ],
    ),
  );

  Widget _learnedCard(OrbitIntelligenceEntry entry) => DuoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.productName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(_detail(entry)),
      ],
    ),
  );

  String _detail(OrbitIntelligenceEntry entry) {
    final metrics = entry.result.metrics;
    final days = metrics.averagePurchaseInterval?.inDays;
    final price = metrics.averageUnitPrice;
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final parts = <String>[];
    if (days != null) parts.add('Compra normalmente a cada ~$days dias');
    if (price != null) parts.add('Preço habitual: ${currency.format(price)}');
    if (parts.isEmpty) return 'Baseado no histórico registrado pelo Orbit.';
    return parts.join(' · ');
  }

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

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    ),
  );
}
