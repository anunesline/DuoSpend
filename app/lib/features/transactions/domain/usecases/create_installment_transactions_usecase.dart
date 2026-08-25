import '../../data/models/transaction_model.dart';
import '../services/installment_service.dart';

class CreateInstallmentTransactionsUseCase {
  final InstallmentService _installmentService;

  const CreateInstallmentTransactionsUseCase({
    InstallmentService installmentService =
        const InstallmentService(),
  }) : _installmentService = installmentService;

  List<TransactionModel> execute({
    required TransactionModel transaction,
    required int installmentCount,
    required DateTime firstInstallmentDate,
    String? installmentGroupId,
  }) {
    if (transaction.isRecurring) {
      throw Exception(
        'Uma transação não pode ser recorrente e parcelada ao mesmo tempo.',
      );
    }

    final normalizedGroupId =
        installmentGroupId?.trim().isNotEmpty == true
            ? installmentGroupId!.trim()
            : transaction.id;

    final plan = _installmentService.createPlan(
      groupId: normalizedGroupId,
      totalValue: transaction.value,
      installmentCount: installmentCount,
      firstInstallmentDate: firstInstallmentDate,
    );

    return List<TransactionModel>.unmodifiable(
      plan.installments.map(
        (installment) {
          final installmentId =
              '${transaction.id}-installment-${installment.number}';

          return transaction.copyWith(
            id: installmentId,
            value: installment.value,
            date: installment.date,
            isInstallment: true,
            installmentCount: plan.installmentCount,
            installmentNumber: installment.number,
            installmentGroupId: plan.groupId,
            items: installment.number == 1
                ? transaction.items
                : const [],
          );
        },
      ),
    );
  }
}
