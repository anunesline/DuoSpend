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
  /// Esse valor será utilizado posteriormente no cálculo
  /// do saldo e no acerto de contas.
  double get amountPaidForOthers {
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
      date: DateTime.tryParse(
            map['date']?.toString() ?? '',
          ) ??
          DateTime.now(),
      walletId: map['walletId']?.toString() ?? 'principal',
      consumerId: map['consumerId']?.toString(),
      paidByMemberId: map['paidByMemberId']?.toString(),
      purchaseFor: map['purchaseFor']?.toString() ?? 'self',
      splitType: map['splitType']?.toString() ?? 'none',
      memberShares: _parseMemberShares(rawMemberShares),
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

  static Map<String, double> _parseMemberShares(dynamic rawValue) {
    if (rawValue is! Map) {
      return const {};
    }

    final result = <String, double>{};

    for (final entry in rawValue.entries) {
      final memberId = entry.key.toString();

      if (memberId.isEmpty) {
        continue;
      }

      result[memberId] = _parseDouble(entry.value);
    }

    return result;
  }
}