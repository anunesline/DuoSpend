import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/presentation/pages/transaction_detail_page.dart';

class CategoryReportPage extends StatelessWidget {
  final String category;
  final DateTime startDate;
  final DateTime endDate;
  final List<TransactionModel> transactions;

  const CategoryReportPage({
    super.key,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.transactions,
  });

  List<TransactionModel> get _categoryTransactions {
    final filtered = transactions.where((transaction) {
      final normalizedCategory = transaction.category.trim().isEmpty
          ? 'Sem categoria'
          : transaction.category.trim();

      return transaction.type == 'expense' &&
          normalizedCategory == category;
    }).toList()
      ..sort((first, second) => second.date.compareTo(first.date));

    return List.unmodifiable(filtered);
  }

  double get _total {
    return _categoryTransactions.fold(
      0,
      (total, transaction) => total + transaction.value,
    );
  }

  String _formatMoney(double value) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    ).format(value);
  }

  String _formatPeriod() {
    final formatter = DateFormat('dd/MM/yyyy');

    return '${formatter.format(startDate)} – '
        '${formatter.format(endDate)}';
  }

  Future<void> _openTransaction(
    BuildContext context,
    TransactionModel transaction,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailPage(
          transaction: transaction,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryTransactions = _categoryTransactions;

    return Scaffold(
      backgroundColor: DuoColors.background,
      appBar: AppBar(
        backgroundColor: DuoColors.background,
        foregroundColor: DuoColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: Text(
          category,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              _formatPeriod(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DuoColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: DuoColors.heroGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: DuoColors.border),
                boxShadow: DuoColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total na categoria',
                    style: TextStyle(
                      color: DuoColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _formatMoney(_total),
                    style: const TextStyle(
                      color: DuoColors.error,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    categoryTransactions.length == 1
                        ? '1 despesa encontrada'
                        : '${categoryTransactions.length} despesas encontradas',
                    style: const TextStyle(
                      color: DuoColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Movimentações',
              style: TextStyle(
                color: DuoColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -.3,
              ),
            ),
            const SizedBox(height: 14),
            if (categoryTransactions.isEmpty)
              const _EmptyCategoryDetail()
            else
              DuoCard(
                borderRadius: 20,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var index = 0;
                        index < categoryTransactions.length;
                        index++) ...[
                      _CategoryTransactionRow(
                        transaction: categoryTransactions[index],
                        formattedValue: _formatMoney(
                          categoryTransactions[index].value,
                        ),
                        onTap: () => _openTransaction(
                          context,
                          categoryTransactions[index],
                        ),
                      ),
                      if (index != categoryTransactions.length - 1)
                        Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          color: DuoColors.divider,
                        ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTransactionRow extends StatelessWidget {
  final TransactionModel transaction;
  final String formattedValue;
  final VoidCallback onTap;

  const _CategoryTransactionRow({
    required this.transaction,
    required this.formattedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: DuoColors.error.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.north_east_rounded,
                  color: DuoColors.error,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DuoColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${transaction.subcategory} • '
                      '${DateFormat('dd/MM/yyyy').format(transaction.date)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DuoColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '- $formattedValue',
                style: const TextStyle(
                  color: DuoColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: DuoColors.textHint,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCategoryDetail extends StatelessWidget {
  const _EmptyCategoryDetail();

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(24),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: DuoColors.textHint,
            size: 34,
          ),
          SizedBox(height: 12),
          Text(
            'Nenhuma despesa encontrada',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DuoColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
