import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../../home/data/models/credit_card_invoice_model.dart';
import '../../../home/data/models/credit_card_model.dart';
import '../../../home/data/models/wallet_model.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/presentation/pages/transaction_detail_page.dart';
import '../controllers/credit_card_controller.dart';

class CreditCardsPage extends StatefulWidget {
  final List<WalletModel> individualWallets;
  final CreditCardController? controller;

  const CreditCardsPage({
    super.key,
    required this.individualWallets,
    this.controller,
  });

  @override
  State<CreditCardsPage> createState() => _CreditCardsPageState();
}

class _CreditCardsPageState extends State<CreditCardsPage> {
  late final CreditCardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? CreditCardController();
    _controller.loadCards();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  String _money(double value) =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);

  String _walletName(String? walletId) {
    if (walletId == null || walletId.isEmpty) return 'Sem carteira';
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
    final form = await showDialog<_NewCardDraft>(
      context: context,
      builder: (_) =>
          _NewCardDialog(individualWallets: widget.individualWallets),
    );

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

  Future<void> _openDetail(CreditCardModel card) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _CreditCardDetailPage(
          card: card,
          controller: _controller,
          wallets: widget.individualWallets,
          money: _money,
          onPayInvoice: _payInvoice,
          onEdit: (updated) => _controller.updateCard(updated),
          onArchive: () => _controller.setCardActive(card, false),
          onReactivate: () => _controller.setCardActive(card, true),
          onDelete: () => _controller.deleteCard(card),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _payInvoice(
    CreditCardModel card,
    CreditCardInvoiceModel invoice,
  ) async {
    String? selectedWalletId = card.walletId;
    final confirmedWalletId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pagar fatura'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedWalletId,
            decoration: const InputDecoration(labelText: 'Pagar com'),
            items: widget.individualWallets
                .map(
                  (wallet) => DropdownMenuItem<String>(
                    value: wallet.id,
                    child: Text(wallet.name),
                  ),
                )
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
                      onTap: () => _openDetail(card),
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
    final available = (card.creditLimit - card.usedLimit).clamp(
      0,
      double.infinity,
    );
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
                style: const TextStyle(color: DuoColors.textHint, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditCardDetailPage extends StatefulWidget {
  final CreditCardModel card;
  final CreditCardController controller;
  final List<WalletModel> wallets;
  final String Function(double) money;
  final Future<void> Function(CreditCardModel, CreditCardInvoiceModel)
  onPayInvoice;
  final Future<CreditCardModel?> Function(CreditCardModel) onEdit;
  final Future<bool> Function() onArchive;
  final Future<bool> Function() onReactivate;
  final Future<bool> Function() onDelete;

  const _CreditCardDetailPage({
    required this.card,
    required this.controller,
    required this.wallets,
    required this.money,
    required this.onPayInvoice,
    required this.onEdit,
    required this.onArchive,
    required this.onReactivate,
    required this.onDelete,
  });

  @override
  State<_CreditCardDetailPage> createState() => _CreditCardDetailPageState();
}

class _CreditCardDetailPageState extends State<_CreditCardDetailPage> {
  int _tab = 0;
  late CreditCardModel _card;

  @override
  void initState() {
    super.initState();
    _card = widget.card;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.loadInvoices(_card.id);
      widget.controller.loadPurchases(_card.id);
    });
  }

  String _walletName(String? id) {
    if (id == null || id.isEmpty) return 'Sem carteira';
    for (final wallet in widget.wallets) {
      if (wallet.id == id) return wallet.name;
    }
    return 'Carteira vinculada';
  }

  Future<void> _edit() async {
    final updated = await showDialog<CreditCardModel>(
      context: context,
      builder: (_) => _EditCardDialog(card: _card, wallets: widget.wallets),
    );
    if (updated == null || !mounted) return;
    final persisted = await widget.onEdit(updated);
    if (!mounted) return;
    if (persisted == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.errorMessage ??
                'Não foi possível atualizar o cartão.',
          ),
        ),
      );
      return;
    }
    setState(() => _card = persisted);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cartão atualizado.')));
  }

  Future<void> _toggleActive() async {
    final success = _card.isActive
        ? await widget.onArchive()
        : await widget.onReactivate();
    if (!success || !mounted) return;
    setState(() => _card = _card.copyWith(isActive: !_card.isActive));
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir cartão?'),
        content: const Text(
          'A exclusão é definitiva e só é permitida quando não há faturas ou compras vinculadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await widget.onDelete();
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este cartão possui histórico financeiro. Arquive-o para preservar o histórico.',
          ),
        ),
      );
    }
  }

  bool _showAllPurchases = false;

  void _openPurchase(TransactionModel purchase) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TransactionDetailPage(transaction: purchase),
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final invoices = widget.controller.invoicesFor(_card.id);
      final purchases = widget.controller.purchasesFor(_card.id);
      final current = invoices.isEmpty
          ? null
          : invoices.firstWhere((i) => !i.isPaid, orElse: () => invoices.first);
      final usage = _card.creditLimit <= 0
          ? 0.0
          : (_card.usedLimit / _card.creditLimit).clamp(0, 1).toDouble();
      return Scaffold(
        backgroundColor: DuoColors.orbitBackground,
        appBar: AppBar(
          backgroundColor: DuoColors.orbitBackground,
          title: const Text('Cartão'),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Ações do cartão',
              onSelected: (value) {
                if (value == 'edit') _edit();
                if (value == 'toggle') _toggleActive();
                if (value == 'delete') _delete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Editar cartão'),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    _card.isActive ? 'Arquivar cartão' : 'Reativar cartão',
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Excluir cartão'),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _CardHero(card: _card, walletName: _walletName(_card.walletId)),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: DuoColors.orbitSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DuoColors.orbitBorder),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < 2; i++)
                      Expanded(
                        child: Semantics(
                          selected: _tab == i,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () => setState(() => _tab = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _tab == i
                                      ? DuoColors.primary.withValues(alpha: .32)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: _tab == i
                                        ? DuoColors.orbitAccent
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  i == 0 ? 'Visão geral' : 'Faturas',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _tab == i
                                        ? DuoColors.orbitTextPrimary
                                        : DuoColors.orbitTextSecondary,
                                    fontWeight: _tab == i
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_tab == 0) ...[
                _DetailCard(
                  title: 'Fatura atual',
                  trailing: current == null
                      ? null
                      : _InvoiceBadge(invoice: current),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (current == null)
                        const _DetailEmpty(text: 'Nenhuma fatura em aberto.')
                      else ...[
                        Text(
                          widget.money(current.total),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: DuoColors.orbitTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Vence em ${DateFormat("dd/MM/yyyy").format(current.dueDate)}',
                          style: const TextStyle(
                            color: DuoColors.orbitTextSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Text(
                        'Limite disponível',
                        style: TextStyle(color: DuoColors.orbitTextSecondary),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 5,
                        children: [
                          Text(
                            widget.money(_card.availableLimit),
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w600,
                              color: DuoColors.orbitTextPrimary,
                            ),
                          ),
                          Text(
                            'de ${widget.money(_card.creditLimit)}',
                            style: const TextStyle(
                              color: DuoColors.orbitTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: usage,
                          minHeight: 10,
                          color: DuoColors.primary,
                          backgroundColor: const Color(0xFF343B4D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${NumberFormat.decimalPattern("pt_BR").format(usage * 100)}% utilizado • ${widget.money(_card.usedLimit)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: DuoColors.orbitTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: DuoColors.orbitBorder),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _CalendarValue(
                                label: 'Fecha dia',
                                day: _card.closingDay,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CalendarValue(
                                label: 'Vence dia',
                                day: _card.dueDay,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (current != null)
                        _DetailAction(
                          label: 'Ver detalhes da fatura',
                          onTap: () => _showInvoice(current, purchases),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _DetailCard(
                  title: 'Compras recentes',
                  child: Column(
                    children: [
                      _PurchaseGroups(
                        purchases: _showAllPurchases
                            ? purchases
                            : purchases.take(8).toList(),
                        money: widget.money,
                        onTap: _openPurchase,
                      ),
                      if (!_showAllPurchases && purchases.length > 8) ...[
                        const SizedBox(height: 16),
                        _DetailAction(
                          label: 'Ver todas as compras',
                          onTap: () => setState(() => _showAllPurchases = true),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _DetailCard(
                  title: 'Informações do cartão',
                  child: Column(
                    children: [
                      const _InfoRow(
                        icon: Icons.credit_card,
                        label: 'Tipo',
                        value: 'Cartão de crédito',
                      ),
                      _InfoRow(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Limite',
                        value: widget.money(_card.creditLimit),
                      ),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Fechamento',
                        value: 'Dia ${_card.closingDay}',
                      ),
                      _InfoRow(
                        icon: Icons.event_outlined,
                        label: 'Vencimento',
                        value: 'Dia ${_card.dueDay}',
                      ),
                      _InfoRow(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Carteira vinculada',
                        value: _walletName(_card.walletId),
                      ),
                      _InfoRow(
                        icon: Icons.info_outline,
                        label: 'Status',
                        value: _card.isActive ? '●  Ativo' : '●  Arquivado',
                        valueColor: _card.isActive
                            ? DuoColors.success
                            : DuoColors.orbitTextSecondary,
                      ),
                    ],
                  ),
                ),
              ] else
                _DetailCard(
                  title: 'Histórico de faturas',
                  child: invoices.isEmpty
                      ? const _DetailEmpty(text: 'Nenhuma fatura encontrada.')
                      : Column(
                          children: [
                            for (final invoice in invoices)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _InvoiceTile(
                                  invoice: invoice,
                                  money: widget.money,
                                  onTap: () => _showInvoice(invoice, purchases),
                                ),
                              ),
                          ],
                        ),
                ),
            ],
          ),
        ),
      );
    },
  );

  Future<void> _showInvoice(
    CreditCardInvoiceModel invoice,
    List<TransactionModel> _,
  ) async {
    final purchases = await widget.controller.loadInvoicePurchases(
      cardId: _card.id,
      invoiceId: invoice.id,
    );
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DuoColors.orbitSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: DuoColors.orbitBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  'Fatura ${invoice.referenceMonth}/${invoice.referenceYear}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _InvoiceBadge(invoice: invoice),
                const SizedBox(height: 16),
                Text(
                  widget.money(invoice.total),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Vence em ${DateFormat("dd/MM/yyyy").format(invoice.dueDate)}',
                  style: const TextStyle(color: DuoColors.orbitTextSecondary),
                ),
                const SizedBox(height: 24),
                if (!invoice.isPaid && widget.wallets.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _DetailAction(
                      label: 'Pagar fatura',
                      onTap: () {
                        Navigator.pop(context);
                        widget.onPayInvoice(_card, invoice);
                      },
                    ),
                  ),
                if (purchases.isEmpty)
                  const _DetailEmpty(
                    text: 'Nenhuma compra vinculada a esta fatura.',
                  )
                else
                  _PurchaseGroups(
                    purchases: purchases,
                    money: widget.money,
                    onTap: _openPurchase,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardHero extends StatelessWidget {
  final CreditCardModel card;
  final String walletName;
  const _CardHero({required this.card, required this.walletName});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: AspectRatio(
          aspectRatio: MediaQuery.textScalerOf(context).scale(14) > 20
              ? 1.25
              : 1.65,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF363443)),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF343440),
                  Color(0xFF101119),
                  Color(0xFF292042),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -70,
                  bottom: -120,
                  child: Container(
                    width: 310,
                    height: 270,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DuoColors.orbitAccent.withValues(alpha: .65),
                      ),
                      gradient: RadialGradient(
                        colors: [
                          DuoColors.primary.withValues(alpha: .15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CRÉDITO',
                          style: TextStyle(
                            color: DuoColors.orbitTextPrimary,
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          flex: 3,
                          child: Text(
                            card.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.w700,
                              color: DuoColors.orbitTextPrimary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (card.lastFourDigits?.isNotEmpty == true)
                          Text(
                            '•••• •••• ${card.lastFourDigits}',
                            style: const TextStyle(
                              color: DuoColors.orbitTextPrimary,
                              fontSize: 17,
                              letterSpacing: 1,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        card.name,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: DuoColors.orbitTextPrimary,
          fontSize: 23,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          const _VisualBadge(
            text: 'Cartão de crédito',
            color: DuoColors.orbitAccent,
          ),
          _VisualBadge(
            text: walletName,
            color: DuoColors.orbitTextSecondary,
            icon: Icons.account_balance_wallet_outlined,
          ),
          if (!card.isActive)
            const _VisualBadge(
              text: 'Arquivado',
              color: DuoColors.orbitTextSecondary,
            ),
        ],
      ),
    ],
  );
}

class _VisualBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const _VisualBadge({required this.text, required this.color, this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text.rich(
      TextSpan(
        children: [
          if (icon != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(icon, size: 17, color: color),
              ),
            ),
          TextSpan(text: text),
        ],
      ),
      style: TextStyle(color: color, fontSize: 13),
    ),
  );
}

class _InvoiceBadge extends StatelessWidget {
  final CreditCardInvoiceModel invoice;
  const _InvoiceBadge({required this.invoice});
  @override
  Widget build(BuildContext context) => _VisualBadge(
    text: invoice.isPaid
        ? 'Paga'
        : invoice.isClosed
        ? 'Fechada'
        : 'Aberta',
    color: invoice.isPaid
        ? DuoColors.orbitTextSecondary
        : invoice.isClosed
        ? DuoColors.orbitAccent
        : DuoColors.success,
  );
}

class _DetailCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _DetailCard({required this.title, required this.child, this.trailing});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: DuoColors.orbitSurface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: DuoColors.orbitBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: DuoColors.orbitTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );
}

class _DetailEmpty extends StatelessWidget {
  final String text;
  const _DetailEmpty({required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
    child: Center(
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 32,
            color: DuoColors.orbitAccent,
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: DuoColors.orbitTextSecondary),
          ),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  const _InfoRow({
    required this.label,
    required this.value,
    this.icon = Icons.info_outline,
    this.valueColor,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: DuoColors.orbitBorder)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: DuoColors.orbitTextSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: DuoColors.orbitTextSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? DuoColors.orbitTextPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CalendarValue extends StatelessWidget {
  final String label;
  final int day;
  const _CalendarValue({required this.label, required this.day});
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(
        Icons.calendar_today_outlined,
        size: 20,
        color: DuoColors.orbitAccent,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: DuoColors.orbitTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$day',
              style: const TextStyle(
                fontSize: 23,
                color: DuoColors.orbitTextPrimary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _DetailAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DetailAction({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: DuoColors.surfaceLight,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: DuoColors.orbitTextPrimary),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: DuoColors.orbitTextSecondary,
            ),
          ],
        ),
      ),
    ),
  );
}

class _InvoiceTile extends StatelessWidget {
  final CreditCardInvoiceModel invoice;
  final String Function(double) money;
  final VoidCallback onTap;
  const _InvoiceTile({
    required this.invoice,
    required this.money,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: DuoColors.surfaceLight,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${invoice.referenceMonth.toString().padLeft(2, '0')}/${invoice.referenceYear}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: DuoColors.orbitTextSecondary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  money(invoice.total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _InvoiceBadge(invoice: invoice),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Vence em ${DateFormat("dd/MM/yyyy").format(invoice.dueDate)}',
              style: const TextStyle(
                color: DuoColors.orbitTextSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PurchaseGroups extends StatelessWidget {
  final List<TransactionModel> purchases;
  final String Function(double) money;
  final ValueChanged<TransactionModel> onTap;
  const _PurchaseGroups({
    required this.purchases,
    required this.money,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    if (purchases.isEmpty) {
      return const _DetailEmpty(text: 'Nenhuma compra encontrada.');
    }
    final sorted = [...purchases]..sort((a, b) => b.date.compareTo(a.date));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final groups = <String, List<TransactionModel>>{};
    for (final purchase in sorted) {
      final date = purchase.date;
      final day = DateTime(date.year, date.month, date.day);
      final label = day == today
          ? 'Hoje'
          : day == yesterday
          ? 'Ontem'
          : DateFormat('dd/MM/yyyy').format(date);
      groups.putIfAbsent(label, () => []).add(purchase);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 10),
            child: Text(
              group.key,
              style: const TextStyle(
                color: DuoColors.orbitTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          for (final purchase in group.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PurchaseTile(
                transaction: purchase,
                money: money,
                onTap: () => onTap(purchase),
              ),
            ),
        ],
      ],
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  final TransactionModel transaction;
  final String Function(double) money;
  final VoidCallback onTap;
  const _PurchaseTile({
    required this.transaction,
    required this.money,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final details = [
      transaction.category,
      if (transaction.subcategory.isNotEmpty) transaction.subcategory,
      if (transaction.items.isNotEmpty) '${transaction.items.length} itens',
      if (transaction.isInstallment &&
          transaction.installmentNumber != null &&
          transaction.installmentCount != null)
        'Parcela ${transaction.installmentNumber}/${transaction.installmentCount}',
    ].where((s) => s.isNotEmpty).join(' • ');
    final category = transaction.category.toLowerCase();
    final IconData icon;
    final Color color;
    if (category.contains('alimenta')) {
      icon = Icons.restaurant_outlined;
      color = const Color(0xFFE783A1);
    } else if (category.contains('transport')) {
      icon = Icons.directions_car_outlined;
      color = DuoColors.orbitAccent;
    } else if (category.contains('saúde') || category.contains('saude')) {
      icon = Icons.local_pharmacy_outlined;
      color = const Color(0xFFE783A1);
    } else if (category.contains('pet')) {
      icon = Icons.pets_outlined;
      color = const Color(0xFF63A7EF);
    } else {
      icon = Icons.shopping_bag_outlined;
      color = DuoColors.orbitAccent;
    }
    final description = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          transaction.description,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: DuoColors.orbitTextPrimary,
          ),
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            details,
            style: const TextStyle(
              fontSize: 12,
              color: DuoColors.orbitTextSecondary,
            ),
          ),
        ],
      ],
    );
    final amount = Text(
      money(transaction.value),
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: DuoColors.orbitTextPrimary,
      ),
    );
    final date = Text(
      DateFormat('dd/MM/yyyy').format(transaction.date),
      style: const TextStyle(fontSize: 11, color: DuoColors.orbitTextSecondary),
    );
    return Material(
      color: DuoColors.surfaceLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 320 ||
                  MediaQuery.textScalerOf(context).scale(14) > 18;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 22, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              description,
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [amount, date],
                              ),
                            ],
                          )
                        : description,
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [date, const SizedBox(height: 6), amount],
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: DuoColors.orbitTextSecondary,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EditCardDialog extends StatefulWidget {
  final CreditCardModel card;
  final List<WalletModel> wallets;
  const _EditCardDialog({required this.card, required this.wallets});
  @override
  State<_EditCardDialog> createState() => _EditCardDialogState();
}

class _EditCardDialogState extends State<_EditCardDialog> {
  late final TextEditingController _name;
  late final TextEditingController _digits;
  late final TextEditingController _limit;
  late final TextEditingController _closing;
  late final TextEditingController _due;
  late String? _walletId;

  @override
  void initState() {
    super.initState();
    final card = widget.card;
    _name = TextEditingController(text: card.name);
    _digits = TextEditingController(text: card.lastFourDigits ?? '');
    _limit = TextEditingController(text: card.creditLimit.toStringAsFixed(2));
    _closing = TextEditingController(text: card.closingDay.toString());
    _due = TextEditingController(text: card.dueDay.toString());
    _walletId = card.walletId;
  }

  @override
  void dispose() {
    _name.dispose();
    _digits.dispose();
    _limit.dispose();
    _closing.dispose();
    _due.dispose();
    super.dispose();
  }

  void _submit() {
    final limit = _parseLimit(_limit.text);
    final closing = int.tryParse(_closing.text.trim());
    final due = int.tryParse(_due.text.trim());
    if (_name.text.trim().isEmpty ||
        limit == null ||
        closing == null ||
        due == null)
      return;
    Navigator.pop(
      context,
      widget.card.copyWith(
        name: _name.text.trim(),
        lastFourDigits: _digits.text.trim(),
        clearLastFourDigits: _digits.text.trim().isEmpty,
        creditLimit: limit,
        closingDay: closing,
        dueDay: due,
        walletId: _walletId,
      ),
    );
  }

  double? _parseLimit(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;

    if (normalized.contains(',')) {
      return double.tryParse(
        normalized.replaceAll('.', '').replaceAll(',', '.'),
      );
    }

    return double.tryParse(normalized);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Editar cartão'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nome/apelido'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _walletId ?? '',
            decoration: const InputDecoration(labelText: 'Carteira vinculada'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Sem carteira')),
              ...widget.wallets.map(
                (wallet) => DropdownMenuItem(
                  value: wallet.id,
                  child: Text(wallet.name),
                ),
              ),
            ],
            onChanged: (value) => setState(
              () => _walletId = value == null || value.isEmpty ? null : value,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _digits,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(labelText: 'Últimos 4 dígitos'),
          ),
          TextField(
            controller: _limit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Limite',
              prefixText: 'R\$ ',
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _closing,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Fechamento'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _due,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Vencimento'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Salvar')),
    ],
  );
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

class _NewCardDialog extends StatefulWidget {
  final List<WalletModel> individualWallets;

  const _NewCardDialog({required this.individualWallets});

  @override
  State<_NewCardDialog> createState() => _NewCardDialogState();
}

class _NewCardDialogState extends State<_NewCardDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _digitsController;
  late final TextEditingController _limitController;
  late final TextEditingController _closingController;
  late final TextEditingController _dueController;
  String? _selectedWalletId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _digitsController = TextEditingController();
    _limitController = TextEditingController();
    _closingController = TextEditingController();
    _dueController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _digitsController.dispose();
    _limitController.dispose();
    _closingController.dispose();
    _dueController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(
      context,
      _NewCardDraft(
        name: _nameController.text.trim(),
        digits: _digitsController.text.trim(),
        limit: _limitController.text,
        closingDay: _closingController.text,
        dueDay: _dueController.text,
        walletId: _selectedWalletId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo cartão'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nome do cartão',
                hintText: 'Ex.: Inter Gold',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedWalletId ?? '',
              decoration: const InputDecoration(
                labelText: 'Carteira vinculada',
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('Sem carteira'),
                ),
                ...widget.individualWallets.map(
                  (wallet) => DropdownMenuItem<String>(
                    value: wallet.id,
                    child: Text(wallet.name),
                  ),
                ),
              ].toList(growable: false),
              onChanged: (value) {
                setState(
                  () => _selectedWalletId = value == null || value.isEmpty
                      ? null
                      : value,
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _digitsController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Últimos 4 dígitos (opcional)',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _limitController,
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
                    controller: _closingController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Fecha dia'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _dueController,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Criar')),
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
  final String? walletId;

  const _NewCardDraft({
    required this.name,
    required this.digits,
    required this.limit,
    required this.closingDay,
    required this.dueDay,
    required this.walletId,
  });
}
