import 'purchase_item_model.dart';

class PurchaseModel {
  final String id;
  final String userId;
  final String walletId;

  final String? merchantId;
  final String merchantName;

  final String financialCategory;
  final String financialSubcategory;

  final List<PurchaseItemModel> items;

  final double subtotal;
  final double discount;
  final double total;

  final DateTime purchaseDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PurchaseModel({
    required this.id,
    required this.userId,
    required this.walletId,
    this.merchantId,
    required this.merchantName,
    required this.financialCategory,
    required this.financialSubcategory,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.purchaseDate,
    required this.createdAt,
    required this.updatedAt,
  });

  PurchaseModel copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? merchantId,
    String? merchantName,
    String? financialCategory,
    String? financialSubcategory,
    List<PurchaseItemModel>? items,
    double? subtotal,
    double? discount,
    double? total,
    DateTime? purchaseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      financialCategory: financialCategory ?? this.financialCategory,
      financialSubcategory:
          financialSubcategory ?? this.financialSubcategory,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'walletId': walletId,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'financialCategory': financialCategory,
      'financialSubcategory': financialSubcategory,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'purchaseDate': purchaseDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PurchaseModel.fromMap(Map<String, dynamic> map) {
    return PurchaseModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      walletId: map['walletId'] ?? '',
      merchantId: map['merchantId'],
      merchantName: map['merchantName'] ?? '',
      financialCategory: map['financialCategory'] ?? 'Sem categoria',
      financialSubcategory:
          map['financialSubcategory'] ?? 'Sem subcategoria',
      items: (map['items'] as List<dynamic>? ?? [])
          .map(
            (item) => PurchaseItemModel.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      purchaseDate: DateTime.parse(map['purchaseDate']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  bool get hasItems => items.isNotEmpty;

  int get itemCount => items.length;
}