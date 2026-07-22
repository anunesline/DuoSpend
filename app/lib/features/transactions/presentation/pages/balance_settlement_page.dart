import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../home/data/models/wallet_model.dart';
import '../../data/models/balance_settlement_model.dart';
import '../controllers/balance_settlement_controller.dart';

class BalanceSettlementPage extends StatefulWidget {
  final String walletId;
  final WalletModel? wallet;
  final Map<String, String> memberNames;

  const BalanceSettlementPage({
    super.key,
    required this.walletId,
    this.wallet,
    this.memberNames = const {},
  });

  @override
  State<BalanceSettlementPage> createState() =>
      _BalanceSettlementPageState();
}

class _BalanceSettlementPageState
    extends State<BalanceSettlementPage> {
  late final BalanceSettlementController _controller;

  String? get _currentUserId =>
      FirebaseAuth.instance.currentUser?.uid;

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
                          if (_controller.errorMessage !=
                              null) ...[
                            _InlineErrorCard(
                              message:
                                  _controller.errorMessage!,
                              onDismiss:
                                  _controller.clearError,
                            ),
                            const SizedBox(height: 16),
                          ],
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
    final pending = _controller.pendingSettlements;

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
              padding: const EdgeInsets.only(bottom: 12),
              child: _PendingSettlementCard(
                settlement: settlement,
                currentUserId: _currentUserId,
                memberNameBuilder: _memberName,
                isProcessing: _controller.isProcessing(
                  settlement.id,
                ),
                onDeclarePayment: () {
                  _declarePayment(settlement);
                },
                onCancelDeclaration: () {
                  _cancelPaymentDeclaration(
                    settlement,
                  );
                },
                onConfirmReceipt: () {
                  _confirmReceipt(settlement);
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    final completed = _controller.completedSettlements;

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
          'Acertos que já foram confirmados pelos dois membros.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        if (completed.isEmpty)
          const _EmptyHistoryCard()
        else
          ...completed.map(
            (settlement) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CompletedSettlementCard(
                settlement: settlement,
                memberNameBuilder: _memberName,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _declarePayment(
    BalanceSettlementModel settlement,
  ) async {
    final confirmed = await _showActionDialog(
      title: 'Informar pagamento',
      description:
          'Confirma que você já pagou '
          '${_memberName(settlement.toMemberId)}?',
      amount: settlement.amount,
      confirmationLabel: 'Já paguei',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final success = await _controller.declarePayment(
      settlement: settlement,
    );

    if (!mounted) {
      return;
    }

    _showResultMessage(
      success: success,
      successMessage:
          'Pagamento informado. Agora falta a confirmação de quem recebeu.',
      fallbackError:
          'Não foi possível informar o pagamento.',
    );
  }

  Future<void> _cancelPaymentDeclaration(
    BalanceSettlementModel settlement,
  ) async {
    final confirmed = await _showActionDialog(
      title: 'Cancelar aviso',
      description:
          'Deseja cancelar a informação de que este pagamento foi realizado?',
      amount: settlement.amount,
      confirmationLabel: 'Cancelar aviso',
      destructive: true,
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final success =
        await _controller.cancelPaymentDeclaration(
      settlement: settlement,
    );

    if (!mounted) {
      return;
    }

    _showResultMessage(
      success: success,
      successMessage:
          'O aviso de pagamento foi cancelado.',
      fallbackError:
          'Não foi possível cancelar o aviso.',
    );
  }

  Future<void> _confirmReceipt(
    BalanceSettlementModel settlement,
  ) async {
    final wallet = widget.wallet;

    if (wallet == null) {
      _showMessage(
        'Não foi possível carregar os dados completos da carteira. '
        'Volte e abra esta tela novamente.',
      );
      return;
    }

    final confirmed = await _showActionDialog(
      title: 'Confirmar recebimento',
      description:
          'Confirma que recebeu o pagamento de '
          '${_memberName(settlement.fromMemberId)}?',
      amount: settlement.amount,
      confirmationLabel: 'Recebi',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final success = await _controller.confirmReceipt(
      settlement: settlement,
      wallet: wallet,
    );

    if (!mounted) {
      return;
    }

    _showResultMessage(
      success: success,
      successMessage:
          'Recebimento confirmado e acerto concluído.',
      fallbackError:
          'Não foi possível confirmar o recebimento.',
    );
  }

  Future<bool?> _showActionDialog({
    required String title,
    required String description,
    required double amount,
    required String confirmationLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(description),
              const SizedBox(height: 16),
              Text(
                _formatCurrency(amount),
                style: Theme.of(dialogContext)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Voltar'),
            ),
            destructive
                ? FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(dialogContext)
                          .pop(true);
                    },
                    icon: const Icon(
                      Icons.undo_outlined,
                    ),
                    label: Text(confirmationLabel),
                  )
                : FilledButton.icon(
                    onPressed: () {
                      Navigator.of(dialogContext)
                          .pop(true);
                    },
                    icon: const Icon(Icons.check),
                    label: Text(confirmationLabel),
                  ),
          ],
        );
      },
    );
  }

  void _showResultMessage({
    required bool success,
    required String successMessage,
    required String fallbackError,
  }) {
    _showMessage(
      success
          ? successMessage
          : _controller.errorMessage ??
              fallbackError,
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
}

class _PendingSettlementCard
    extends StatelessWidget {
  final BalanceSettlementModel settlement;
  final String? currentUserId;
  final String Function(String memberId)
      memberNameBuilder;
  final bool isProcessing;
  final VoidCallback onDeclarePayment;
  final VoidCallback onCancelDeclaration;
  final VoidCallback onConfirmReceipt;

  const _PendingSettlementCard({
    required this.settlement,
    required this.currentUserId,
    required this.memberNameBuilder,
    required this.isProcessing,
    required this.onDeclarePayment,
    required this.onCancelDeclaration,
    required this.onConfirmReceipt,
  });

  bool get _currentUserIsDebtor {
    return settlement.fromMemberId == currentUserId;
  }

  bool get _currentUserIsCreditor {
    return settlement.toMemberId == currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    final debtor =
        memberNameBuilder(settlement.fromMemberId);
    final creditor =
        memberNameBuilder(settlement.toMemberId);

    final awaiting =
        settlement.isAwaitingConfirmation;

    final title = _currentUserIsDebtor
        ? 'Você deve'
        : '$debtor deve';

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _SettlementStatusHeader(
              awaitingConfirmation: awaiting,
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
              _formatCurrency(settlement.amount),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'para $creditor',
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
            _buildAction(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context) {
    if (isProcessing) {
      return const SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: null,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 10),
              Text('Processando...'),
            ],
          ),
        ),
      );
    }

    if (settlement.isPending) {
      if (_currentUserIsDebtor) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onDeclarePayment,
            icon: const Icon(
              Icons.payments_outlined,
            ),
            label: const Text('Já paguei'),
          ),
        );
      }

      return _InformativeAction(
        icon: Icons.schedule_outlined,
        text: _currentUserIsCreditor
            ? 'Aguardando o pagamento'
            : 'Pagamento pendente',
      );
    }

    if (settlement.isAwaitingConfirmation) {
      if (_currentUserIsCreditor) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onConfirmReceipt,
            icon: const Icon(
              Icons.check_circle_outline,
            ),
            label: const Text('Recebi'),
          ),
        );
      }

      if (_currentUserIsDebtor) {
        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const _InformativeAction(
              icon: Icons.hourglass_top_outlined,
              text:
                  'Aguardando confirmação de quem recebeu',
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onCancelDeclaration,
              icon: const Icon(
                Icons.undo_outlined,
              ),
              label: const Text(
                'Cancelar aviso de pagamento',
              ),
            ),
          ],
        );
      }

      return const _InformativeAction(
        icon: Icons.hourglass_top_outlined,
        text: 'Aguardando confirmação',
      );
    }

    return const _InformativeAction(
      icon: Icons.info_outline,
      text: 'Estado do acerto indisponível',
    );
  }
}

class _SettlementStatusHeader
    extends StatelessWidget {
  final bool awaitingConfirmation;

  const _SettlementStatusHeader({
    required this.awaitingConfirmation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final backgroundColor =
        awaitingConfirmation
            ? colorScheme.tertiaryContainer
            : colorScheme.errorContainer;

    final foregroundColor =
        awaitingConfirmation
            ? colorScheme.onTertiaryContainer
            : colorScheme.onErrorContainer;

    final icon = awaitingConfirmation
        ? Icons.hourglass_top_outlined
        : Icons.schedule_outlined;

    final label = awaitingConfirmation
        ? 'Aguardando confirmação'
        : 'Pendente';

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: backgroundColor,
          child: Icon(
            icon,
            color: foregroundColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }
}

class _InformativeAction extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InformativeAction({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _CompletedSettlementCard
    extends StatelessWidget {
  final BalanceSettlementModel settlement;
  final String Function(String memberId)
      memberNameBuilder;

  const _CompletedSettlementCard({
    required this.settlement,
    required this.memberNameBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final debtor =
        memberNameBuilder(settlement.fromMemberId);
    final creditor =
        memberNameBuilder(settlement.toMemberId);

    final paymentDate =
        settlement.settledAt ?? settlement.createdAt;

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
                    '$debtor pagou $creditor',
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
                    _formatCurrency(settlement.amount),
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
                    _formatDateTime(paymentDate),
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

class _InlineErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _InlineErrorCard({
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color:
          Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context)
                  .colorScheme
                  .onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onErrorContainer,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Fechar',
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
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
              label: const Text('Tentar novamente'),
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

  for (var index = 0;
      index < integerPart.length;
      index++) {
    final remaining = integerPart.length - index;

    buffer.write(integerPart[index]);

    if (remaining > 1 && remaining % 3 == 1) {
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
