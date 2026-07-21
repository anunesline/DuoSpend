import 'balance_engine.dart';

/// Modelo simplificado utilizado pela interface.
///
/// Evita que a camada de apresentação conheça os detalhes
/// internos do BalanceEngine.
class BalanceSummary {
  final BalanceResult result;
  final String currentMemberId;

  const BalanceSummary({
    required this.result,
    required this.currentMemberId,
  });

  /// Saldo líquido do membro atual.
  double get balance {
    return result.balanceForMember(currentMemberId);
  }

  /// Valor que o membro ainda precisa pagar.
  double get amountToPay {
    return result.amountToPay(currentMemberId);
  }

  /// Valor que o membro tem para receber.
  double get amountToReceive {
    return result.amountToReceive(currentMemberId);
  }

  bool get hasDebt {
    return amountToPay > 0;
  }

  bool get hasCredit {
    return amountToReceive > 0;
  }

  bool get isSettled {
    return !hasDebt && !hasCredit;
  }

  /// Transferências necessárias para quitar os saldos.
  List<BalanceTransfer> get transfers {
    return result.transfers;
  }

  /// Quantidade de acertos pendentes.
  int get pendingTransfers {
    return transfers.length;
  }
}