import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/models/shared_transaction_confirmation_status.dart';
import '../controllers/transaction_controller.dart';
import 'transaction_detail_page.dart';

class HistoryPage extends StatefulWidget {
  final WalletModel wallet;
  final List<TransactionModel> transactions;
  final TransactionController? transactionController;
  final String? currentUserId;

  const HistoryPage({
    super.key,
    required this.wallet,
    required this.transactions,
    this.transactionController,
    this.currentUserId,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final List<TransactionModel> _transactions;

  String? _processingTransactionId;

  @override
  void initState() {
    super.initState();

    _transactions = List<TransactionModel>.from(
      widget.transactions,
    );

    _sortTransactions();
  }

  bool get _canRespondToConfirmations {
    final currentUserId = widget.currentUserId?.trim();

    return widget.transactionController != null &&
        currentUserId != null &&
        currentUserId.isNotEmpty;
  }

  void _sortTransactions() {
    _transactions.sort((firstTransaction, secondTransaction) {
      final firstCanRespond = _canCurrentUserRespond(
        firstTransaction,
      );

      final secondCanRespond = _canCurrentUserRespond(
        secondTransaction,
      );

      if (firstCanRespond != secondCanRespond) {
        return firstCanRespond ? -1 : 1;
      }

      final firstIsPending =
          firstTransaction.isAwaitingConfirmation;

      final secondIsPending =
          secondTransaction.isAwaitingConfirmation;

      if (firstIsPending != secondIsPending) {
        return firstIsPending ? -1 : 1;
      }

      return secondTransaction.date.compareTo(
        firstTransaction.date,
      );
    });
  }

  String _formatValue(TransactionModel transaction) {
    final prefix = transaction.type == 'income' ? '+' : '-';
    final formattedValue = transaction.value
        .toStringAsFixed(2)
        .replaceAll('.', ',');

    return '$prefix R\$ $formattedValue';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  bool _isTransactionAuthor(TransactionModel transaction) {
    final currentUserId = widget.currentUserId?.trim();
    final paidByMemberId = transaction.paidByMemberId?.trim();

    if (currentUserId == null ||
        currentUserId.isEmpty ||
        paidByMemberId == null ||
        paidByMemberId.isEmpty) {
      return false;
    }

    return paidByMemberId == currentUserId;
  }

  bool _canCurrentUserRespond(TransactionModel transaction) {
    return _canRespondToConfirmations &&
        transaction.isAwaitingConfirmation &&
        !_isTransactionAuthor(transaction);
  }

  bool _isProcessing(TransactionModel transaction) {
    return _processingTransactionId == transaction.id;
  }

  Future<void> _openTransactionDetail(
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

  Future<void> _acceptTransaction(
    TransactionModel transaction,
  ) async {
    await _resolveTransaction(
      transaction: transaction,
      accept: true,
    );
  }

  Future<void> _rejectTransaction(
    TransactionModel transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Recusar despesa?',
          ),
          content: Text(
            'A despesa "${transaction.description}" não impactará '
            'a divisão financeira compartilhada.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Recusar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _resolveTransaction(
      transaction: transaction,
      accept: false,
    );
  }

  Future<void> _resolveTransaction({
    required TransactionModel transaction,
    required bool accept,
  }) async {
    final transactionController = widget.transactionController;
    final currentUserId = widget.currentUserId?.trim();

    if (transactionController == null ||
        currentUserId == null ||
        currentUserId.isEmpty ||
        _processingTransactionId != null) {
      return;
    }

    setState(() {
      _processingTransactionId = transaction.id;
    });

    try {
      final updatedTransaction = accept
          ? await transactionController.acceptSharedTransaction(
              transaction: transaction,
              wallet: widget.wallet,
              respondingMemberId: currentUserId,
            )
          : await transactionController.rejectSharedTransaction(
              transaction: transaction,
              wallet: widget.wallet,
              respondingMemberId: currentUserId,
            );

      if (!mounted) {
        return;
      }

      final transactionIndex = _transactions.indexWhere(
        (currentTransaction) {
          return currentTransaction.id == updatedTransaction.id;
        },
      );

      if (transactionIndex != -1) {
        setState(() {
          _transactions[transactionIndex] = updatedTransaction;
          _sortTransactions();
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'Despesa compartilhada confirmada.'
                : 'Despesa compartilhada recusada.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      final errorMessage = transactionController.errorMessage ??
          'Não foi possível responder à confirmação.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingTransactionId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico',
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _WalletHeader(
            wallet: widget.wallet,
            transactionCount: _transactions.length,
          ),
          Expanded(
            child: _transactions.isEmpty
                ? const _EmptyHistory()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    itemCount: _transactions.length,
                    separatorBuilder: (_, __) {
                      return const SizedBox(
                        height: AppSpacing.sm,
                      );
                    },
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];

                      return _TransactionHistoryCard(
                        transaction: transaction,
                        formattedValue: _formatValue(transaction),
                        formattedDate: _formatDate(transaction.date),
                        formattedTime: _formatTime(transaction.date),
                        isAuthor: _isTransactionAuthor(transaction),
                        canRespond:
                            _canCurrentUserRespond(transaction),
                        isProcessing: _isProcessing(transaction),
                        onTap: () {
                          _openTransactionDetail(transaction);
                        },
                        onAccept: () {
                          _acceptTransaction(transaction);
                        },
                        onReject: () {
                          _rejectTransaction(transaction);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _WalletHeader extends StatelessWidget {
  final WalletModel wallet;
  final int transactionCount;

  const _WalletHeader({
    required this.wallet,
    required this.transactionCount,
  });

  @override
  Widget build(BuildContext context) {
    final transactionLabel = transactionCount == 1
        ? '1 movimentação'
        : '$transactionCount movimentações';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
      ),
      child: Row(
        children: [
          CircleAvatar(
            child: Icon(
              wallet.isShared
                  ? Icons.favorite_outline_rounded
                  : Icons.account_balance_wallet_outlined,
            ),
          ),
          const SizedBox(
            width: AppSpacing.md,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  transactionLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionHistoryCard extends StatelessWidget {
  final TransactionModel transaction;
  final String formattedValue;
  final String formattedDate;
  final String formattedTime;
  final bool isAuthor;
  final bool canRespond;
  final bool isProcessing;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _TransactionHistoryCard({
    required this.transaction,
    required this.formattedValue,
    required this.formattedDate,
    required this.formattedTime,
    required this.isAuthor,
    required this.canRespond,
    required this.isProcessing,
    required this.onTap,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final transactionColor = isIncome
        ? Colors.green
        : Colors.red;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isProcessing ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: transactionColor.withValues(
                      alpha: 0.12,
                    ),
                    child: Icon(
                      isIncome
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: transactionColor,
                    ),
                  ),
                  const SizedBox(
                    width: AppSpacing.md,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(
                          height: AppSpacing.xs,
                        ),
                        Text(
                          '$formattedDate às $formattedTime',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: AppSpacing.sm,
                  ),
                  Text(
                    formattedValue,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: transactionColor,
                    ),
                  ),
                ],
              ),
              if (transaction.isSharedExpense) ...[
                const SizedBox(
                  height: AppSpacing.md,
                ),
                _ConfirmationStatusChip(
                  transaction: transaction,
                  isAuthor: isAuthor,
                ),
              ],
              if (canRespond) ...[
                const SizedBox(
                  height: AppSpacing.md,
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isProcessing
                            ? null
                            : onReject,
                        icon: const Icon(
                          Icons.close_rounded,
                        ),
                        label: const Text(
                          'Recusar',
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: AppSpacing.sm,
                    ),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isProcessing
                            ? null
                            : onAccept,
                        icon: isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.check_rounded,
                              ),
                        label: Text(
                          isProcessing
                              ? 'Salvando...'
                              : 'Aceitar',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmationStatusChip extends StatelessWidget {
  final TransactionModel transaction;
  final bool isAuthor;

  const _ConfirmationStatusChip({
    required this.transaction,
    required this.isAuthor,
  });

  @override
  Widget build(BuildContext context) {
    final status = transaction.confirmationStatus;

    late final String label;
    late final IconData icon;
    late final Color foregroundColor;
    late final Color backgroundColor;

    switch (status) {
      case SharedTransactionConfirmationStatus.pending:
        label = isAuthor
            ? 'Aguardando confirmação'
            : 'Aguardando sua resposta';
        icon = Icons.schedule_rounded;
        foregroundColor = Colors.orange.shade800;
        backgroundColor = Colors.orange.withValues(
          alpha: 0.12,
        );

      case SharedTransactionConfirmationStatus.accepted:
        label = 'Confirmada';
        icon = Icons.check_circle_outline_rounded;
        foregroundColor = Colors.green.shade700;
        backgroundColor = Colors.green.withValues(
          alpha: 0.12,
        );

      case SharedTransactionConfirmationStatus.rejected:
        label = 'Recusada';
        icon = Icons.cancel_outlined;
        foregroundColor = Colors.red.shade700;
        backgroundColor = Colors.red.withValues(
          alpha: 0.12,
        );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: foregroundColor,
            ),
            const SizedBox(
              width: AppSpacing.xs,
            ),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 52,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
            const SizedBox(
              height: AppSpacing.md,
            ),
            Text(
              'Nenhuma movimentação encontrada.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(
              height: AppSpacing.xs,
            ),
            Text(
              'As transações desta carteira aparecerão aqui.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}