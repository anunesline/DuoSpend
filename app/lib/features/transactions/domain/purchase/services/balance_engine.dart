import '../../../data/models/transaction_model.dart';

/// Motor responsável por calcular o saldo financeiro
/// entre os membros de uma carteira compartilhada.
class BalanceEngine {
  static const double _minimumAmount = 0.01;

  const BalanceEngine();

  /// Calcula o saldo de cada membro e gera os acertos necessários.
  ///
  /// Saldo positivo:
  /// o membro tem dinheiro a receber.
  ///
  /// Saldo negativo:
  /// o membro deve dinheiro.
  BalanceResult calculate({
    required List<TransactionModel> transactions,
    String? walletId,
  }) {
    final balances = <String, double>{};

    for (final transaction in transactions) {
      if (!_shouldIncludeTransaction(
        transaction: transaction,
        walletId: walletId,
      )) {
        continue;
      }

      final payerId = transaction.paidByMemberId!;

      final validShares = <String, double>{};

      for (final entry in transaction.memberShares.entries) {
        final memberId = entry.key.trim();
        final share = _roundCurrency(entry.value);

        if (memberId.isEmpty || share <= 0) {
          continue;
        }

        validShares[memberId] = share;
      }

      if (validShares.isEmpty) {
        continue;
      }

      final totalAssigned = validShares.values.fold<double>(
        0,
        (total, share) => total + share,
      );

      /// O pagador desembolsou o valor atribuído aos participantes.
      balances[payerId] = (balances[payerId] ?? 0) + totalAssigned;

      /// Cada participante assume a própria parte da transação.
      for (final entry in validShares.entries) {
        balances[entry.key] =
            (balances[entry.key] ?? 0) - entry.value;
      }
    }

    final normalizedBalances = <String, double>{};

    for (final entry in balances.entries) {
      final amount = _roundCurrency(entry.value);

      normalizedBalances[entry.key] =
          amount.abs() < _minimumAmount ? 0 : amount;
    }

    final transfers = _buildTransfers(normalizedBalances);

    return BalanceResult(
      memberBalances: normalizedBalances,
      transfers: transfers,
    );
  }

  bool _shouldIncludeTransaction({
    required TransactionModel transaction,
    required String? walletId,
  }) {
    if (transaction.type != 'expense') {
      return false;
    }

    if (walletId != null &&
        walletId.isNotEmpty &&
        transaction.walletId != walletId) {
      return false;
    }

    final payerId = transaction.paidByMemberId;

    if (payerId == null || payerId.trim().isEmpty) {
      return false;
    }

    if (!transaction.hasFinancialSplit) {
      return false;
    }

    return true;
  }

  List<BalanceTransfer> _buildTransfers(
    Map<String, double> balances,
  ) {
    final debtors = <_MutableBalance>[];
    final creditors = <_MutableBalance>[];

    for (final entry in balances.entries) {
      final amount = _roundCurrency(entry.value);

      if (amount <= -_minimumAmount) {
        debtors.add(
          _MutableBalance(
            memberId: entry.key,
            amount: amount.abs(),
          ),
        );
      } else if (amount >= _minimumAmount) {
        creditors.add(
          _MutableBalance(
            memberId: entry.key,
            amount: amount,
          ),
        );
      }
    }

    debtors.sort(
      (first, second) => second.amount.compareTo(first.amount),
    );

    creditors.sort(
      (first, second) => second.amount.compareTo(first.amount),
    );

    final transfers = <BalanceTransfer>[];

    var debtorIndex = 0;
    var creditorIndex = 0;

    while (debtorIndex < debtors.length &&
        creditorIndex < creditors.length) {
      final debtor = debtors[debtorIndex];
      final creditor = creditors[creditorIndex];

      final transferAmount = _roundCurrency(
        debtor.amount < creditor.amount
            ? debtor.amount
            : creditor.amount,
      );

      if (transferAmount >= _minimumAmount) {
        transfers.add(
          BalanceTransfer(
            fromMemberId: debtor.memberId,
            toMemberId: creditor.memberId,
            amount: transferAmount,
          ),
        );
      }

      debtor.amount = _roundCurrency(
        debtor.amount - transferAmount,
      );

      creditor.amount = _roundCurrency(
        creditor.amount - transferAmount,
      );

      if (debtor.amount < _minimumAmount) {
        debtorIndex++;
      }

      if (creditor.amount < _minimumAmount) {
        creditorIndex++;
      }
    }

    return List.unmodifiable(transfers);
  }

  static double _roundCurrency(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}

/// Resultado completo produzido pelo Balance Engine.
class BalanceResult {
  /// Saldo líquido de cada membro.
  ///
  /// Positivo significa que o membro deve receber.
  /// Negativo significa que o membro deve pagar.
  final Map<String, double> memberBalances;

  /// Transferências necessárias para zerar os saldos.
  final List<BalanceTransfer> transfers;

  const BalanceResult({
    required this.memberBalances,
    required this.transfers,
  });

  /// Indica se existe algum acerto pendente.
  bool get hasPendingTransfers {
    return transfers.isNotEmpty;
  }

  /// Retorna o saldo líquido de um membro.
  double balanceForMember(String memberId) {
    return memberBalances[memberId] ?? 0;
  }

  /// Retorna quanto um membro precisa pagar.
  double amountToPay(String memberId) {
    final balance = balanceForMember(memberId);

    if (balance >= 0) {
      return 0;
    }

    return balance.abs();
  }

  /// Retorna quanto um membro precisa receber.
  double amountToReceive(String memberId) {
    final balance = balanceForMember(memberId);

    if (balance <= 0) {
      return 0;
    }

    return balance;
  }
}

/// Representa um pagamento necessário entre dois membros.
class BalanceTransfer {
  final String fromMemberId;
  final String toMemberId;
  final double amount;

  const BalanceTransfer({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
  });
}

class _MutableBalance {
  final String memberId;
  double amount;

  _MutableBalance({
    required this.memberId,
    required this.amount,
  });
}