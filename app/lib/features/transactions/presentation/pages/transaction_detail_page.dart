import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../data/models/transaction_model.dart';

class TransactionDetailPage extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailPage({
    super.key,
    required this.transaction,
  });

  bool get isIncome => transaction.type == 'income';

  String get formattedValue {
    final prefix = isIncome ? '+' : '-';
    return '$prefix R\$ ${transaction.value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String get formattedDate {
    final day = transaction.date.day.toString().padLeft(2, '0');
    final month = transaction.date.month.toString().padLeft(2, '0');
    final year = transaction.date.year.toString();
    return '$day/$month/$year';
  }

  String get formattedTime {
    final hour = transaction.date.hour.toString().padLeft(2, '0');
    final minute = transaction.date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.description,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              formattedValue,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.swap_vert,
                      label: 'Tipo',
                      value: isIncome ? 'Receita' : 'Despesa',
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.calendar_today,
                      label: 'Data',
                      value: formattedDate,
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.access_time,
                      label: 'Horário',
                      value: formattedTime,
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.account_balance_wallet,
                      label: 'Carteira',
                      value: transaction.walletId,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Duo Insights',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Em breve, o Duo vai comparar esse gasto com seus hábitos e mostrar dicas inteligentes aqui.',
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit),
                label: const Text('Editar transação'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.delete_outline),
                label: const Text('Excluir transação'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AppSpacing.md),
        Text(label),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}