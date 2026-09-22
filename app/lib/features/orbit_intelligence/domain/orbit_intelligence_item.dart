import '../../consumption/domain/interactions/consumption_interaction.dart';
import '../../consumption/presentation/controllers/orbit_intelligence_controller.dart';
import '../../financial_intelligence/domain/signals/financial_signals.dart';
import '../../financial_intelligence/domain/facts/financial_facts.dart';

enum OrbitIntelligenceDomain { consumption, financial }

enum OrbitIntelligenceKind { action, insight, learned }

enum OrbitPresentationPriority { primary, secondary, tertiary }

class OrbitIntelligenceScope {
  const OrbitIntelligenceScope({
    required this.id,
    required this.domain,
    this.walletScope,
  });
  final String id;
  final OrbitIntelligenceDomain domain;
  final FinancialWalletScope? walletScope;
}

class OrbitIntelligenceAction {
  const OrbitIntelligenceAction({required this.id, this.payload});
  final String id;
  final Object? payload;
}

class OrbitIntelligenceContent {
  const OrbitIntelligenceContent({required this.title, required this.detail});
  final String title;
  final String detail;
}

class OrbitIntelligenceItem {
  const OrbitIntelligenceItem({
    required this.id,
    required this.dedupeKey,
    required this.domain,
    required this.kind,
    required this.priority,
    required this.scope,
    required this.content,
    required this.source,
    this.action,
  });

  final String id;
  final String dedupeKey;
  final OrbitIntelligenceDomain domain;
  final OrbitIntelligenceKind kind;
  final OrbitPresentationPriority priority;
  final OrbitIntelligenceScope scope;
  final OrbitIntelligenceContent content;
  final OrbitIntelligenceAction? action;
  final Object source;
}

class ConsumptionCentralAdapter {
  const ConsumptionCentralAdapter();

  List<OrbitIntelligenceItem> adapt(Iterable<OrbitIntelligenceEntry> entries) {
    final items = <OrbitIntelligenceItem>[];
    for (final entry in entries) {
      final interaction = entry.interaction;
      if (interaction != null) {
        final kind =
            interaction.type ==
                ConsumptionInteractionType.acknowledgePriceOpportunity
            ? OrbitIntelligenceKind.insight
            : OrbitIntelligenceKind.action;
        items.add(
          OrbitIntelligenceItem(
            id: '${interaction.id}:${kind.name}',
            dedupeKey: 'consumption:${interaction.id}:${kind.name}',
            domain: OrbitIntelligenceDomain.consumption,
            kind: kind,
            priority: interaction.priority >= 90
                ? OrbitPresentationPriority.primary
                : interaction.priority >= 30
                ? OrbitPresentationPriority.secondary
                : OrbitPresentationPriority.tertiary,
            scope: OrbitIntelligenceScope(
              id: interaction.scopeId,
              domain: OrbitIntelligenceDomain.consumption,
            ),
            content: OrbitIntelligenceContent(
              title: entry.productName,
              detail: entry.productName,
            ),
            action: kind == OrbitIntelligenceKind.action
                ? OrbitIntelligenceAction(
                    id: interaction.id,
                    payload: interaction,
                  )
                : null,
            source: entry,
          ),
        );
      }
      if (entry.result.metrics.probableRecurrence != null) {
        items.add(
          OrbitIntelligenceItem(
            id: '${entry.productId}:learned',
            dedupeKey: 'consumption:${entry.productId}:learned',
            domain: OrbitIntelligenceDomain.consumption,
            kind: OrbitIntelligenceKind.learned,
            priority: OrbitPresentationPriority.tertiary,
            scope: OrbitIntelligenceScope(
              id: entry.result.scopeId,
              domain: OrbitIntelligenceDomain.consumption,
            ),
            content: OrbitIntelligenceContent(
              title: entry.productName,
              detail: entry.productName,
            ),
            source: entry,
          ),
        );
      }
    }
    return List.unmodifiable(items);
  }
}

class FinancialCentralAdapter {
  const FinancialCentralAdapter();

  List<OrbitIntelligenceItem> adapt(Iterable<FinancialSignal> signals) =>
      List.unmodifiable(signals.map(_adapt));

  OrbitIntelligenceItem _adapt(FinancialSignal signal) {
    final label = _label(signal);
    return OrbitIntelligenceItem(
      id: 'financial:${signal.dedupeKey}',
      dedupeKey: 'financial:${signal.dedupeKey}',
      domain: OrbitIntelligenceDomain.financial,
      kind: OrbitIntelligenceKind.insight,
      priority: signal.type == FinancialSignalType.invoiceOverdue
          ? OrbitPresentationPriority.primary
          : signal.type == FinancialSignalType.invoiceDue ||
                signal.type == FinancialSignalType.budgetExceeded
          ? OrbitPresentationPriority.secondary
          : OrbitPresentationPriority.tertiary,
      scope: OrbitIntelligenceScope(
        id: signal.walletId,
        domain: OrbitIntelligenceDomain.financial,
        walletScope: signal.walletScope,
      ),
      content: OrbitIntelligenceContent(title: label.$1, detail: label.$2),
      source: signal,
    );
  }

  (String, String) _label(FinancialSignal signal) {
    final percentage = signal.percentageDifference?.abs();
    final value = percentage == null
        ? signal.absoluteDifference?.abs().toStringAsFixed(2)
        : '${(percentage * 100).toStringAsFixed(1)}%';
    final suffix = value == null ? '' : ' (${signal.direction.name}: $value)';
    return switch (signal.type) {
      FinancialSignalType.spendingChanged => (
        'Seus gastos mudaram',
        'Variação identificada$suffix.',
      ),
      FinancialSignalType.incomeChanged => (
        'Sua renda mudou',
        'Variação identificada$suffix.',
      ),
      FinancialSignalType.cashFlowChanged => (
        'Seu fluxo de caixa mudou',
        'Variação identificada$suffix.',
      ),
      FinancialSignalType.categorySpendingChanged => (
        'Gastos por categoria mudaram',
        '${signal.category ?? 'Categoria'}$suffix.',
      ),
      FinancialSignalType.cardSpendingChanged => (
        'Gastos no cartão mudaram',
        'Cartão ${signal.cardId ?? ''}$suffix.',
      ),
      FinancialSignalType.budgetExceeded => (
        'Orçamento excedido',
        '${signal.category ?? 'Categoria'} ultrapassou o limite.',
      ),
      FinancialSignalType.knownCommitment => (
        'Compromissos conhecidos',
        'Há compromissos financeiros no período.',
      ),
      FinancialSignalType.invoiceDue => (
        'Fatura próxima',
        'Uma fatura em aberto está próxima do vencimento.',
      ),
      FinancialSignalType.invoiceOverdue => (
        'Fatura vencida',
        'Uma fatura em aberto está vencida.',
      ),
    };
  }
}

class OrbitIntelligenceOrchestrator {
  const OrbitIntelligenceOrchestrator();

  List<OrbitIntelligenceItem> build({
    Iterable<OrbitIntelligenceItem> consumption = const [],
    Iterable<OrbitIntelligenceItem> financial = const [],
  }) {
    final byKey = <String, OrbitIntelligenceItem>{};
    for (final item in [...consumption, ...financial]) {
      byKey.putIfAbsent(item.dedupeKey, () => item);
    }
    final result = byKey.values.toList()
      ..sort((a, b) {
        final priority = a.priority.index.compareTo(b.priority.index);
        if (priority != 0) return priority;
        final domain = a.domain.index.compareTo(b.domain.index);
        if (domain != 0) return domain;
        return a.dedupeKey.compareTo(b.dedupeKey);
      });
    return List.unmodifiable(result);
  }
}
