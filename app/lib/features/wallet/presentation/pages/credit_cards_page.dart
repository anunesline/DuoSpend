import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../../home/data/models/credit_card_invoice_model.dart';
import '../../../home/data/models/credit_card_model.dart';
import '../../../home/data/models/wallet_model.dart';
import '../controllers/credit_card_controller.dart';

class CreditCardsPage extends StatefulWidget {
  final List<WalletModel> individualWallets;

  const CreditCardsPage({
    super.key,
    required this.individualWallets,
  });

  @override
  State<CreditCardsPage> createState() => _CreditCardsPageState();
}

class _CreditCardsPageState extends State<CreditCardsPage> {
  late final CreditCardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CreditCardController()..loadCards();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _money(double value) => NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
      ).format(value);

  String _walletName(String walletId) {
    for (final wallet in widget.individualWallets) {
      if (wallet.id == walletId) return wallet.name;
    }
    return 'Carteira vinculada';
  }

  double? _parseMoney(String value) {
    return double.tryParse(
      value.trim().replaceAll('.', '').replaceAll(',', '.'),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _openCreateCardDialog() async {
    if (_controller.isLoading) {
      _showMessage('Os cartões ainda estão carregando.');
      return;
    }
    if (widget.individualWallets.isEmpty) {
      _showMessage('Crie uma carteira individual antes de adicionar um cartão.');
      return;
    }

    final nameController = TextEditingController();
    final digitsController = TextEditingController();
    final limitController = TextEditingController();
    final closingController = TextEditingController();
    final dueController = TextEditingController();
    var selectedWalletId = widget.individualWallets.first.id;

    final form = await showDialog<_NewCardDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Novo cartão'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nome do cartão',
                    hintText: 'Ex.: Inter Gold',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedWalletId,
                  decoration: const InputDecoration(
                    labelText: 'Carteira vinculada',
                  ),
                  items: widget.individualWallets
                      .map((wallet) => DropdownMenuItem<String>(
                            value: wallet.id,
                            child: Text(wallet.name),
                          ))
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedWalletId = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: digitsController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'Últimos 4 dígitos (opcional)',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: limitController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Limite total',
                    prefixText: 'R\$ ',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: closingController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Fecha dia'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: dueController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Vence dia'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  _NewCardDraft(
                    name: nameController.text.trim(),
                    digits: digitsController.text.trim(),
                    limit: limitController.text,
                    closingDay: closingController.text,
                    dueDay: dueController.text,
                    walletId: selectedWalletId,
                  ),
                );
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    digitsController.dispose();
    limitController.dispose();
    closingController.dispose();
    dueController.dispose();

    if (form == null || !mounted) return;

    final limit = _parseMoney(form.limit);
    final closingDay = int.tryParse(form.closingDay.trim());
    final dueDay = int.tryParse(form.dueDay.trim());
    if (form.name.isEmpty ||
        limit == null ||
        limit <= 0 ||
        closingDay == null ||
        closingDay < 1 ||
        closingDay > 31 ||
        dueDay == null ||
        dueDay < 1 ||
        dueDay > 31) {
      _showMessage('Confira nome, limite, fechamento e vencimento do cartão.');
      return;
    }

    final card = await _controller.createCard(
      name: form.name,
      walletId: form.walletId,
      creditLimit: limit,
      closingDay: closingDay,
      dueDay: dueDay,
      lastFourDigits: form.digits.isEmpty ? null : form.digits,
    );
    if (!mounted) return;
    _showMessage(
      card == null
          ? _controller.errorMessage ?? 'Não foi possível criar o cartão.'
          : 'Cartão criado.',
    );
  }

  Future<void> _openInvoices(CreditCardModel card) async {
    await _controller.loadInvoices(card.id);
    if (!mounted) return;
    final invoices = _controller.invoicesFor(card.id);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DuoColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.name,
                style: const TextStyle(
                  color: DuoColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fecha dia ${card.closingDay} • vence dia ${card.dueDay}',
                style: const TextStyle(color: DuoColors.textSecondary),
              ),
              const SizedBox(height: 18),
              if (invoices.isEmpty)
                const Text(
                  'Nenhuma fatura encontrada.',
                  style: TextStyle(color: DuoColors.textSecondary),
                )
              else
                ...invoices.map(
                  (invoice) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Fatura ${invoice.referenceMonth.toString().padLeft(2, '0')}/${invoice.referenceYear}',
                      style: const TextStyle(color: DuoColors.textPrimary),
                    ),
                    subtitle: Text(
                      invoice.isPaid
                          ? 'Paga'
                          : 'Vence em ${DateFormat('dd/MM/yyyy').format(invoice.dueDate)}',
                      style: const TextStyle(color: DuoColors.textSecondary),
                    ),
                    trailing: invoice.isPaid
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: DuoColors.success,
                          )
                        : FilledButton.tonal(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _payInvoice(card, invoice);
                            },
                            child: Text(_money(invoice.total)),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _payInvoice(
    CreditCardModel card,
    CreditCardInvoiceModel invoice,
  ) async {
    var selectedWalletId = card.walletId;
    final confirmedWalletId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pagar fatura'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedWalletId,
            decoration: const InputDecoration(labelText: 'Pagar com'),
            items: widget.individualWallets
                .map((wallet) => DropdownMenuItem<String>(
                      value: wallet.id,
                      child: Text(wallet.name),
                    ))
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                setDialogState(() => selectedWalletId = value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, selectedWalletId),
              child: const Text('Pagar'),
            ),
          ],
        ),
      ),
    );
    if (confirmedWalletId == null || !mounted) return;
    final success = await _controller.payInvoice(
      card: card,
      invoice: invoice,
      walletId: confirmedWalletId,
    );
    if (!mounted) return;
    _showMessage(
      success
          ? 'Fatura paga e limite liberado.'
          : _controller.errorMessage ?? 'Não foi possível pagar a fatura.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Scaffold(
        backgroundColor: DuoColors.background,
        appBar: AppBar(
          title: const Text('Cartões'),
          actions: [
            IconButton(
              tooltip: 'Novo cartão',
              onPressed: _openCreateCardDialog,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreateCardDialog,
          icon: const Icon(Icons.add_card_rounded),
          label: const Text('Novo cartão'),
        ),
        body: _controller.isLoading && !_controller.hasCards
            ? const Center(child: CircularProgressIndicator())
            : !_controller.hasCards
                ? const _EmptyCardsState()
                : RefreshIndicator(
                    onRefresh: _controller.loadCards,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                      itemCount: _controller.cards.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final card = _controller.cards[index];
                        return _OrbitCreditCard(
                          card: card,
                          walletName: _walletName(card.walletId),
                          money: _money,
                          onTap: () => _openInvoices(card),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

class _OrbitCreditCard extends StatelessWidget {
  final CreditCardModel card;
  final String walletName;
  final String Function(double) money;
  final VoidCallback onTap;

  const _OrbitCreditCard({
    required this.card,
    required this.walletName,
    required this.money,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final available = (card.creditLimit - card.usedLimit).clamp(0, double.infinity);
    final progress = card.creditLimit <= 0
        ? 0.0
        : (card.usedLimit / card.creditLimit).clamp(0, 1).toDouble();

    return DuoCard(
      borderRadius: 26,
      gradient: DuoColors.cardGradient,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: DuoColors.primary.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.credit_card_rounded,
                      color: DuoColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          style: const TextStyle(
                            color: DuoColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          card.lastFourDigits == null
                              ? walletName
                              : '•••• ${card.lastFourDigits} • $walletName',
                          style: const TextStyle(
                            color: DuoColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: DuoColors.textHint,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Fatura atual',
                style: TextStyle(color: DuoColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                money(card.usedLimit),
                style: const TextStyle(
                  color: DuoColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: DuoColors.surfaceLight,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Disponível ${money(available.toDouble())}',
                      style: const TextStyle(
                        color: DuoColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    'Limite ${money(card.creditLimit)}',
                    style: const TextStyle(
                      color: DuoColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Fecha dia ${card.closingDay} • vence dia ${card.dueDay}',
                style: const TextStyle(
                  color: DuoColors.textHint,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCardsState extends StatelessWidget {
  const _EmptyCardsState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 80),
        Icon(
          Icons.credit_card_off_rounded,
          size: 56,
          color: DuoColors.textHint,
        ),
        SizedBox(height: 16),
        Text(
          'Nenhum cartão cadastrado',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: DuoColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Cadastre um cartão para organizar limites e faturas.',
          textAlign: TextAlign.center,
          style: TextStyle(color: DuoColors.textSecondary),
        ),
      ],
    );
  }
}

class _NewCardDraft {
  final String name;
  final String digits;
  final String limit;
  final String closingDay;
  final String dueDay;
  final String walletId;

  const _NewCardDraft({
    required this.name,
    required this.digits,
    required this.limit,
    required this.closingDay,
    required this.dueDay,
    required this.walletId,
  });
}
