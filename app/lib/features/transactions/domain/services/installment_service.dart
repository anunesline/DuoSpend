import '../models/installment_plan.dart';

class InstallmentService {
  const InstallmentService();

  InstallmentPlan createPlan({
    required String groupId,
    required double totalValue,
    required int installmentCount,
    required DateTime firstInstallmentDate,
  }) {
    final normalizedGroupId = groupId.trim();

    if (normalizedGroupId.isEmpty) {
      throw Exception(
        'O parcelamento precisa ter um identificador.',
      );
    }

    if (totalValue <= 0) {
      throw Exception(
        'O valor total do parcelamento deve ser maior que zero.',
      );
    }

    if (installmentCount <= 1) {
      throw Exception(
        'O parcelamento precisa ter pelo menos 2 parcelas.',
      );
    }

    final totalInCents = (totalValue * 100).round();
    final baseInstallmentInCents =
        totalInCents ~/ installmentCount;
    final remainderInCents =
        totalInCents % installmentCount;

    final installments = <InstallmentPlanItem>[];

    for (var index = 0; index < installmentCount; index++) {
      final number = index + 1;
      final extraCent =
          index < remainderInCents ? 1 : 0;

      final installmentValue =
          (baseInstallmentInCents + extraCent) / 100;

      installments.add(
        InstallmentPlanItem(
          number: number,
          totalInstallments: installmentCount,
          value: installmentValue,
          date: _addMonthsFromAnchor(
            firstInstallmentDate,
            index,
          ),
        ),
      );
    }

    return InstallmentPlan(
      groupId: normalizedGroupId,
      totalValue: totalInCents / 100,
      installmentCount: installmentCount,
      firstInstallmentDate: firstInstallmentDate,
      installments: List.unmodifiable(
        installments,
      ),
    );
  }

  DateTime _addMonthsFromAnchor(
    DateTime anchor,
    int monthsToAdd,
  ) {
    if (monthsToAdd <= 0) {
      return anchor;
    }

    final absoluteMonth =
        (anchor.year * 12 + anchor.month - 1) +
            monthsToAdd;

    final year = absoluteMonth ~/ 12;
    final month = absoluteMonth % 12 + 1;

    final day = _validDayForMonth(
      year: year,
      month: month,
      preferredDay: anchor.day,
    );

    return DateTime(
      year,
      month,
      day,
      anchor.hour,
      anchor.minute,
      anchor.second,
      anchor.millisecond,
      anchor.microsecond,
    );
  }

  int _validDayForMonth({
    required int year,
    required int month,
    required int preferredDay,
  }) {
    final lastDayOfMonth =
        DateTime(year, month + 1, 0).day;

    if (preferredDay > lastDayOfMonth) {
      return lastDayOfMonth;
    }

    return preferredDay;
  }
}
