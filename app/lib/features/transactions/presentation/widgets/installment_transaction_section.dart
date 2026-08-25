import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class InstallmentTransactionSection extends StatelessWidget {
  final bool enabled;
  final bool isInstallment;
  final int installmentCount;
  final DateTime firstInstallmentDate;
  final ValueChanged<bool> onInstallmentChanged;
  final ValueChanged<int> onInstallmentCountChanged;
  final ValueChanged<DateTime> onFirstInstallmentDateChanged;

  const InstallmentTransactionSection({
    super.key,
    required this.enabled,
    required this.isInstallment,
    required this.installmentCount,
    required this.firstInstallmentDate,
    required this.onInstallmentChanged,
    required this.onInstallmentCountChanged,
    required this.onFirstInstallmentDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Parcelar'),
              subtitle: const Text(
                'Cria parcelas mensais a partir do valor total.',
              ),
              value: isInstallment,
              onChanged: enabled ? onInstallmentChanged : null,
            ),
            if (isInstallment) ...[
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<int>(
                initialValue: installmentCount,
                decoration: const InputDecoration(
                  labelText: 'Quantidade de parcelas',
                  prefixIcon: Icon(Icons.calendar_view_month_outlined),
                ),
                items: List.generate(23, (index) => index + 2)
                    .map(
                      (count) => DropdownMenuItem<int>(
                        value: count,
                        child: Text('$count parcelas'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: !enabled
                    ? null
                    : (count) {
                        if (count != null) {
                          onInstallmentCountChanged(count);
                        }
                      },
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: const Text('Primeira parcela'),
                subtitle: Text(_formatDate(firstInstallmentDate)),
                trailing: const Icon(Icons.chevron_right),
                onTap: !enabled
                    ? null
                    : () => _pickDate(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: firstInstallmentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      onFirstInstallmentDateChanged(selectedDate);
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
