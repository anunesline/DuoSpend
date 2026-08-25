import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  State<CreditCardsPage> createState() =>
      _CreditCardsPageState();
}

class _CreditCardsPageState extends State<CreditCardsPage> {
  late final CreditCardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CreditCardController();
    _controller.loadCards();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _money(double value) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(value);
  }

  String _walletName(String walletId) {
    for (final wallet in widget.individualWallets) {
      if (wallet.id == walletId) {
        return wallet.name;
      }
    }
    return 'Carteira vinculada';
  }

  Future<void> _openCreateCardDialog() async {
    if (widget.individualWallets.isEmpty) {
      _showMessage(
        'Crie uma carteira individual antes de adicionar um cartão.',
      );
      return;
    }

    final nameController = TextEditingController();
    final digitsController = TextEditingController();
    final limitController = TextEditingController();
    final closingController = TextEditingController();
    final dueController = TextEditingController();
    var selectedWalletId = widget.individualWallets.first.id;

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
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
                          .map(
                            (wallet) => DropdownMenuItem<String>(
                              value: wallet.id,
                              child: Text(wallet.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedWalletId = value;
                          });
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
                      keyboardType:
                          const TextInputType.numberWithOptions(
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
                            decoration: const InputDecoration(
                              labelText: 'Fecha dia',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: dueController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Vence dia',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Criar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldCreate != true || !mounted) {
      _disposeControllers([
        nameController,
        digitsController,
        limitController,
        closingController,
        dueController,
      ]);
      return;
    }

    final name = nameController.text.trim();
    final digits = digitsController.text.trim();
    final limit = _parseMoney(limitController.text);
    final closingDay = int.tryParse(closingController.text.trim());
    final dueDay = int.tryParse(dueController.text.trim());

    _disposeControllers([
      nameController,
      digitsController,
      limitController,
      closingController,
      dueController,
    ]);

    if (name.isEmpty ||
        limit == null ||
        closingDay == null ||
        dueDay == null) {
      _showMessage('Preencha os dados obrigatórios do cartão.');
      return;
    }

    final card = await _controller.createCard(
      name: name,
      walletId: selectedWalletId,
      creditLimit: limit,
      closingDay: closingDay,
      dueDay: dueDay,
      lastFourDigits: digits,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      card == null
          ? _controller.errorMessage ??
              'Não foi possível criar o cartão.'
          : 'Cartão criado.',
    );
  }

  Future<void> _payInvoice(
    CreditCardModel card,
    CreditCardInvoiceModel invoice,
  ) async {
    var selectedWalletId = card.walletId;

    final confirmedWalletId = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Pagar fatura'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'A fatura de ${_money(invoice.total)} será debitada da carteira escolhida.',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedWalletId,
                    decoration: const InputDecoration(
                      labelText: 'Pagar com',
                    ),
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
                        setDialogState(() {
                          selectedWalletId = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      selectedWalletId,
                    );
                  },
                  child: const Text('Pagar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmedWalletId == null || !mounted) {
      return;
    }

    final success = await _controller.payInvoice(
      card: card,
      invoice: invoice,
      walletId: confirmedWalletId,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'Fatura paga e limite liberado.'
          : _controller.errorMessage ??
              'Não foi possível pagar a fatura.',
    );
  }

  double? _parseMoney(String value) {
    return double.tryParse(
      value.trim().replaceAll('.', '').replaceAll(',', '.'),
    );
  }

  void _disposeControllers(
    Iterable<TextEditingController> controllers,
  ) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cartões e faturas'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _controller.isLoading
            ? null
            : _openCreateCardDialog,
        icon: const Icon(Icons.add_card_rounded),
        label: const Text('Novo cartão'),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading &&
              !_controller.hasCards) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!_controller.hasCards) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: const [
                SizedBox(height: 80),
                Icon(Icons.credit_card_off_rounded, size: 56),
                SizedBox(height: 16),
                Text(
                  'Nenhum cartão cadastrado',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Cadastre um cartão para organizar limites e faturas.',
                  textAlign: TextAlign.center,
                ),
              ],
            );
          }

          return RefreshIndicator(
            onRefresh: _controller.loadCards,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _controller.cards.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final card = _controller.cards[index];
                final invoices =
                    _controller.invoicesFor(card.id);

                return Card(
                  child: ExpansionTile(
                    onExpansionChanged: (expanded) {
                      if (expanded) {
                        _controller.loadInvoices(card.id);
                      }
                    },
                    leading:
                        const Icon(Icons.credit_card_rounded),
                    title: Text(
                      card.lastFourDigits == null
                          ? card.name
                          : '${card.name} •••• ${card.lastFourDigits}',
                    ),
                    subtitle: Text(
                      'Usado ${_money(card.usedLimit)} de '
                      '${_money(card.creditLimit)}\n'
                      'Vinculado a ${_walletName(card.walletId)}',
                    ),
                    isThreeLine: true,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: LinearProgressIndicator(
                          value: card.creditLimit <= 0
                              ? 0
                              : (card.usedLimit /
                                      card.creditLimit)
                                  .clamp(0, 1)
                                  .toDouble(),
                        ),
                      ),
                      if (_controller.isProcessing(card.id))
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        )
                      else if (invoices.isEmpty)
                        const ListTile(
                          title: Text('Nenhuma fatura encontrada.'),
                        )
                      else
                        ...invoices.map(
                          (invoice) => ListTile(
                            title: Text(
                              'Fatura ${invoice.referenceMonth.toString().padLeft(2, '0')}/${invoice.referenceYear}',
                            ),
                            subtitle: Text(
                              invoice.isPaid
                                  ? 'Paga'
                                  : 'Vence em '
                                      '${DateFormat('dd/MM/yyyy').format(invoice.dueDate)}',
                            ),
                            trailing: invoice.isPaid
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.green,
                                  )
                                : FilledButton.tonal(
                                    onPressed: _controller
                                            .isProcessing(
                                      '${card.id}:${invoice.id}',
                                    )
                                        ? null
                                        : () {
                                            _payInvoice(
                                              card,
                                              invoice,
                                            );
                                          },
                                    child: Text(
                                      _money(invoice.total),
                                    ),
                                  ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
