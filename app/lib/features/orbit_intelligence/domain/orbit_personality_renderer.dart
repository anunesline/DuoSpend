import 'package:intl/intl.dart';

import '../../consumption/domain/intelligence/consumption_intelligence_engine.dart';
import '../../consumption/domain/interactions/consumption_interaction.dart';
import '../../consumption/presentation/controllers/orbit_intelligence_controller.dart';
import '../../financial_intelligence/domain/facts/financial_facts.dart';
import '../../financial_intelligence/domain/signals/financial_signals.dart';
import 'orbit_intelligence_item.dart';
import 'orbit_personality.dart';

class OrbitPersonalityRenderResult {
  const OrbitPersonalityRenderResult({
    required this.content,
    required this.factType,
    required this.family,
    required this.variantId,
  });
  final OrbitIntelligenceContent content;
  final String factType;
  final String family;
  final String variantId;
}

/// Pure local presentation: it reads structured facts and never changes them.
class OrbitPersonalityRenderer {
  const OrbitPersonalityRenderer();

  OrbitPersonalityRenderResult render({
    required OrbitIntelligenceItem item,
    required OrbitPersonality? personality,
    List<String> recentVariantIds = const [],
  }) {
    if (personality == null) return _fallback(item);
    final draft = item.source is FinancialSignal
        ? _financial(item.source as FinancialSignal, personality)
        : item.source is OrbitIntelligenceEntry
        ? _consumption(item, item.source as OrbitIntelligenceEntry, personality)
        : null;
    if (draft == null) return _fallback(item);
    final variants = draft.variants;
    final selected = _select(
      variants: variants,
      recent: recentVariantIds,
      seed: '${item.id}|${personality.name}|${draft.factType}|${draft.family}',
    );
    return OrbitPersonalityRenderResult(
      content: OrbitIntelligenceContent(
        title: selected.$2,
        detail: draft.detail,
      ),
      factType: draft.factType,
      family: draft.family,
      variantId: selected.$1,
    );
  }

  OrbitPersonalityRenderResult _fallback(OrbitIntelligenceItem item) =>
      OrbitPersonalityRenderResult(
        content: item.content,
        factType: 'fallback',
        family: 'factual',
        variantId: 'factual',
      );

  _Draft? _financial(FinancialSignal signal, OrbitPersonality p) {
    final tone = switch (signal.type) {
      FinancialSignalType.invoiceOverdue => OrbitToneFreedom.factual,
      FinancialSignalType.invoiceDue ||
      FinancialSignalType.knownCommitment => OrbitToneFreedom.restrained,
      _ => OrbitToneFreedom.normal,
    };
    if (!{
      FinancialSignalType.spendingChanged,
      FinancialSignalType.incomeChanged,
      FinancialSignalType.cashFlowChanged,
      FinancialSignalType.budgetExceeded,
      FinancialSignalType.knownCommitment,
      FinancialSignalType.invoiceDue,
      FinancialSignalType.invoiceOverdue,
    }.contains(signal.type))
      return null;
    if (signal.type == FinancialSignalType.invoiceDue ||
        signal.type == FinancialSignalType.invoiceOverdue) {
      final date = signal.dueDate == null
          ? ''
          : ' em ${DateFormat('dd/MM/yyyy').format(signal.dueDate!)}';
      final overdue = signal.type == FinancialSignalType.invoiceOverdue;
      final title = overdue
          ? 'Uma fatura está vencida.'
          : 'Uma fatura vence em breve.';
      return _Draft(
        factType: signal.type.name,
        family: 'invoice',
        detail: overdue
            ? 'A fatura em aberto venceu$date.'
            : 'Há uma fatura em aberto com vencimento$date.',
        variants: [('base', title)],
      );
    }
    if (signal.type == FinancialSignalType.knownCommitment) {
      final until = signal.commitmentRangeEnd == null
          ? ''
          : ' até ${DateFormat('dd/MM/yyyy').format(signal.commitmentRangeEnd!)}';
      return _Draft(
        factType: signal.type.name,
        family: 'commitment',
        detail: 'Há compromissos financeiros conhecidos$until.',
        variants: _voice(
          p,
          tone,
          factual: 'Compromissos financeiros no período.',
          restrained: 'Olha os compromissos financeiros deste período.',
        ),
      );
    }
    if (signal.type == FinancialSignalType.budgetExceeded) {
      if (signal.currentValue == null ||
          signal.comparisonValue == null ||
          signal.absoluteDifference == null)
        return null;
      final category = signal.category == null
          ? 'O orçamento'
          : 'O orçamento de ${signal.category}';
      final limit = _money(signal.comparisonValue!);
      final consumed = _money(signal.currentValue!);
      final excess = _money(signal.absoluteDifference!.abs());
      return _Draft(
        factType: signal.type.name,
        family: 'budget',
        detail:
            '$category era $limit. Foram gastos $consumed: $excess acima do limite.',
        variants: _voice(
          p,
          tone,
          factual: '$category passou $excess.',
          mother: 'Olha… $category passou $excess. Vamos cuidar disso.',
          sarcastic: '$category era $limit. Entendeu como sugestão.',
          julius: '$excess ACIMA DO ORÇAMENTO!',
          motivator:
              '$category passou $excess. Vale acompanhar para não aumentar essa diferença.',
        ),
      );
    }
    if (signal.absoluteDifference == null ||
        (signal.direction != FinancialSignalDirection.increase &&
            signal.direction != FinancialSignalDirection.decrease))
      return null;
    final noun = switch (signal.type) {
      FinancialSignalType.spendingChanged => 'gastos',
      FinancialSignalType.incomeChanged => 'renda',
      FinancialSignalType.cashFlowChanged => 'fluxo de caixa',
      _ => '',
    };
    if (noun.isEmpty) return null;
    final subject = signal.walletScope == FinancialWalletScope.sharedWallet
        ? 'Vocês'
        : 'Seus';
    final value = _money(signal.absoluteDifference!.abs());
    final increased = signal.direction == FinancialSignalDirection.increase;
    final verb = increased ? 'aumentaram' : 'caíram';
    final percentage = signal.percentageDifference == null
        ? ''
        : ' Isso representa ${(signal.percentageDifference!.abs() * 100).toStringAsFixed(1)}%.';
    final base = '$subject $noun $verb $value neste período.';
    return _Draft(
      factType: signal.type.name,
      family: increased ? 'increase' : 'decrease',
      detail: '$base$percentage',
      variants: _voice(
        p,
        tone,
        factual: base,
        mother: increased ? 'Olha… $base Vamos cuidar disso.' : 'Viu? $base',
        sarcastic: increased
            ? '$value a mais nos $noun. O número não se distraiu.'
            : 'Olha só: $value a menos nos $noun.',
        julius: increased
            ? '$value A MAIS NOS $noun!'
            : '$value A MENOS NOS $noun!',
        motivator: increased
            ? base
            : 'Boa! $base Essa mudança apareceu nos números.',
      ),
    );
  }

  _Draft? _consumption(
    OrbitIntelligenceItem item,
    OrbitIntelligenceEntry entry,
    OrbitPersonality p,
  ) {
    final interaction = entry.interaction;
    final signals = interaction?.signals ?? const <ConsumptionSignalType>[];
    if (item.kind == OrbitIntelligenceKind.learned &&
        entry.result.metrics.probableRecurrence != null) {
      final days =
          entry.result.metrics.probableRecurrence!.averageInterval.inDays;
      final detail =
          'O histórico registrado indica uma compra a cada cerca de $days dias.';
      return _Draft(
        factType: 'learnedRecurrence',
        family: 'recurrence',
        detail: detail,
        variants: _voice(
          p,
          OrbitToneFreedom.normal,
          factual: 'Recorrência registrada para ${entry.productName}.',
          mother: 'Olha… $detail',
          motivator: 'Olha isso 👀✨ $detail',
        ),
      );
    }
    if (interaction?.type ==
            ConsumptionInteractionType.offerAddToShoppingList &&
        interaction?.state == ConsumptionState.finishedConfirmed) {
      return _Draft(
        factType: 'finishedConfirmed',
        family: 'finished',
        detail: 'O produto foi confirmado como acabado.',
        variants: _voice(
          p,
          OrbitToneFreedom.normal,
          factual: '${entry.productName} acabou.',
          mother: 'Meu bem, ${entry.productName} acabou. Vamos cuidar disso.',
          sarcastic: '${entry.productName} saiu oficialmente de cena.',
          julius: '${entry.productName} ACABOU.',
          motivator:
              '${entry.productName} acabou. Já dá para organizar a reposição.',
        ),
      );
    }
    if (interaction?.type == ConsumptionInteractionType.confirmStock &&
        signals.contains(ConsumptionSignalType.repurchaseOverdue)) {
      final detail =
          'O histórico registrado indica que pode ser hora de conferir ${entry.productName}.';
      return _Draft(
        factType: 'repurchaseOverdue',
        family: 'repurchase',
        detail: detail,
        variants: _voice(
          p,
          OrbitToneFreedom.restrained,
          factual: 'Confira o estoque de ${entry.productName}.',
          mother: 'Olha… vale conferir ${entry.productName}.',
          motivator: detail,
        ),
      );
    }
    if (signals.contains(ConsumptionSignalType.priceBelowUsual) ||
        signals.contains(ConsumptionSignalType.newLowestPrice)) {
      final last = entry.result.metrics.lastUnitPrice;
      final detail = last == null
          ? 'O histórico registrado mostra um preço favorável para ${entry.productName}.'
          : 'O histórico registrado mostra ${entry.productName} por ${_money(last)}.';
      return _Draft(
        factType: signals.contains(ConsumptionSignalType.newLowestPrice)
            ? 'newLowestPrice'
            : 'priceBelowUsual',
        family: 'price',
        detail: detail,
        variants: _voice(
          p,
          OrbitToneFreedom.normal,
          factual: 'Preço favorável para ${entry.productName}.',
          mother: 'Viu? $detail',
          sarcastic: '${entry.productName} resolveu colaborar com o orçamento.',
          julius: 'PREÇO FAVORÁVEL PARA ${entry.productName.toUpperCase()}!',
          motivator: 'Boa! $detail',
        ),
      );
    }
    return null;
  }

  List<(String, String)> _voice(
    OrbitPersonality p,
    OrbitToneFreedom tone, {
    required String factual,
    String? mother,
    String? sarcastic,
    String? julius,
    String? motivator,
    String? restrained,
  }) {
    if (tone == OrbitToneFreedom.factual) return [('factual', factual)];
    final value = switch (p) {
      OrbitPersonality.mother => mother,
      OrbitPersonality.sarcastic => sarcastic,
      OrbitPersonality.julius => julius,
      OrbitPersonality.motivator => motivator,
      OrbitPersonality.sincere => factual,
    };
    return [('one', value ?? restrained ?? factual), ('two', factual)];
  }

  (String, String) _select({
    required List<(String, String)> variants,
    required List<String> recent,
    required String seed,
  }) {
    final rotated = List<(String, String)>.from(variants);
    final index = _hash(seed) % rotated.length;
    final ordered = [...rotated.skip(index), ...rotated.take(index)];
    for (final variant in ordered) {
      if (!recent.contains(variant.$1)) return variant;
    }
    return variants.reduce(
      (least, candidate) =>
          recent.indexOf(candidate.$1) < recent.indexOf(least.$1)
          ? candidate
          : least,
    );
  }

  int _hash(String value) {
    var hash = 2166136261;
    for (final unit in value.codeUnits) {
      hash = (hash ^ unit) * 16777619 & 0x7fffffff;
    }
    return hash;
  }

  String _money(double value) =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
}

class _Draft {
  const _Draft({
    required this.factType,
    required this.family,
    required this.detail,
    required this.variants,
  });
  final String factType;
  final String family;
  final String detail;
  final List<(String, String)> variants;
}
