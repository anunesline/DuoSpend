class InstallmentPlan {
  final String groupId;
  final double totalValue;
  final int installmentCount;
  final DateTime firstInstallmentDate;
  final List<InstallmentPlanItem> installments;

  const InstallmentPlan({
    required this.groupId,
    required this.totalValue,
    required this.installmentCount,
    required this.firstInstallmentDate,
    required this.installments,
  });

  DateTime get lastInstallmentDate {
    if (installments.isEmpty) {
      return firstInstallmentDate;
    }

    return installments.last.date;
  }

  double get totalInstallmentsValue {
    return installments.fold<double>(
      0,
      (sum, installment) => sum + installment.value,
    );
  }

  bool get isBalanced {
    return (totalInstallmentsValue - totalValue).abs() < 0.001;
  }
}

class InstallmentPlanItem {
  final int number;
  final int totalInstallments;
  final double value;
  final DateTime date;

  const InstallmentPlanItem({
    required this.number,
    required this.totalInstallments,
    required this.value,
    required this.date,
  });

  String get label {
    return '$number/$totalInstallments';
  }
}
