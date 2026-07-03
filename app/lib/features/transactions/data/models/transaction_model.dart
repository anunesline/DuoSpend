class TransactionModel {
  final String id;
  final String description;
  final double value;
  final String type; // income | expense
  final DateTime date;
  final String walletId;
  final String category;
  final String subcategory;

  TransactionModel({
    required this.id,
    required this.description,
    required this.value,
    required this.type,
    required this.date,
    required this.walletId,
    required this.category,
    required this.subcategory,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'value': value,
      'type': type,
      'date': date.toIso8601String(),
      'walletId': walletId,
      'category': category,
      'subcategory': subcategory,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      value: (map['value'] ?? 0).toDouble(),
      type: map['type'] ?? 'expense',
      date: DateTime.parse(map['date']),
      walletId: map['walletId'] ?? 'principal',
      category: map['category'] ?? 'Sem categoria',
      subcategory: map['subcategory'] ?? 'Sem subcategoria',
    );
  }
}
