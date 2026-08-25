import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class RecurringTransactionSection extends StatelessWidget {
  final bool enabled;
  final bool isRecurring;
  final String recurringFrequency;
  final DateTime recurringStartDate;
  final DateTime? recurringEndDate;
  final bool recurringNeverEnds;
  final ValueChanged<bool> onRecurringChanged;
  final ValueChanged<String> onFrequencyChanged;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final ValueChanged<bool> onNeverEndsChanged;

  const RecurringTransactionSection({
    super.key,
    required this.enabled,
    required this.isRecurring,
    required this.recurringFrequency,
    required this.recurringStartDate,
    required this.recurringEndDate,
    required this.recurringNeverEnds,
    required this.onRecurringChanged,
    required this.onFrequencyChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onNeverEndsChanged,
  });

  static const Map<String, String> _frequencyLabels = {
    'daily': 'Diária',
    'weekly': 'Semanal',
    'monthly': 'Mensal',
    'yearly': 'Anual',
  };

  Future<void> _selectStartDate(
    BuildContext context,
  ) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: recurringStartDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) {
      return;
    }

    onStartDateChanged(selectedDate);
  }

  Future<void> _selectEndDate(
    BuildContext context,
  ) async {
    final initialDate =
        recurringEndDate ?? recurringStartDate;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(recurringStartDate)
          ? recurringStartDate
          : initialDate,
      firstDate: recurringStartDate,
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) {
      return;
    }

    onEndDateChanged(selectedDate);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: isRecurring,
              onChanged: enabled ? onRecurringChanged : null,
              title: const Text('Transação recorrente'),
              subtitle: const Text(
                'Repita automaticamente esta despesa ou receita.',
              ),
            ),
            if (isRecurring) ...[
              const SizedBox(
                height: AppSpacing.md,
              ),
              DropdownButtonFormField<String>(
                initialValue: recurringFrequency,
                decoration: const InputDecoration(
                  labelText: 'Frequência',
                ),
                items: _frequencyLabels.entries
                    .map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: enabled
                    ? (value) {
                        if (value != null) {
                          onFrequencyChanged(value);
                        }
                      }
                    : null,
              ),
              const SizedBox(
                height: AppSpacing.md,
              ),
              _DateField(
                label: 'Data de início',
                value: _formatDate(recurringStartDate),
                icon: Icons.calendar_today_outlined,
                enabled: enabled,
                onTap: () => _selectStartDate(context),
              ),
              const SizedBox(
                height: AppSpacing.sm,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: recurringNeverEnds,
                onChanged: enabled
                    ? (value) {
                        if (value == null) {
                          return;
                        }

                        onNeverEndsChanged(value);

                        if (value) {
                          onEndDateChanged(null);
                        }
                      }
                    : null,
                title: const Text('Nunca expira'),
                controlAffinity:
                    ListTileControlAffinity.leading,
              ),
              if (!recurringNeverEnds) ...[
                const SizedBox(
                  height: AppSpacing.sm,
                ),
                _DateField(
                  label: 'Data de término',
                  value: recurringEndDate == null
                      ? 'Selecionar data'
                      : _formatDate(recurringEndDate!),
                  icon: Icons.event_available_outlined,
                  enabled: enabled,
                  onTap: () => _selectEndDate(context),
                ),
              ],
              const SizedBox(
                height: AppSpacing.sm,
              ),
              Text(
                'A recorrência será validada antes de salvar.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(icon),
          enabled: enabled,
        ),
        child: Text(value),
      ),
    );
  }
}