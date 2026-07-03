import 'transaction_item_model.dart';

class TransactionModel {
  final String id;
  final String description;
  final double value;
  final String type; // income | expense
  final DateTime date;
  final String walletId;
  final String category;
  final String subcategory;
  final List<TransactionItemModel> items;

  TransactionModel({
    required this.id,
    required this.description,
    required this.value,
    required this.type,
    required this.date,
    required this.walletId,
    required this.category,
    required this.subcategory,
    this.items = const [],
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
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];

    return TransactionModel(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      value: (map['value'] ?? 0).toDouble(),
      type: map['type'] ?? 'expense',
      date: DateTime.parse(map['date']),
      walletId: map['walletId'] ?? 'principal',
      category: map['category'] ?? 'Sem categoria',
      subcategory: map['subcategory'] ?? 'Sem subcategoria',
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(TransactionItemModel.fromMap)
              .toList()
          : [],
    );
  }
}