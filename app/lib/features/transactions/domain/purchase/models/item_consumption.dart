enum ItemConsumptionSource {
  manual,
  intelligence;

  String get value => name;

  static ItemConsumptionSource fromValue(String? value) {
    return ItemConsumptionSource.values.firstWhere(
      (source) => source.value == value,
      orElse: () => ItemConsumptionSource.manual,
    );
  }
}

class ItemConsumption {
  final String consumerId;
  final double? quantity;
  final double? percentage;
  final ItemConsumptionSource source;
  final double? confidence;

  const ItemConsumption({
    required this.consumerId,
    this.quantity,
    this.percentage,
    this.source = ItemConsumptionSource.manual,
    this.confidence,
  });

  bool get isManual => source == ItemConsumptionSource.manual;

  bool get isSuggested =>
      source == ItemConsumptionSource.intelligence;

  ItemConsumption copyWith({
    String? consumerId,
    double? quantity,
    double? percentage,
    ItemConsumptionSource? source,
    double? confidence,
  }) {
    return ItemConsumption(
      consumerId: consumerId ?? this.consumerId,
      quantity: quantity ?? this.quantity,
      percentage: percentage ?? this.percentage,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'consumerId': consumerId,
      'quantity': quantity,
      'percentage': percentage,
      'source': source.value,
      'confidence': confidence,
    };
  }

  factory ItemConsumption.fromMap(Map<String, dynamic> map) {
    return ItemConsumption(
      consumerId: map['consumerId'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble(),
      percentage: (map['percentage'] as num?)?.toDouble(),
      source: ItemConsumptionSource.fromValue(
        map['source'] as String?,
      ),
      confidence: (map['confidence'] as num?)?.toDouble(),
    );
  }
}