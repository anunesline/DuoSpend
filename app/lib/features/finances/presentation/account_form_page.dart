import 'package:flutter/material.dart';

import '../../home/data/models/wallet_model.dart';
import '../../home/data/models/credit_card_model.dart';
import '../../home/data/repositories/credit_card_repository.dart';
import '../data/financial_accounts_repository.dart';
import 'finance_widgets.dart';

class AccountKindPage extends StatelessWidget {
  const AccountKindPage({super.key});
  @override
  Widget build(BuildContext context) => FinanceScaffold(
    title: 'Adicionar conta',
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Qual tipo de conta você quer adicionar?',
          style: TextStyle(color: OrbitHomeTokens.muted),
        ),
        const SizedBox(height: 16),
        for (final kind in AccountKind.values)
          Padding(
            padding: const EdgeInsets.only(bottom: OrbitHomeTokens.gap),
            child: FinanceEntry(
              icon: accountIcon(kind),
              color: accountColor(kind),
              title: kind.label,
              subtitle: switch (kind) {
                AccountKind.bank => 'Conta corrente, poupança ou conta digital',
                AccountKind.digital => 'Dinheiro em uma carteira digital',
                AccountKind.cash => 'Dinheiro em espécie',
                AccountKind.other => 'Outros lugares onde você guarda dinheiro',
              },
              onTap: () => Navigator.pop(context, kind),
            ),
          ),
        const SizedBox(height: 14),
        const OrbitHomeMessage(
          message: 'Você pode vincular cartões depois. Cartão é um meio de pagamento; conta ou carteira é onde o dinheiro está.',
        ),
      ],
    ),
  );
}

class AccountFormPage extends StatefulWidget {
  final FinancialAccountsRepository repository;
  final AccountKind kind;
  final WalletModel? account;
  final bool isPrimary;
  const AccountFormPage({
    super.key,
    required this.repository,
    required this.kind,
    this.account,
    this.isPrimary = false,
  });
  @override
  State<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends State<AccountFormPage> {
  final _form = GlobalKey<FormState>();
  late final _creationId = widget.repository.newOperationId();
  late final _name = TextEditingController(text: widget.account?.name ?? '');
  late final _bank = TextEditingController(text: widget.account?.bank ?? '');
  late final _holder = TextEditingController(
    text:
        widget.account?.holder ??
        widget.repository.auth.currentUser?.displayName ??
        '',
  );
  late final _pix = TextEditingController(text: widget.account?.pix ?? '');
  final _balance = TextEditingController();
  late AccountKind _kind = widget.kind;
  bool _primary = false, _busy = false;
  String? _error;
  @override
  void dispose() {
    for (final c in [_name, _bank, _holder, _pix, _balance]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Preencha este campo.' : null;

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final account = await widget.repository.save(
        id: widget.account?.id,
        creationId: _creationId,
        name: _name.text,
        kind: _kind,
        bank: _bank.text,
        holder: _holder.text,
        pix: _pix.text,
        initialBalance: parseAccountMoney(_balance.text) ?? 0,
        primary: _primary,
      );
      if (!mounted) return;
      if (widget.account == null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LinkAccountCardsPage(
              repository: widget.repository,
              account: account,
            ),
          ),
        );
      }
      if (mounted) Navigator.pop(context, account);
    } catch (_) {
      if (mounted)
        setState(() {
          _busy = false;
          _error =
              'Não foi possível salvar. Confira sua conexão e tente novamente.';
        });
    }
  }

  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Arquivar conta?'),
        content: const Text(
          'O histórico será preservado. A conta sairá do patrimônio total e deixará de ser usada como principal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Arquivar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.setArchived(widget.account!.id, true);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        setState(() {
          _busy = false;
          _error = 'Não foi possível arquivar. Tente novamente.';
        });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: FinanceScaffold(
      title: widget.account == null
          ? (_kind == AccountKind.other
                ? 'Nova conta'
                : 'Nova ${_kind.label.toLowerCase()}')
          : 'Editar conta',
      actions: [
        TextButton(
          onPressed: _busy ? null : _save,
          child: const Text('Salvar'),
        ),
      ],
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Preencha as informações da conta.',
              style: TextStyle(color: OrbitHomeTokens.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Nome da conta'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AccountKind>(
              initialValue: _kind,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Tipo da conta'),
              items: [
                for (final kind in AccountKind.values)
                  DropdownMenuItem(value: kind, child: Text(kind.label)),
              ],
              onChanged: _busy ? null : (kind) => setState(() => _kind = kind!),
            ),
            if (_kind == AccountKind.bank) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _bank,
                enabled: !_busy,
                decoration: const InputDecoration(labelText: 'Banco'),
                validator: _required,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _holder,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Titular'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pix,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'PIX (opcional)'),
            ),
            const SizedBox(height: 12),
            if (widget.account == null)
              TextFormField(
                controller: _balance,
                enabled: !_busy,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Saldo inicial (opcional)',
                  hintText: '0,00',
                  prefixText: 'R\$ ',
                ),
                validator: (v) => parseAccountMoney(v ?? '') == null
                    ? 'Use um valor como 1.234,56.'
                    : null,
              )
            else
              const OrbitHomeMessage(
                message: 'O saldo é atualizado pelas movimentações. Editar o cadastro mantém o saldo atual.',
              ),
            const SizedBox(height: 8),
            if (widget.isPrimary)
              const OrbitHomeMessage(
                message: 'Esta é sua conta principal na Home.',
              )
            else
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Usar como principal',
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: const Text(
                  'Mostrar o saldo desta conta na Home Solo.',
                  style: TextStyle(fontSize: 12),
                ),
                value: _primary,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _primary = value),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: OrbitHomeTokens.red),
                ),
              ),
            const SizedBox(height: 12),
            FinanceButton(
              label: _busy ? 'Salvando…' : 'Salvar conta',
              onPressed: _busy ? null : _save,
            ),
            if (widget.account != null)
              TextButton.icon(
                onPressed: _busy ? null : _archive,
                icon: const Icon(
                  Icons.delete_outline,
                  color: OrbitHomeTokens.red,
                ),
                label: const Text(
                  'Arquivar conta',
                  style: TextStyle(color: OrbitHomeTokens.red),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class LinkAccountCardsPage extends StatefulWidget {
  final FinancialAccountsRepository repository;
  final WalletModel account;
  const LinkAccountCardsPage({
    super.key,
    required this.repository,
    required this.account,
  });
  @override
  State<LinkAccountCardsPage> createState() => _LinkAccountCardsPageState();
}

class _LinkAccountCardsPageState extends State<LinkAccountCardsPage> {
  late final _cards = CreditCardRepository(
    firestore: widget.repository.firestore,
    auth: widget.repository.auth,
  );
  List<CreditCardModel> _items = [];
  String? _selected, _error;
  bool _loading = true, _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cards = await _cards.getActiveCards();
      if (mounted)
        setState(() {
          _items = cards
              .where(
                (c) => c.walletId == null || c.walletId == widget.account.id,
              )
              .toList();
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Não foi possível carregar os cartões.';
        });
    }
  }

  Future<void> _link() async {
    if (_selected == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final card = await _cards.getCardById(_selected!);
      if (card == null ||
          !card.isActive ||
          (card.walletId != null && card.walletId != widget.account.id)) {
        throw StateError('O vínculo do cartão mudou.');
      }
      await _cards.updateCard(card: card.copyWith(walletId: widget.account.id));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted)
        setState(() {
          _busy = false;
          _error = 'Não foi possível vincular o cartão. Atualize a lista e tente novamente.';
        });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: FinanceScaffold(
      title: 'Vincular cartão',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Selecione um cartão para vincular a esta conta.',
                  style: TextStyle(color: OrbitHomeTokens.muted),
                ),
                const SizedBox(height: 16),
                if (_items.isEmpty && _error == null)
                  const OrbitHomeMessage(
                    message: 'Nenhum cartão disponível. Você pode cadastrar um depois em Finanças → Cartões.',
                  ),
                for (final card in _items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: OrbitHomeSurface(
                      onTap: _busy
                          ? null
                          : () => setState(() => _selected = card.id),
                      child: Row(
                        children: [
                          const OrbitHomeIcon(
                            icon: Icons.credit_card,
                            color: OrbitHomeTokens.purple,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${card.name}${card.lastFourDigits == null ? '' : ' •••• ${card.lastFourDigits}'}',
                            ),
                          ),
                          Icon(
                            _selected == card.id
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: OrbitHomeTokens.purple,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                const OrbitHomeMessage(
                  message: 'O cartão é um meio de pagamento. Compras no crédito não descontam o saldo da conta; o pagamento da fatura movimenta a conta escolhida.',
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: OrbitHomeTokens.red),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _load,
                    child: const Text('Atualizar lista'),
                  ),
                ],
                const SizedBox(height: 16),
                FinanceButton(
                  label: 'Vincular cartão',
                  onPressed: _busy || _selected == null ? null : _link,
                ),
                TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: const Text('Pular por enquanto'),
                ),
              ],
            ),
    ),
  );
}
