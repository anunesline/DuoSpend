import 'package:flutter/material.dart';

import '../../../transactions/data/models/transaction_model.dart';

class TransactionsPreview extends StatelessWidget {
  final List<TransactionModel> transactions;

  const TransactionsPreview({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Últimas movimentações",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            if (transactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "Nenhuma movimentação encontrada.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...transactions.take(5).map(
                (transaction) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    transaction.type == "income"
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: transaction.type == "income"
                        ? Colors.green
                        : Colors.red,
                  ),
                  title: Text(transaction.description),
                  trailing: Text(
                    "R\$ ${transaction.value.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: transaction.type == "income"
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}