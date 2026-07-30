import '../../../home/data/models/wallet_model.dart';
import '../models/shared_transaction_confirmation_status.dart';

class SharedTransactionConfirmationDecision {
  final SharedTransactionConfirmationStatus status;
  final DateTime? requestedAt;

  const SharedTransactionConfirmationDecision({
    required this.status,
    required this.requestedAt,
  });

  bool get canAffectSharedBalance {
    return status.canAffectSharedBalance;
  }

  bool get shouldSynchronizeSettlement {
    return status.canAffectSharedBalance;
  }

  bool get requiresPartnerConfirmation {
    return status.isPending;
  }
}

class SharedTransactionConfirmationService {
  const SharedTransactionConfirmationService();

  SharedTransactionConfirmationDecision resolve({
    required WalletModel wallet,
    required String transactionType,
    required bool hasFinancialSplit,
    required bool isSettlement,
  }) {
    if (_requiresConfirmation(
      wallet: wallet,
      transactionType: transactionType,
      hasFinancialSplit: hasFinancialSplit,
      isSettlement: isSettlement,
    )) {
      return SharedTransactionConfirmationDecision(
        status: SharedTransactionConfirmationStatus.pending,
        requestedAt: DateTime.now(),
      );
    }

    return const SharedTransactionConfirmationDecision(
      status: SharedTransactionConfirmationStatus.accepted,
      requestedAt: null,
    );
  }

  bool _requiresConfirmation({
    required WalletModel wallet,
    required String transactionType,
    required bool hasFinancialSplit,
    required bool isSettlement,
  }) {
    if (!wallet.isShared) {
      return false;
    }

    if (transactionType != 'expense') {
      return false;
    }

    if (!hasFinancialSplit) {
      return false;
    }

    if (isSettlement) {
      return false;
    }

    return true;
  }
}