import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/financial_intelligence/domain/comparison/financial_comparison.dart';
import 'package:app/features/financial_intelligence/domain/facts/financial_facts.dart';
import 'package:app/features/financial_intelligence/domain/signals/financial_signals.dart';
import 'package:app/features/orbit_intelligence/data/orbit_personality_preferences.dart';
import 'package:app/features/orbit_intelligence/domain/orbit_intelligence_item.dart';
import 'package:app/features/orbit_intelligence/domain/orbit_personality.dart';
import 'package:app/features/orbit_intelligence/domain/orbit_personality_renderer.dart';

void main() {
  const renderer = OrbitPersonalityRenderer();

  test('same structured budget fact keeps its values in five voices', () {
    final signal = _budget();
    final item = _item(signal);
    for (final personality in OrbitPersonality.values) {
      final rendered = renderer.render(item: item, personality: personality);
      expect(rendered.content.detail, contains('R\$ 500,00'));
      expect(rendered.content.detail, contains('R\$ 648,00'));
      expect(rendered.content.detail, contains('R\$ 148,00'));
    }
    expect(item.source, same(signal));
  });

  test('comparative direction and absent percentage are preserved', () {
    final signal = _comparative(direction: FinancialSignalDirection.decrease);
    final rendered = renderer.render(
      item: _item(signal),
      personality: OrbitPersonality.sincere,
    );
    expect(rendered.content.detail, contains('caíram'));
    expect(rendered.content.detail, isNot(contains('%')));
  });

  test('overdue invoice neither invents an amount nor jokes', () {
    final signal = FinancialSignal(
      type: FinancialSignalType.invoiceOverdue,
      direction: FinancialSignalDirection.overdue,
      reason: FinancialSignalReason.invoiceOverdue,
      evidence: FinancialSignalEvidence.currentState,
      dedupeKey: 'invoice',
      walletId: 'w',
      walletScope: FinancialWalletScope.sharedWallet,
      period: _period(),
      dueDate: DateTime(2026, 9, 1),
    );
    final rendered = renderer.render(
      item: _item(signal),
      personality: OrbitPersonality.sarcastic,
    );
    expect(rendered.content.title, 'Uma fatura está vencida.');
    expect(rendered.content.detail, isNot(contains('R\$')));
  });

  test(
    'shared financial comparison can say vocês and unsupported fact falls back',
    () {
      expect(
        renderer
            .render(
              item: _item(_comparative()),
              personality: OrbitPersonality.sincere,
            )
            .content
            .detail,
        contains('Vocês'),
      );
      final unsupported = FinancialSignal(
        type: FinancialSignalType.cardSpendingChanged,
        direction: FinancialSignalDirection.increase,
        reason: FinancialSignalReason.comparisonThresholdMet,
        evidence: FinancialSignalEvidence.comparable,
        dedupeKey: 'card',
        walletId: 'w',
        walletScope: FinancialWalletScope.individualWallet,
        period: _period(),
      );
      final item = _item(unsupported);
      expect(
        renderer
            .render(item: item, personality: OrbitPersonality.julius)
            .content
            .title,
        item.content.title,
      );
    },
  );

  test(
    'variant selection avoids recent then reuses least recent deterministically',
    () {
      final item = _item(_budget());
      final first = renderer.render(
        item: item,
        personality: OrbitPersonality.mother,
      );
      final second = renderer.render(
        item: item,
        personality: OrbitPersonality.mother,
        recentVariantIds: [first.variantId],
      );
      expect(second.variantId, isNot(first.variantId));
      final exhausted = renderer.render(
        item: item,
        personality: OrbitPersonality.mother,
        recentVariantIds: ['one', 'two'],
      );
      expect(exhausted.variantId, 'one');
    },
  );

  test(
    'preferences isolate users and survive a new repository instance',
    () async {
      final store = _MemoryStore();
      final one = OrbitPersonalityPreferences(store: store);
      await one.savePersonality('aline', OrbitPersonality.mother);
      await one.savePersonality('matheus', OrbitPersonality.julius);
      await one.recordVariant(
        userId: 'aline',
        personality: OrbitPersonality.mother,
        factType: 'budgetExceeded',
        family: 'budget',
        variantId: 'one',
      );
      final restarted = OrbitPersonalityPreferences(store: store);
      expect(await restarted.loadPersonality('aline'), OrbitPersonality.mother);
      expect(
        await restarted.loadPersonality('matheus'),
        OrbitPersonality.julius,
      );
      expect(
        await restarted.recentVariants(
          userId: 'matheus',
          personality: OrbitPersonality.julius,
          factType: 'budgetExceeded',
          family: 'budget',
        ),
        isEmpty,
      );
    },
  );
}

FinancialSignal _budget() => FinancialSignal(
  type: FinancialSignalType.budgetExceeded,
  direction: FinancialSignalDirection.exceeded,
  reason: FinancialSignalReason.budgetExceeded,
  evidence: FinancialSignalEvidence.currentState,
  dedupeKey: 'budget',
  walletId: 'w',
  walletScope: FinancialWalletScope.individualWallet,
  period: _period(),
  currentValue: 648,
  comparisonValue: 500,
  absoluteDifference: 148,
  category: 'lazer',
);

FinancialSignal _comparative({
  FinancialSignalDirection direction = FinancialSignalDirection.increase,
}) => FinancialSignal(
  type: FinancialSignalType.spendingChanged,
  direction: direction,
  reason: FinancialSignalReason.comparisonThresholdMet,
  evidence: FinancialSignalEvidence.comparable,
  dedupeKey: 'spending',
  walletId: 'w',
  walletScope: FinancialWalletScope.sharedWallet,
  period: _period(),
  absoluteDifference: direction == FinancialSignalDirection.increase ? 50 : -50,
);

FinancialSignalPeriod _period() => FinancialSignalPeriod(
  start: DateTime(2026, 9),
  end: DateTime(2026, 9, 30),
  completeness: FinancialPeriodCompleteness.complete,
);

OrbitIntelligenceItem _item(FinancialSignal signal) => OrbitIntelligenceItem(
  id: signal.dedupeKey,
  dedupeKey: signal.dedupeKey,
  domain: OrbitIntelligenceDomain.financial,
  kind: OrbitIntelligenceKind.insight,
  priority: OrbitPresentationPriority.secondary,
  scope: OrbitIntelligenceScope(
    id: signal.walletId,
    domain: OrbitIntelligenceDomain.financial,
    walletScope: signal.walletScope,
  ),
  content: const OrbitIntelligenceContent(
    title: 'Factual title',
    detail: 'Factual detail',
  ),
  source: signal,
);

class _MemoryStore implements OrbitPersonalityKeyValueStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
