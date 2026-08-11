import '../../domain/models/shared_transaction_confirmation_status.dart';
import 'transaction_item_model.dart';

class TransactionModel {
  final String id;
  final String description;
  final double value;
  final String type; // income | expense
  final DateTime date;
  final String walletId;

  /// Consumidor relacionado à compra.
  ///
  /// Mantido para compatibilidade com o fluxo de consumidores
  /// e com transações criadas antes da Sprint 18.5.
  final String? consumerId;

  /// Identificador do membro da carteira que realizou o pagamento.
  ///
  /// Em carteiras compartilhadas, normalmente corresponde
  /// ao UID do usuário pagador.
  ///
  /// Pode ser nulo em transações antigas.
  final String? paidByMemberId;

  /// Indica para quem a compra foi realizada.
  ///
  /// Valores esperados:
  /// - self: compra destinada ao próprio pagador;
  /// - partner: compra destinada ao outro membro;
  /// - both: compra destinada aos dois membros.
  ///
  /// O valor padrão é self para preservar o comportamento
  /// das transações individuais já existentes.
  final String purchaseFor;

  /// Define como o valor da transação foi dividido.
  ///
  /// Valores esperados:
  /// - none: não existe divisão financeira;
  /// - equal: valor dividido igualmente entre os membros;
  /// - custom: divisão personalizada.
  final String splitType;

  /// Valor financeiro atribuído a cada membro da carteira.
  ///
  /// A chave corresponde ao identificador do membro
  /// e o valor representa a parte da transação atribuída a ele.
  ///
  /// Exemplo:
  /// {
  ///   'user-1': 50.0,
  ///   'user-2': 50.0,
  /// }
  final Map<String, double> memberShares;

  /// Estado da confirmação bilateral da despesa compartilhada.
  ///
  /// Transações antigas são consideradas aceitas por padrão,
  /// preservando o comportamento financeiro existente antes
  /// da Sprint 20.5.
  final SharedTransactionConfirmationStatus confirmationStatus;

  /// Momento em que a confirmação bilateral foi solicitada
  /// ao outro membro da carteira.
  ///
  /// Pode ser nulo em transações individuais, settlements
  /// ou transações antigas.
  final DateTime? confirmationRequestedAt;

  /// Momento em que a confirmação bilateral recebeu
  /// uma decisão definitiva.
  ///
  /// É preenchido tanto em aceitações quanto em recusas.
  final DateTime? confirmationResolvedAt;

  /// Identificador do membro que aceitou ou recusou
  /// a despesa compartilhada.
  final String? confirmationRespondedByMemberId;

  /// Indica que esta transação representa o pagamento
  /// de um acerto financeiro entre membros da carteira.
  ///
  /// Transações antigas recebem false por padrão.
  final bool isSettlement;

  /// Identificador do acerto financeiro que originou
  /// esta transação.
  ///
  /// Permite rastrear o pagamento e impedir que o mesmo
  /// acerto gere mais de uma transação.
  final String? settlementId;

  /// Indica se esta transação pertence a uma série recorrente.
  ///
  /// Transações antigas recebem false por padrão.
  final bool isRecurring;

  /// Identificador da série recorrente.
  ///
  /// Todas as ocorrências geradas a partir da mesma
  /// configuração compartilham este identificador.
  final String? recurringId;

  /// Frequência configurada para a recorrência.
  ///
  /// Valores esperados:
  /// - daily: diária;
  /// - weekly: semanal;
  /// - monthly: mensal;
  /// - yearly: anual.
  final String? recurringFrequency;

  /// Data de início da recorrência.
  ///
  /// Representa a primeira data válida para geração
  /// das ocorrências da série.
  final DateTime? recurringStartDate;

  /// Data final da recorrência.
  ///
  /// Pode ser nula quando a recorrência nunca expira.
  final DateTime? recurringEndDate;

  /// Indica que a recorrência não possui data final.
  ///
  /// Quando verdadeiro, recurringEndDate deve ser ignorada.
  final bool recurringNeverEnds;

  final String category;
  final String subcategory;
  final List<TransactionItemModel> items;

  TransactionModel({
    required this.id,
    required this.description,
    required this.value,
    required this.type,
    required this.date,
    required this.walletId,
    this.consumerId,
    this.paidByMemberId,
    this.purchaseFor = 'self',
    this.splitType = 'none',
    this.memberShares = const {},
    this.confirmationStatus =
        SharedTransactionConfirmationStatus.accepted,
    this.confirmationRequestedAt,
    this.confirmationResolvedAt,
    this.confirmationRespondedByMemberId,
    this.isSettlement = false,
    this.settlementId,
    this.isRecurring = false,
    this.recurringId,
    this.recurringFrequency,
    this.recurringStartDate,
    this.recurringEndDate,
    this.recurringNeverEnds = true,
    required this.category,
    required this.subcategory,
    this.items = const [],
  });

  /// Retorna verdadeiro quando a transação possui
  /// algum tipo de divisão entre membros.
  bool get hasFinancialSplit {
    return splitType != 'none' && memberShares.isNotEmpty;
  }

  /// Retorna verdadeiro quando a compra foi destinada
  /// aos dois membros da carteira.
  bool get isForBoth {
    return purchaseFor == 'both';
  }

  /// Retorna verdadeiro quando a transação representa
  /// uma despesa compartilhada entre membros.
  bool get isSharedExpense {
    return type == 'expense' &&
        !isSettlement &&
        hasFinancialSplit &&
        isForBoth;
  }

  /// Indica que a despesa compartilhada ainda aguarda
  /// a decisão do outro membro.
  bool get isAwaitingConfirmation {
    return isSharedExpense && confirmationStatus.isPending;
  }

  /// Indica que a confirmação bilateral já recebeu
  /// uma decisão definitiva.
  bool get hasConfirmationDecision {
    return confirmationStatus.isResolved;
  }

  /// Indica que a divisão financeira desta transação
  /// pode impactar os saldos entre os membros.
  ///
  /// Transações sem divisão financeira continuam válidas
  /// normalmente. Despesas compartilhadas somente produzem
  /// impacto definitivo após serem aceitas.
  bool get canAffectSharedBalance {
    if (!hasFinancialSplit) {
      return true;
    }

    return confirmationStatus.canAffectSharedBalance;
  }

  /// Retorna verdadeiro quando existe um vínculo válido
  /// com um acerto financeiro.
  bool get hasSettlementReference {
    final normalizedSettlementId = settlementId?.trim();

    return isSettlement &&
        normalizedSettlementId != null &&
        normalizedSettlementId.isNotEmpty;
  }

  /// Retorna o valor atribuído a um membro específico.
  ///
  /// Caso o membro não esteja presente na divisão,
  /// retorna zero.
  double shareForMember(String memberId) {
    return memberShares[memberId] ?? 0;
  }

  /// Retorna quanto o pagador desembolsou em benefício
  /// dos demais membros.
  ///
  /// Despesas compartilhadas pendentes ou recusadas
  /// não geram responsabilidade financeira definitiva.
  double get amountPaidForOthers {
    if (!canAffectSharedBalance) {
      return 0;
    }

    final payerId = paidByMemberId;

    if (payerId == null || payerId.isEmpty) {
      return 0;
    }

    final payerShare = shareForMember(payerId);
    final amount = value - payerShare;

    if (amount <= 0) {
      return 0;
    }

    return amount;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'value': value,
      'type': type,
      'date': date.toIso8601String(),
      'walletId': walletId,
      'consumerId': consumerId,
      'paidByMemberId': paidByMemberId,
      'purchaseFor': purchaseFor,
      'splitType': splitType,
      'memberShares': memberShares,
      'confirmationStatus': confirmationStatus.value,
      'confirmationRequestedAt':
          confirmationRequestedAt?.toIso8601String(),
      'confirmationResolvedAt':
          confirmationResolvedAt?.toIso8601String(),
      'confirmationRespondedByMemberId':
          confirmationRespondedByMemberId,
      'isSettlement': isSettlement,
      'settlementId': settlementId,
      'isRecurring': isRecurring,
      'recurringId': recurringId,
      'recurringFrequency': recurringFrequency,
      'recurringStartDate':
          recurringStartDate?.toIso8601String(),
      'recurringEndDate':
          recurringEndDate?.toIso8601String(),
      'recurringNeverEnds': recurringNeverEnds,
      'category': category,
      'subcategory': subcategory,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  factory TransactionModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final rawItems = map['items'];
    final rawMemberShares = map['memberShares'];

    return TransactionModel(
      id: map['id']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      value: _parseDouble(map['value']),
      type: map['type']?.toString() ?? 'expense',
      date: _parseDateTime(map['date']) ?? DateTime.now(),
      walletId: map['walletId']?.toString() ?? 'principal',
      consumerId: map['consumerId']?.toString(),
      paidByMemberId: map['paidByMemberId']?.toString(),
      purchaseFor: map['purchaseFor']?.toString() ?? 'self',
      splitType: map['splitType']?.toString() ?? 'none',
      memberShares: _parseMemberShares(rawMemberShares),
      confirmationStatus:
          SharedTransactionConfirmationStatus.fromValue(
        map['confirmationStatus'],
      ),
      confirmationRequestedAt:
          _parseDateTime(map['confirmationRequestedAt']),
      confirmationResolvedAt:
          _parseDateTime(map['confirmationResolvedAt']),
      confirmationRespondedByMemberId:
          map['confirmationRespondedByMemberId']?.toString(),
      isSettlement: _parseBool(map['isSettlement']),
      settlementId: map['settlementId']?.toString(),
      isRecurring: _parseBool(map['isRecurring']),
      recurringId: map['recurringId']?.toString(),
      recurringFrequency:
          map['recurringFrequency']?.toString(),
      recurringStartDate:
          _parseDateTime(map['recurringStartDate']),
      recurringEndDate:
          _parseDateTime(map['recurringEndDate']),
      recurringNeverEnds:
          map['recurringNeverEnds'] == null
              ? true
              : _parseBool(map['recurringNeverEnds']),
      category: map['category']?.toString() ?? 'Sem categoria',
      subcategory:
          map['subcategory']?.toString() ?? 'Sem subcategoria',
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(TransactionItemModel.fromMap)
              .toList()
          : const [],
    );
  }

  TransactionModel copyWith({
    String? id,
    String? description,
    double? value,
    String? type,
    DateTime? date,
    String? walletId,
    String? consumerId,
    String? paidByMemberId,
    String? purchaseFor,
    String? splitType,
    Map<String, double>? memberShares,
    SharedTransactionConfirmationStatus? confirmationStatus,
    DateTime? confirmationRequestedAt,
    DateTime? confirmationResolvedAt,
    String? confirmationRespondedByMemberId,
    bool? isSettlement,
    String? settlementId,
    bool? isRecurring,
    String? recurringId,
    String? recurringFrequency,
    DateTime? recurringStartDate,
    DateTime? recurringEndDate,
    bool? recurringNeverEnds,
    String? category,
    String? subcategory,
    List<TransactionItemModel>? items,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      description: description ?? this.description,
      value: value ?? this.value,
      type: type ?? this.type,
      date: date ?? this.date,
      walletId: walletId ?? this.walletId,
      consumerId: consumerId ?? this.consumerId,
      paidByMemberId: paidByMemberId ?? this.paidByMemberId,
      purchaseFor: purchaseFor ?? this.purchaseFor,
      splitType: splitType ?? this.splitType,
      memberShares: memberShares ?? this.memberShares,
      confirmationStatus:
          confirmationStatus ?? this.confirmationStatus,
      confirmationRequestedAt:
          confirmationRequestedAt ?? this.confirmationRequestedAt,
      confirmationResolvedAt:
          confirmationResolvedAt ?? this.confirmationResolvedAt,
      confirmationRespondedByMemberId:
          confirmationRespondedByMemberId ??
              this.confirmationRespondedByMemberId,
      isSettlement: isSettlement ?? this.isSettlement,
      settlementId: settlementId ?? this.settlementId,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
      recurringFrequency:
          recurringFrequency ?? this.recurringFrequency,
      recurringStartDate:
          recurringStartDate ?? this.recurringStartDate,
      recurringEndDate:
          recurringEndDate ?? this.recurringEndDate,
      recurringNeverEnds:
          recurringNeverEnds ?? this.recurringNeverEnds,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      items: items ?? this.items,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    return value?.toString().toLowerCase() == 'true';
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }

  static Map<String, double> _parseMemberShares(dynamic rawValue) {
    if (rawValue is! Map) {
      return const {};
    }

    final result = <String, double>{};

    for (final entry in rawValue.entries) {
      final memberId = entry.key.toString().trim();

      if (memberId.isEmpty) {
        continue;
      }

      result[memberId] = _parseDouble(entry.value);
    }

    return result;
  }
}
