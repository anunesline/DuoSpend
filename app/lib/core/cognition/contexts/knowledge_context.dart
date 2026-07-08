import 'cognition_scope.dart';

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

class KnowledgeContext {
  final String id;
  final CognitionScope scope;
  final KnowledgeContextSource source;
  final DateTime occurredAt;

  final Map<String, dynamic> data;
  final Map<String, dynamic> metadata;

  const KnowledgeContext({
    required this.id,
    required this.scope,
    required this.source,
    required this.occurredAt,
    this.data = const {},
    this.metadata = const {},
  });

  KnowledgeContext copyWith({
    String? id,
    CognitionScope? scope,
    KnowledgeContextSource? source,
    DateTime? occurredAt,
    Map<String, dynamic>? data,
    Map<String, dynamic>? metadata,
  }) {
    return KnowledgeContext(
      id: id ?? this.id,
      scope: scope ?? this.scope,
      source: source ?? this.source,
      occurredAt: occurredAt ?? this.occurredAt,
      data: data ?? this.data,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get hasData => data.isNotEmpty;

  bool get hasMetadata => metadata.isNotEmpty;
}