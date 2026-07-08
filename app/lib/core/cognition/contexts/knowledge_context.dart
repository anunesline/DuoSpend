import 'cognition_scope.dart';

abstract class KnowledgePayload {
  const KnowledgePayload();
}

enum KnowledgeContextSource {
  manualPurchase,
  shoppingFlow,
  correction,
  conversation,
  ocr,
  openFinance,
  import,
  systemInference,
}

class KnowledgeContext<TPayload extends KnowledgePayload> {
  final String id;
  final CognitionScope scope;
  final KnowledgeContextSource source;
  final DateTime occurredAt;

  final TPayload payload;

  final Map<String, Object?> metadata;

  const KnowledgeContext({
    required this.id,
    required this.scope,
    required this.source,
    required this.occurredAt,
    required this.payload,
    this.metadata = const {},
  });

  KnowledgeContext<TPayload> copyWith({
    String? id,
    CognitionScope? scope,
    KnowledgeContextSource? source,
    DateTime? occurredAt,
    TPayload? payload,
    Map<String, Object?>? metadata,
  }) {
    return KnowledgeContext<TPayload>(
      id: id ?? this.id,
      scope: scope ?? this.scope,
      source: source ?? this.source,
      occurredAt: occurredAt ?? this.occurredAt,
      payload: payload ?? this.payload,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get hasMetadata => metadata.isNotEmpty;
}