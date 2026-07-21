import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/balance_settlement_model.dart';
import '../controllers/balance_settlement_controller.dart';

class BalanceSettlementPage extends StatefulWidget {
  final String walletId;

  /// Permite mostrar nomes reais quando eles estiverem disponíveis.
  ///
  /// Exemplo:
  /// {
  ///   'uid-aline': 'Aline',
  ///   'uid-matheus': 'Matheus',
  /// }
  final Map<String, String> memberNames;

  const BalanceSettlementPage({
    super.key,
    required this.walletId,
    this.memberNames = const {},
  });

  @override
  State<BalanceSettlementPage> createState() =>
      _BalanceSettlementPageState();
}

class _BalanceSettlementPageState
    extends State<BalanceSettlementPage> {
  late final BalanceSettlementController _controller;

  String? get _currentUserId {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void initState() {
    super.initState();

    _controller = BalanceSettlementController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadSettlements(
        walletId: widget.walletId,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerto de contas'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            if (_controller.isLoading &&
                !_controller.hasSettlements) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (_controller.errorMessage != null &&
                !_controller.hasSettlements) {
              return _ErrorState(
                message: _controller.errorMessage!,
                onRetry: () {
                  _controller.loadSettlements(
                    walletId: widget.walletId,
                  );
                },
              );
            }

            return RefreshIndicator(
              onRefresh: () {
                return _controller.loadSettlements(
                  walletId: widget.walletId,
                );
              },
              child: CustomScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      20,
                      16,
                      32,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          _buildPendingSection(context),
                          const SizedBox(height: 28),
                          _buildHistorySection(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPendingSection(BuildContext context) {
    final pending =
        _controller.pendingSettlements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acertos pendentes',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Valores que ainda precisam ser acertados entre os membros.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        if (pending.isEmpty)
          const _EmptyPendingCard()
        else
          ...pending.map(
            (settlement) => Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: _PendingSettlementCard(
                settlement: settlement,
                currentUserId: _currentUserId,
                memberNameBuilder: _memberName,
                isProcessing: _controller.isLoading,
                onMarkAsPaid: () {
                  _confirmSettlementPayment(
                    settlement,
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    final completed =
        _controller.completedSettlements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Histórico',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Acertos que já foram marcados como pagos.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        if (completed.isEmpty)
          const _EmptyHistoryCard()
        else
          ...completed.map(
            (settlement) => Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: _CompletedSettlementCard(
                settlement: settlement,
                currentUserId: _currentUserId,
                memberNameBuilder: _memberName,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmSettlementPayment(
    BalanceSettlementModel settlement,
  ) async {
    DateTime selectedDate = DateTime.now();

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            dialogContext,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Confirmar pagamento',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _paymentDescription(
                      settlement,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatCurrency(
                      settlement.amount,
                    ),
                    style: Theme.of(dialogContext)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Data do pagamento',
                    style: Theme.of(dialogContext)
                        .textTheme
                        .labelLarge,
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius:
                        BorderRadius.circular(12),
                    onTap: () async {
                      final pickedDate =
                          await showDatePicker(
                        context: dialogContext,
                        initialDate:
                            selectedDate,
                        firstDate:
                            DateTime(2020),
                        lastDate:
                            DateTime.now(),
                      );

                      if (pickedDate == null) {
                        return;
                      }

                      setDialogState(() {
                        selectedDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          selectedDate.hour,
                          selectedDate.minute,
                        );
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(
                            dialogContext,
                          )
                              .colorScheme
                              .outlineVariant,
                        ),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _formatDate(
                                selectedDate,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.edit_outlined,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'O horário atual será registrado junto com a data.',
                    style: Theme.of(dialogContext)
                        .textTheme
                        .bodySmall,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop(false);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop(true);
                  },
                  icon: const Icon(
                    Icons.check,
                  ),
                  label: const Text(
                    'Confirmar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final now = DateTime.now();

    final settledAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    final success =
        await _controller.markAsSettled(
      settlement: settlement,
      settledAt: settledAt,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pagamento registrado com sucesso.',
          ),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _controller.errorMessage ??
              'Não foi possível registrar o pagamento.',
        ),
      ),
    );
  }

  String _paymentDescription(
    BalanceSettlementModel settlement,
  ) {
    final payer =
        _memberName(settlement.fromMemberId);
    final receiver =
        _memberName(settlement.toMemberId);

    return '$payer pagou $receiver?';
  }

  String _memberName(String memberId) {
    if (memberId == _currentUserId) {
      return 'Você';
    }

    final savedName =
        widget.memberNames[memberId]?.trim();

    if (savedName != null &&
        savedName.isNotEmpty) {
      return savedName;
    }

    if (memberId.length <= 8) {
      return memberId;
    }

    return '${memberId.substring(0, 8)}...';
  }

  String _formatCurrency(double value) {
    final parts =
        value.toStringAsFixed(2).split('.');

    final integerPart = parts.first;
    final decimalPart = parts.last;

    final buffer = StringBuffer();

    for (
      var index = 0;
      index < integerPart.length;
      index++
    ) {
      final remaining =
          integerPart.length - index;

      buffer.write(integerPart[index]);

      if (remaining > 1 &&
          remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'R\$ ${buffer.toString()},$decimalPart';
  }

  String _formatDate(DateTime date) {
    return '${_twoDigits(date.day)}/'
        '${_twoDigits(date.month)}/'
        '${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} às '
        '${_twoDigits(date.hour)}:'
        '${_twoDigits(date.minute)}';
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}

class _PendingSettlementCard
    extends StatelessWidget {
  final BalanceSettlementModel settlement;
  final String? currentUserId;
  final String Function(String memberId)
      memberNameBuilder;
  final bool isProcessing;
  final VoidCallback onMarkAsPaid;

  const _PendingSettlementCard({
    required this.settlement,
    required this.currentUserId,
    required this.memberNameBuilder,
    required this.isProcessing,
    required this.onMarkAsPaid,
  });

  @override
  Widget build(BuildContext context) {
    final payer =
        memberNameBuilder(settlement.fromMemberId);
    final receiver =
        memberNameBuilder(settlement.toMemberId);

    final currentUserMustPay =
        settlement.fromMemberId ==
            currentUserId;

    final title = currentUserMustPay
        ? 'Você deve'
        : '$payer deve';

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .errorContainer,
                  child: Icon(
                    Icons.schedule_outlined,
                    color: Theme.of(context)
                        .colorScheme
                        .onErrorContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pendente',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _formatCurrency(
                settlement.amount,
              ),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'para $receiver',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Criado em ${_formatDate(settlement.createdAt)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isProcessing
                    ? null
                    : onMarkAsPaid,
                icon: const Icon(
                  Icons.check_circle_outline,
                ),
                label: const Text(
                  'Marcar como pago',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedSettlementCard
    extends StatelessWidget {
  final BalanceSettlementModel settlement;
  final String? currentUserId;
  final String Function(String memberId)
      memberNameBuilder;

  const _CompletedSettlementCard({
    required this.settlement,
    required this.currentUserId,
    required this.memberNameBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final payer =
        memberNameBuilder(settlement.fromMemberId);
    final receiver =
        memberNameBuilder(settlement.toMemberId);

    final paymentDate =
        settlement.settledAt ??
            settlement.createdAt;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .primaryContainer,
              child: Icon(
                Icons.check,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '$payer pagou $receiver',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatCurrency(
                      settlement.amount,
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDateTime(
                      paymentDate,
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall,
                  ),
                  if (settlement.notes
                          ?.trim()
                          .isNotEmpty ==
                      true) ...[
                    const SizedBox(height: 8),
                    Text(
                      settlement.notes!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium,
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

class _EmptyPendingCard extends StatelessWidget {
  const _EmptyPendingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color:
                  Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Nenhum acerto pendente. Está tudo certo por aqui!',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(Icons.history),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Os pagamentos concluídos aparecerão aqui.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color:
                  Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Tentar novamente',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCurrency(double value) {
  final parts = value.toStringAsFixed(2).split('.');
  final integerPart = parts.first;
  final decimalPart = parts.last;
  final buffer = StringBuffer();

  for (
    var index = 0;
    index < integerPart.length;
    index++
  ) {
    final remaining =
        integerPart.length - index;

    buffer.write(integerPart[index]);

    if (remaining > 1 &&
        remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  return 'R\$ ${buffer.toString()},$decimalPart';
}

String _formatDate(DateTime date) {
  return '${_twoDigits(date.day)}/'
      '${_twoDigits(date.month)}/'
      '${date.year}';
}

String _formatDateTime(DateTime date) {
  return '${_formatDate(date)} às '
      '${_twoDigits(date.hour)}:'
      '${_twoDigits(date.minute)}';
}

String _twoDigits(int value) {
  return value.toString().padLeft(2, '0');
}