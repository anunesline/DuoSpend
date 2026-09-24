import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../home/data/models/wallet_model.dart';
import '../../home/data/models/credit_card_model.dart';
import '../../home/data/repositories/wallet_repository.dart';
import '../../home/data/repositories/credit_card_repository.dart';
import '../../transactions/data/repositories/transaction_repository.dart';
import '../../wallet/presentation/pages/credit_cards_page.dart';
import '../data/financial_accounts_repository.dart';
import 'account_form_page.dart';
import 'finance_widgets.dart';

class AccountMovement {
  final String title, status;
  final double amount;
  final DateTime date;
  const AccountMovement(this.title, this.amount, this.date, this.status);
}

class AccountDetailPage extends StatefulWidget {
  final FinancialAccountsRepository repository;
  final WalletModel account;
  final Widget Function(BuildContext)? navigationBuilder;
  final bool valuesVisible;
  const AccountDetailPage({
    super.key,
    required this.repository,
    required this.account,
    this.navigationBuilder,
    this.valuesVisible = true,
  });
  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  late WalletModel _account = widget.account;
  List<WalletModel> _accounts = [];
  List<CreditCardModel> _cards = [];
  List<AccountMovement> _movements = [];
  bool _loading = true, _error = false, _primary = false, _busy = false;
  late bool _visible = widget.valuesVisible;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final repo = widget.repository;
      final accounts = await repo.loadAccounts();
      final account = accounts.firstWhere((a) => a.id == widget.account.id);
      final primaryId = await repo.loadPrimaryId();
      final cardRepo = CreditCardRepository(
        firestore: repo.firestore,
        auth: repo.auth,
      );
      final cards = await cardRepo.getCards();
      final transactions = await TransactionRepository(
        firestore: repo.firestore,
        auth: repo.auth,
      ).getTransactionsByWallet(account.id, wallet: account);
      final transfers = await repo.loadTransfers(account.id);
      final movements = <AccountMovement>[
        for (final t in transactions)
          AccountMovement(
            t.description,
            t.type == 'income' ? t.value : -t.value,
            t.date,
            t.isSettledByInvoice
                ? 'Na fatura • sem débito na conta'
                : t.isFinanciallyPending
                ? 'Pendente'
                : 'Concluída',
          ),
        for (final t in transfers)
          AccountMovement(
            t.fromId == account.id
                ? 'Transferência para ${t.toName}'
                : 'Transferência de ${t.fromName}',
            t.fromId == account.id ? -t.amount : t.amount,
            t.date,
            'Entre suas contas',
          ),
      ];
      // Invoice payments are real account debits, independent of today's card link.
      for (final card in cards) {
        final invoices = await cardRepo.getInvoices(cardId: card.id);
        for (final invoice in invoices) {
          if (invoice.isPaid &&
              invoice.paymentWalletId == account.id &&
              invoice.paidAt != null) {
            movements.add(
              AccountMovement(
                'Pagamento de fatura • ${card.name}',
                -invoice.total,
                invoice.paidAt!,
                'Concluída',
              ),
            );
          }
        }
      }
      movements.sort((a, b) => b.date.compareTo(a.date));
      if (!mounted) return;
      setState(() {
        _account = account;
        _accounts = accounts;
        _primary =
            WalletRepository.resolveHomeWallet(accounts, primaryId)?.id ==
            account.id;
        _cards = cards.where((c) => c.walletId == account.id).toList();
        _movements = movements;
        _loading = false;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = true;
        });
    }
  }

  Future<void> _edit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountFormPage(
          repository: widget.repository,
          kind: _account.accountKind,
          account: _account,
          isPrimary: _primary,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _more() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_account.isArchived) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar conta'),
                onTap: () => Navigator.pop(sheet, 'edit'),
              ),
              if (!_primary)
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: const Text('Usar como principal'),
                  onTap: () => Navigator.pop(sheet, 'primary'),
                ),
              ListTile(
                leading: const Icon(Icons.add_card),
                title: const Text('Vincular cartão'),
                onTap: () => Navigator.pop(sheet, 'link'),
              ),
            ] else
              ListTile(
                leading: const Icon(Icons.unarchive_outlined),
                title: const Text('Reativar conta'),
                onTap: () => Navigator.pop(sheet, 'restore'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      await _edit();
      return;
    }
    if (action == 'link') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LinkAccountCardsPage(
            repository: widget.repository,
            account: _account,
          ),
        ),
      );
      if (mounted) await _load();
      return;
    }
    setState(() => _busy = true);
    try {
      if (action == 'primary') await widget.repository.setPrimary(_account.id);
      if (action == 'restore')
        await widget.repository.setArchived(_account.id, false);
      if (mounted) await _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível concluir. Tente novamente.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _operation(bool transfer) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountOperationPage(
          repository: widget.repository,
          account: _account,
          destinations: _accounts
              .where((a) => !a.isArchived && a.id != _account.id)
              .toList(),
          transfer: transfer,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _statement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FinanceScaffold(
          title: 'Extrato • ${_account.name}',
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_movements.isEmpty)
                const OrbitHomeMessage(
                  message: 'Nenhuma movimentação registrada.',
                ),
              for (final movement in _movements) _movement(movement),
            ],
          ),
        ),
      ),
    );
  }

  Widget _movement(AccountMovement m) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: OrbitHomeSurface(
      child: Row(
        children: [
          OrbitHomeIcon(
            icon: m.amount >= 0 ? Icons.south_west : Icons.north_east,
            color: m.amount >= 0
                ? OrbitHomeTokens.green
                : OrbitHomeTokens.purple,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: OrbitHomeTokens.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('dd/MM/yyyy').format(m.date)} • ${m.status}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: OrbitHomeTokens.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  orbitMoney(m.amount, visible: _visible),
                  style: TextStyle(
                    fontSize: 14,
                    color: m.amount >= 0
                        ? OrbitHomeTokens.green
                        : OrbitHomeTokens.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget _info(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: OrbitHomeTokens.muted, fontSize: 12),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Text(
            value.isEmpty ? 'Não informado' : value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: OrbitHomeTokens.text, fontSize: 12),
          ),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => FinanceScaffold(
    title: 'Detalhe da conta',
    navigation: widget.navigationBuilder?.call(context),
    actions: [
      if (!_account.isArchived)
        TextButton(
          onPressed: _loading || _busy ? null : _edit,
          child: const Text('Editar'),
        ),
    ],
    child: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error
        ? FinanceError(retry: _load)
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              children: [
                Center(
                  child: OrbitHomeIcon(
                    icon: accountIcon(_account.accountKind),
                    color: accountColor(_account.accountKind),
                    size: 54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _account.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: OrbitHomeTokens.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_account.accountKind.label}${_primary ? ' • Principal' : ''}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: OrbitHomeTokens.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        orbitMoney(_account.balance, visible: _visible),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          color: OrbitHomeTokens.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _visible ? 'Ocultar saldo' : 'Mostrar saldo',
                      onPressed: () => setState(() => _visible = !_visible),
                      icon: Icon(
                        _visible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 19,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns =
                        MediaQuery.textScalerOf(context).scale(12) > 17 ? 2 : 4;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (icon, label, action)
                            in <(IconData, String, VoidCallback?)>[
                              (
                                Icons.sync_alt,
                                'Transferir',
                                _account.isArchived
                                    ? null
                                    : () => _operation(true),
                              ),
                              (
                                Icons.add_card,
                                'Depositar',
                                _account.isArchived
                                    ? null
                                    : () => _operation(false),
                              ),
                              (
                                Icons.receipt_long_outlined,
                                'Extrato',
                                _statement,
                              ),
                              (Icons.more_vert, 'Mais', _busy ? null : _more),
                            ])
                          SizedBox(
                            width:
                                (constraints.maxWidth - (columns - 1) * 8) /
                                columns,
                            child: OutlinedButton(
                              onPressed: action,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 3,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(icon, size: 22),
                                  const SizedBox(height: 6),
                                  Text(
                                    label,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                OrbitHomeSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informações da conta',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: OrbitHomeTokens.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _info('Tipo', _account.accountKind.label),
                      if (_account.accountKind == AccountKind.bank)
                        _info('Banco', _account.bank),
                      _info('Titular', _account.holder),
                      _info('PIX', _account.pix),
                      _info(
                        'Status',
                        _account.isArchived ? 'Arquivada' : 'Ativa',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OrbitHomeSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cartões vinculados',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: OrbitHomeTokens.text,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_cards.isEmpty)
                        const Text(
                          'Nenhum cartão vinculado.',
                          style: TextStyle(
                            color: OrbitHomeTokens.muted,
                            fontSize: 12,
                          ),
                        ),
                      for (final card in _cards)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: FinanceEntry(
                            icon: Icons.credit_card,
                            color: OrbitHomeTokens.purple,
                            title:
                                '${card.name}${card.lastFourDigits == null ? '' : ' •••• ${card.lastFourDigits}'}',
                            subtitle: card.isActive
                                ? 'Cartão de crédito • gerenciar cartões'
                                : 'Cartão inativo',
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreditCardsPage(
                                    individualWallets: _accounts
                                        .where((a) => !a.isArchived)
                                        .toList(),
                                  ),
                                ),
                              );
                              if (mounted) await _load();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OrbitHomeSectionTitle(
                  title: 'Últimas movimentações',
                  action: 'Ver todas',
                  onAction: _statement,
                ),
                const SizedBox(height: 8),
                if (_movements.isEmpty)
                  const OrbitHomeMessage(
                    message: 'Nenhuma movimentação registrada.',
                  ),
                for (final movement in _movements.take(5)) _movement(movement),
              ],
            ),
          ),
  );
}

class AccountOperationPage extends StatefulWidget {
  final FinancialAccountsRepository repository;
  final WalletModel account;
  final List<WalletModel> destinations;
  final bool transfer;
  const AccountOperationPage({
    super.key,
    required this.repository,
    required this.account,
    required this.destinations,
    required this.transfer,
  });
  @override
  State<AccountOperationPage> createState() => _AccountOperationPageState();
}

class _AccountOperationPageState extends State<AccountOperationPage> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  late final String _operationId = widget.repository.newOperationId();
  String? _destination, _error;
  bool _busy = false;
  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final amount = parseAccountMoney(_amount.text)!;
      if (widget.transfer) {
        await widget.repository.transfer(
          fromId: widget.account.id,
          toId: _destination!,
          amount: amount,
          operationId: _operationId,
        );
      } else {
        await widget.repository.deposit(
          id: widget.account.id,
          amount: amount,
          operationId: _operationId,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on StateError catch (e) {
      if (mounted)
        setState(() {
          _busy = false;
          _error = e.message;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _busy = false;
          _error = 'Não foi possível concluir. Tente novamente.';
        });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: FinanceScaffold(
      title: widget.transfer ? 'Transferir' : 'Depositar',
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.account.name,
              style: const TextStyle(fontSize: 19, color: OrbitHomeTokens.text),
            ),
            const SizedBox(height: 12),
            OrbitHomeMessage(
              message: widget.transfer
                  ? 'Registre uma transferência entre suas contas. Isso não é uma despesa.'
                  : 'Registre uma entrada de dinheiro nesta conta. Para mover dinheiro de outra conta sua, use Transferir.',
            ),
            const SizedBox(height: 16),
            if (widget.transfer && widget.destinations.isEmpty)
              const OrbitHomeMessage(
                message: 'Adicione outra conta ativa para transferir.',
              )
            else ...[
              if (widget.transfer) ...[
                DropdownButtonFormField<String>(
                  initialValue: _destination,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Conta de destino',
                  ),
                  items: [
                    for (final a in widget.destinations)
                      DropdownMenuItem(
                        value: a.id,
                        child: Text(a.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _destination = value),
                  validator: (value) =>
                      value == null ? 'Escolha uma conta.' : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _amount,
                enabled: !_busy,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                  hintText: '0,00',
                ),
                validator: (value) {
                  final amount = parseAccountMoney(value ?? '');
                  return amount == null || amount <= 0
                      ? 'Informe um valor positivo, como 50,00.'
                      : null;
                },
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: OrbitHomeTokens.red),
                  ),
                ),
              const SizedBox(height: 20),
              FinanceButton(
                label: _busy ? 'Registrando…' : 'Confirmar registro',
                onPressed: _busy ? null : _save,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
