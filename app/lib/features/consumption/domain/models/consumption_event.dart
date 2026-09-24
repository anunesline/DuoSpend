/// Fatos confirmados sobre o ciclo de consumo de um produto.
///
/// Estes eventos não representam sinais, previsões nem estado de estoque.
/// Eles registram apenas o que foi declarado ou importado e podem ser
/// inativados explicitamente sem apagar o histórico.
enum ConsumptionEventType {
  stillHave,
  finished,
  spoiled,
  discarded,
  externalPurchase,
  exceptionalPurchase,
  paused,
  discontinued;

  String get value => name;

  static ConsumptionEventType fromValue(Object? value) {
    return ConsumptionEventType.values.firstWhere(
      (type) => type.value == value?.toString(),
      orElse: () => ConsumptionEventType.stillHave,
    );
  }
}

/// Origem factual do registro. A origem não é uma inferência do motor.
enum ConsumptionEventSource {
  userFeedback,
  import;

  String get value => name;

  static ConsumptionEventSource fromValue(Object? value) {
    return ConsumptionEventSource.values.firstWhere(
      (source) => source.value == value?.toString(),
      orElse: () => ConsumptionEventSource.userFeedback,
    );
  }
}

/// Motivo explicitamente informado para uma compra excepcional.
///
/// A ausência deste campo significa que nenhuma causa foi confirmada.
enum ExceptionalPurchaseReason {
  promotion,
  stocking,
  eventOrVisit,
  other;

  String get value => name;

  static ExceptionalPurchaseReason? fromValue(Object? value) {
    final normalized = value?.toString().trim();
    if (normalized == null || normalized.isEmpty) return null;
    for (final reason in ExceptionalPurchaseReason.values) {
      if (reason.value == normalized) return reason;
    }
    return null;
  }
}

class ConsumptionEvent {
  static const currentSchemaVersion = 1;

  const ConsumptionEvent({
    required this.id,
    required this.productId,
    required this.type,
    required this.occurredAt,
    required this.recordedAt,
    this.scopeId,
    this.recordedByUserId,
    this.source = ConsumptionEventSource.userFeedback,
    this.remainingQuantity,
    this.remainingUnit,
    this.purchaseId,
    this.purchaseItemId,
    this.priceObservationId,
    this.exceptionalReason,
    this.exceptionalReasonNote,
    this.pauseUntil,
    this.supersedesEventId,
    this.isActive = true,
    this.invalidatedAt,
    this.invalidatedByUserId,
    this.invalidationReason,
    this.schemaVersion = currentSchemaVersion,
  });

  final String id;

  /// Identidade física canônica; nunca inclui escopo, autor ou carteira.
  final String productId;

  /// `null` significa exclusivamente escopo ainda não atribuído ou
  /// desconhecido. Nunca representa Solo, household, escopo global,
  /// compartilhamento implícito ou fallback para autoria/pagamento.
  final String? scopeId;
  final ConsumptionEventType type;
  final ConsumptionEventSource source;
  final DateTime occurredAt;
  final DateTime recordedAt;
  final String? recordedByUserId;

  /// Somente para [ConsumptionEventType.stillHave] quando a pessoa informou
  /// uma quantidade. Não representa inventário calculado pelo sistema.
  final double? remainingQuantity;
  final String? remainingUnit;

  /// Referências factuais opcionais; a compra permanece a fonte de preço,
  /// estabelecimento e itens, sem duplicação desses dados neste evento.
  final String? purchaseId;
  final String? purchaseItemId;
  final String? priceObservationId;

  final ExceptionalPurchaseReason? exceptionalReason;
  final String? exceptionalReasonNote;
  final DateTime? pauseUntil;

  /// Um evento corretivo pode apontar para o evento factual que substitui.
  final String? supersedesEventId;

  /// A inativação é explícita para preservar a trilha de auditoria.
  final bool isActive;
  final DateTime? invalidatedAt;
  final String? invalidatedByUserId;
  final String? invalidationReason;
  final int schemaVersion;

  bool get hasKnownScope => _text(scopeId) != null;
  bool get hasRemainingQuantity => remainingQuantity != null;
  bool get isHumanFeedback => source == ConsumptionEventSource.userFeedback;

  ConsumptionEvent invalidate({
    required DateTime at,
    String? byUserId,
    String? reason,
  }) {
    return ConsumptionEvent(
      id: id,
      productId: productId,
      scopeId: scopeId,
      type: type,
      source: source,
      occurredAt: occurredAt,
      recordedAt: recordedAt,
      recordedByUserId: recordedByUserId,
      remainingQuantity: remainingQuantity,
      remainingUnit: remainingUnit,
      purchaseId: purchaseId,
      purchaseItemId: purchaseItemId,
      priceObservationId: priceObservationId,
      exceptionalReason: exceptionalReason,
      exceptionalReasonNote: exceptionalReasonNote,
      pauseUntil: pauseUntil,
      supersedesEventId: supersedesEventId,
      isActive: false,
      invalidatedAt: at,
      invalidatedByUserId: byUserId,
      invalidationReason: reason,
      schemaVersion: schemaVersion,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'productId': productId,
    'scopeId': scopeId,
    'type': type.value,
    'source': source.value,
    'occurredAt': occurredAt.toIso8601String(),
    'recordedAt': recordedAt.toIso8601String(),
    'recordedByUserId': recordedByUserId,
    'remainingQuantity': remainingQuantity,
    'remainingUnit': remainingUnit,
    'purchaseId': purchaseId,
    'purchaseItemId': purchaseItemId,
    'priceObservationId': priceObservationId,
    'exceptionalReason': exceptionalReason?.value,
    'exceptionalReasonNote': exceptionalReasonNote,
    'pauseUntil': pauseUntil?.toIso8601String(),
    'supersedesEventId': supersedesEventId,
    'isActive': isActive,
    'invalidatedAt': invalidatedAt?.toIso8601String(),
    'invalidatedByUserId': invalidatedByUserId,
    'invalidationReason': invalidationReason,
    'schemaVersion': schemaVersion,
  };

  factory ConsumptionEvent.fromMap(Map<String, dynamic> map) {
    return ConsumptionEvent(
      id: map['id']?.toString() ?? '',
      productId: map['productId']?.toString() ?? '',
      scopeId: _text(map['scopeId']),
      type: ConsumptionEventType.fromValue(map['type']),
      source: ConsumptionEventSource.fromValue(map['source']),
      occurredAt:
          _date(map['occurredAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      recordedAt:
          _date(map['recordedAt']) ??
          _date(map['occurredAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      recordedByUserId: _text(map['recordedByUserId']),
      remainingQuantity: _positiveNumber(map['remainingQuantity']),
      remainingUnit: _text(map['remainingUnit']),
      purchaseId: _text(map['purchaseId']),
      purchaseItemId: _text(map['purchaseItemId']),
      priceObservationId: _text(map['priceObservationId']),
      exceptionalReason: ExceptionalPurchaseReason.fromValue(
        map['exceptionalReason'],
      ),
      exceptionalReasonNote: _text(map['exceptionalReasonNote']),
      pauseUntil: _date(map['pauseUntil']),
      supersedesEventId: _text(map['supersedesEventId']),
      isActive: map['isActive'] is bool ? map['isActive'] as bool : true,
      invalidatedAt: _date(map['invalidatedAt']),
      invalidatedByUserId: _text(map['invalidatedByUserId']),
      invalidationReason: _text(map['invalidationReason']),
      schemaVersion: _integer(map['schemaVersion']) ?? 1,
    );
  }

  static String? _text(Object? value) {
    final normalized = value?.toString().trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static DateTime? _date(Object? value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }

  static double? _positiveNumber(Object? value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    return number != null && number >= 0 ? number : null;
  }

  static int? _integer(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
