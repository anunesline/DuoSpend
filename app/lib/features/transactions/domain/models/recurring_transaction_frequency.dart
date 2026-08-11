enum RecurringTransactionFrequency {
  daily('daily', 'Diária'),
  weekly('weekly', 'Semanal'),
  monthly('monthly', 'Mensal'),
  yearly('yearly', 'Anual');

  final String value;
  final String label;

  const RecurringTransactionFrequency(
    this.value,
    this.label,
  );

  factory RecurringTransactionFrequency.fromValue(
    dynamic value,
  ) {
    final normalizedValue = value?.toString().trim().toLowerCase();

    return RecurringTransactionFrequency.values.firstWhere(
      (frequency) => frequency.value == normalizedValue,
      orElse: () => RecurringTransactionFrequency.monthly,
    );
  }
}