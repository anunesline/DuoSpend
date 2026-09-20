import 'package:flutter/material.dart';

import '../../home/data/models/wallet_model.dart';
import '../../home/data/repositories/wallet_repository.dart';
import '../data/financial_accounts_repository.dart';
import 'account_detail_page.dart';
import 'account_form_page.dart';
import 'finance_widgets.dart';

class AccountsPage extends StatefulWidget {
  final FinancialAccountsRepository repository;
  final Widget Function(BuildContext)? navigationBuilder;
  final bool valuesVisible;
  const AccountsPage({
    super.key,
    required this.repository,
    this.navigationBuilder,
    this.valuesVisible = true,
  });
  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  List<WalletModel> _accounts = [];
  String? _primaryId;
  bool _loading = true, _error = false, _archived = false;
  late bool _visible = widget.valuesVisible;
  int _filter = 0;
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
      final accounts = await widget.repository.loadAccounts();
      final primary = await widget.repository.loadPrimaryId();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _primaryId = primary;
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

  Future<void> _add() async {
    final kind = await Navigator.push<AccountKind>(
      context,
      MaterialPageRoute(builder: (_) => const AccountKindPage()),
    );
    if (kind == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AccountFormPage(repository: widget.repository, kind: kind),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _detail(WalletModel account) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountDetailPage(
          repository: widget.repository,
          account: account,
          navigationBuilder: widget.navigationBuilder,
          valuesVisible: _visible,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final active = _accounts.where((a) => !a.isArchived).toList();
    final primary = WalletRepository.resolveHomeWallet(active, _primaryId);
    final listed = _accounts.where((a) => a.isArchived == _archived).toList();
    final shown = _accounts
        .where(
          (a) =>
              a.isArchived == _archived &&
              (_filter == 0 ||
                  (_filter == 1
                      ? a.accountKind == AccountKind.bank
                      : a.accountKind != AccountKind.bank)),
        )
        .toList();
    final total = active.fold(0.0, (value, a) => value + a.balance);
    return FinanceScaffold(
      title: 'Contas e carteiras',
      navigation: widget.navigationBuilder?.call(context),
      actions: [
        PopupMenuButton<bool>(
          tooltip: 'Mais opções',
          onSelected: (value) => setState(() => _archived = value),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: !_archived,
              child: Text(_archived ? 'Ver contas ativas' : 'Ver arquivadas'),
            ),
          ],
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
          ? FinanceError(retry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                children: [
                  const Text(
                    'Gerencie onde o seu dinheiro está.',
                    style: TextStyle(
                      color: OrbitHomeTokens.muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OrbitHomeSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Patrimônio total',
                                style: TextStyle(
                                  color: OrbitHomeTokens.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: _visible
                                  ? 'Ocultar valores'
                                  : 'Mostrar valores',
                              onPressed: () =>
                                  setState(() => _visible = !_visible),
                              icon: Icon(
                                _visible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 19,
                                color: OrbitHomeTokens.purple,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          orbitMoney(total, visible: _visible),
                          style: const TextStyle(
                            fontSize: 25,
                            color: OrbitHomeTokens.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Saldo das suas contas e carteiras ativas',
                          style: TextStyle(
                            color: OrbitHomeTokens.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final (index, label) in [
                        (0, 'Todas (${listed.length})'),
                        (
                          1,
                          'Contas (${listed.where((a) => a.accountKind == AccountKind.bank).length})',
                        ),
                        (
                          2,
                          'Carteiras (${listed.where((a) => a.accountKind != AccountKind.bank).length})',
                        ),
                      ])
                        ChoiceChip(
                          label: Text(label),
                          selected: _filter == index,
                          onSelected: (_) => setState(() => _filter = index),
                        ),
                    ],
                  ),
                  if (_archived)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Arquivadas • fora do patrimônio total',
                        style: TextStyle(color: OrbitHomeTokens.muted),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (shown.isEmpty)
                    const OrbitHomeMessage(
                      message: 'Nenhuma conta ou carteira nesta lista.',
                    ),
                  for (final account in shown)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: OrbitHomeTokens.gap,
                      ),
                      child: FinanceEntry(
                        icon: accountIcon(account.accountKind),
                        color: accountColor(account.accountKind),
                        title: account.name,
                        subtitle:
                            '${account.accountKind.label}${account.id == primary?.id ? ' • Principal' : ''}${account.isArchived ? ' • Arquivada' : ''}',
                        amount: orbitMoney(account.balance, visible: _visible),
                        onTap: () => _detail(account),
                      ),
                    ),
                  const SizedBox(height: 8),
                  FinanceButton(
                    label: '+  Adicionar conta ou carteira',
                    onPressed: _add,
                    outlined: true,
                  ),
                ],
              ),
            ),
    );
  }
}
