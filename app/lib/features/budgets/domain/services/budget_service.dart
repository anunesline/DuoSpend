import '../models/budget.dart';

class BudgetService {
  const BudgetService();

  Budget create({required String id, required String walletId, required String category, required DateTime month, required double limitAmount, required String createdByUserId, DateTime? now}) {
    final time = now ?? DateTime.now();
    _validate(id: id, walletId: walletId, category: category, limitAmount: limitAmount, createdByUserId: createdByUserId);
    return Budget(id: id.trim(), walletId: walletId.trim(), category: category.trim(), month: DateTime(month.year, month.month), limitAmount: limitAmount, createdByUserId: createdByUserId.trim(), createdAt: time, updatedAt: time);
  }

  Budget update({required Budget budget, required String category, required DateTime month, required double limitAmount, DateTime? now}) {
    if (budget.isArchived) throw StateError('Orçamentos arquivados não podem ser editados.');
    _validate(id: budget.id, walletId: budget.walletId, category: category, limitAmount: limitAmount, createdByUserId: budget.createdByUserId);
    return budget.copyWith(category: category.trim(), month: DateTime(month.year, month.month), limitAmount: limitAmount, updatedAt: now ?? DateTime.now());
  }

  void _validate({required String id, required String walletId, required String category, required double limitAmount, required String createdByUserId}) {
    if (id.trim().isEmpty || walletId.trim().isEmpty || createdByUserId.trim().isEmpty) throw ArgumentError('Dados obrigatórios do orçamento não informados.');
    if (category.trim().isEmpty) throw ArgumentError.value(category, 'category', 'Informe uma categoria.');
    if (!limitAmount.isFinite || limitAmount <= 0) throw ArgumentError.value(limitAmount, 'limitAmount', 'O limite deve ser maior que zero.');
  }
}
