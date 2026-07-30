enum SharedTransactionConfirmationStatus {
  /// A despesa compartilhada foi criada, mas ainda aguarda
  /// a decisão do outro membro da carteira.
  pending,

  /// O outro membro aceitou a despesa compartilhada.
  ///
  /// A partir deste estado, a divisão financeira pode
  /// impactar definitivamente os saldos entre os membros.
  accepted,

  /// O outro membro recusou a despesa compartilhada.
  ///
  /// A despesa não deve impactar os saldos compartilhados
  /// enquanto permanecer neste estado.
  rejected;

  /// Converte o estado de confirmação para o valor
  /// persistido no banco de dados.
  String get value {
    switch (this) {
      case SharedTransactionConfirmationStatus.pending:
        return 'pending';
      case SharedTransactionConfirmationStatus.accepted:
        return 'accepted';
      case SharedTransactionConfirmationStatus.rejected:
        return 'rejected';
    }
  }

  /// Indica que a despesa ainda aguarda uma decisão.
  bool get isPending {
    return this == SharedTransactionConfirmationStatus.pending;
  }

  /// Indica que a despesa compartilhada foi aceita.
  bool get isAccepted {
    return this == SharedTransactionConfirmationStatus.accepted;
  }

  /// Indica que a despesa compartilhada foi recusada.
  bool get isRejected {
    return this == SharedTransactionConfirmationStatus.rejected;
  }

  /// Indica que a confirmação já recebeu uma decisão final.
  bool get isResolved {
    return isAccepted || isRejected;
  }

  /// Indica que a divisão financeira pode impactar
  /// definitivamente os saldos compartilhados.
  bool get canAffectSharedBalance {
    return isAccepted;
  }

  /// Converte o valor persistido no banco para o estado
  /// correspondente do domínio.
  ///
  /// Transações antigas que não possuem confirmação
  /// bilateral são consideradas aceitas para preservar
  /// o comportamento financeiro já existente.
  static SharedTransactionConfirmationStatus fromValue(
    dynamic value, {
    SharedTransactionConfirmationStatus fallback =
        SharedTransactionConfirmationStatus.accepted,
  }) {
    final normalizedValue = value?.toString().trim().toLowerCase();

    switch (normalizedValue) {
      case 'pending':
        return SharedTransactionConfirmationStatus.pending;
      case 'accepted':
        return SharedTransactionConfirmationStatus.accepted;
      case 'rejected':
        return SharedTransactionConfirmationStatus.rejected;
      default:
        return fallback;
    }
  }
}