import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_card.dart';
import '../../../../core/design_system/duo_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/services/transaction_maintenance_service.dart';

class TransactionDetailResult {
  final TransactionModel? transaction;
  final bool deleted;

  const TransactionDetailResult.updated(TransactionModel value)
      : transaction = value,
        deleted = false;

  const TransactionDetailResult.deleted()
      : transaction = null,
        deleted = true;
}

class TransactionDetailPage extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailPage({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  final TransactionMaintenanceService _maintenanceService =
      TransactionMaintenanceService();
  late TransactionModel _transaction;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
  }

  bool get _isIncome => _transaction.type == 'income';

  String get _formattedValue {
    final prefix = _isIncome ? '+' : '-';
    return '$prefix R\$ ${_transaction.value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _editTransaction() async {
    if (_processing) return;

    final descriptionController =
        TextEditingController(text: _transaction.description);
    final valueController = TextEditingController(
      text: _transaction.value.toStringAsFixed(2).replaceAll('.', ','),
    );
    final categoryController = TextEditingController(text: _transaction.category);
    final subcategoryController =
        TextEditingController(text: _transaction.subcategory);
    final notesController = TextEditingController(text: _transaction.notes ?? '');
    var selectedDate = _transaction.date;

    final draft = await showDialog<_TransactionEditDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar transação'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Valor',
                    prefixText: 'R\$ ',
                    helperText: _transaction.paymentMethod == 'creditCard'
                        ? 'Valor de compra no crédito é controlado pela fatura.'
                        : _transaction.hasFinancialSplit
                            ? 'Para mudar o valor, refaça a divisão financeira.'
                            : null,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month_rounded),
                  title: const Text('Data'),
                  subtitle: Text(_formatDate(selectedDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null && dialogContext.mounted) {
                      setDialogState(() {
                        selectedDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          selectedDate.hour,
                          selectedDate.minute,
                        );
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subcategoryController,
                  decoration: const InputDecoration(labelText: 'Subcategoria'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Observações',
                  ),
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
                  _TransactionEditDraft(
                    description: descriptionController.text,
                    value: valueController.text,
                    date: selectedDate,
                    category: categoryController.text,
                    subcategory: subcategoryController.text,
                    notes: notesController.text,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 320));
    descriptionController.dispose();
    valueController.dispose();
    categoryController.dispose();
    subcategoryController.dispose();
    notesController.dispose();

    if (draft == null || !mounted) return;
    final value = double.tryParse(
      draft.value.trim().replaceAll('.', '').replaceAll(',', '.'),
    );
    if (value == null || value <= 0 || draft.description.trim().isEmpty) {
      _showMessage('Confira descrição e valor.');
      return;
    }

    setState(() => _processing = true);
    try {
      final updated = await _maintenanceService.updateTransaction(
        original: _transaction,
        description: draft.description,
        value: value,
        date: draft.date,
        category: draft.category,
        subcategory: draft.subcategory,
        notes: draft.notes,
      );
      if (!mounted) return;
      setState(() {
        _transaction = updated;
        _processing = false;
      });
      Navigator.pop(context, TransactionDetailResult.updated(updated));
    } catch (error) {
      if (!mounted) return;
      setState(() => _processing = false);
      _showMessage(
        error
            .toString()
            .replaceFirst('Bad state: ', '')
            .replaceFirst('Invalid argument(s): ', '')
            .replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _deleteTransaction() async {
    if (_processing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir transação?'),
        content: Text(
          '“${_transaction.description}” será removida do histórico. '
          'Se ela já movimentou saldo, o valor será estornado automaticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _processing = true);
    try {
      await _maintenanceService.deleteTransaction(_transaction);
      if (!mounted) return;
      Navigator.pop(context, const TransactionDetailResult.deleted());
    } catch (error) {
      if (!mounted) return;
      setState(() => _processing = false);
      _showMessage(
        error
            .toString()
            .replaceFirst('Bad state: ', '')
            .replaceFirst('Invalid argument(s): ', '')
            .replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.background,
      appBar: AppBar(
        title: const Text('Detalhes'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              _transaction.description,
              style: const TextStyle(
                color: DuoColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _formattedValue,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _isIncome ? DuoColors.success : DuoColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            DuoCard(
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.swap_vert,
                    label: 'Tipo',
                    value: _isIncome ? 'Receita' : 'Despesa',
                  ),
                  const Divider(),
                  _DetailRow(
                    icon: Icons.calendar_today,
                    label: 'Data',
                    value: _formatDate(_transaction.date),
                  ),
                  const Divider(),
                  _DetailRow(
                    icon: Icons.access_time,
                    label: 'Horário',
                    value: _formatTime(_transaction.date),
                  ),
                  const Divider(),
                  _DetailRow(
                    icon: Icons.category_outlined,
                    label: 'Categoria',
                    value: _transaction.subcategory.isEmpty
                        ? _transaction.category
                        : '${_transaction.category} • ${_transaction.subcategory}',
                  ),
                  if ((_transaction.notes ?? '').trim().isNotEmpty) ...[
                    const Divider(),
                    _DetailRow(
                      icon: Icons.notes_rounded,
                      label: 'Observações',
                      value: _transaction.notes!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: _processing ? null : _editTransaction,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Editar transação'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _processing ? null : _deleteTransaction,
              icon: _processing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              label: const Text('Excluir transação'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: DuoColors.primaryLight),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: const TextStyle(color: DuoColors.textSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: DuoColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionEditDraft {
  final String description;
  final String value;
  final DateTime date;
  final String category;
  final String subcategory;
  final String notes;

  const _TransactionEditDraft({
    required this.description,
    required this.value,
    required this.date,
    required this.category,
    required this.subcategory,
    required this.notes,
  });
}
