import '../../domain/models/budget.dart';

class BudgetModel {
  const BudgetModel._();
  static Map<String, dynamic> toMap(Budget budget) => {
    'id': budget.id, 'walletId': budget.walletId, 'category': budget.category,
    'month': budget.month.toIso8601String(), 'limitAmount': budget.limitAmount,
    'createdByUserId': budget.createdByUserId, 'status': budget.status.name,
    'createdAt': budget.createdAt.toIso8601String(), 'updatedAt': budget.updatedAt.toIso8601String(),
  };
  static Budget fromMap(Map<String, dynamic> map, {String? documentId}) => Budget(
    id: (map['id']?.toString().trim().isNotEmpty ?? false) ? map['id'].toString() : documentId ?? '',
    walletId: map['walletId']?.toString() ?? '', category: map['category']?.toString() ?? '',
    month: _date(map['month']) ?? DateTime.now(), limitAmount: _double(map['limitAmount']),
    createdByUserId: map['createdByUserId']?.toString() ?? '',
    status: _status(map['status']),
    createdAt: _date(map['createdAt']) ?? DateTime.now(), updatedAt: _date(map['updatedAt']) ?? DateTime.now(),
  );
  static double _double(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
  static DateTime? _date(dynamic value) => value == null ? null : DateTime.tryParse(value.toString());
  static BudgetStatus _status(dynamic value) {
    final raw = value?.toString();
    for (final status in BudgetStatus.values) {
      if (status.name == raw) return status;
    }
    return BudgetStatus.active;
  }
}
