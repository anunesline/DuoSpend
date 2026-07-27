import 'dart:collection';

import 'financial_responsibility.dart';

class FinancialSplitResult {
  final String payerMemberId;
  final String purchaseFor;
  final String splitType;

  final List<FinancialResponsibility> _responsibilities;

  late final Map<String, double> _memberShares =
      Map<String, double>.unmodifiable({
        for (final responsibility in _responsibilities)
          responsibility.memberId: responsibility.amount,
      });

  FinancialSplitResult({
    required String payerMemberId,
    required this.purchaseFor,
    required this.splitType,
    List<FinancialResponsibility>? responsibilities,
    Map<String, double>? memberShares,
  })  : payerMemberId = _normalizeMemberId(payerMemberId),
        _responsibilities =
            List<FinancialResponsibility>.unmodifiable(
          _resolveResponsibilities(
            payerMemberId: payerMemberId,
            responsibilities: responsibilities,
            memberShares: memberShares,
          ),
        ) {
    _validateResponsibilities();
  }

  List<FinancialResponsibility> get responsibilities {
    return _responsibilities;
  }

  Map<String, double> get memberShares {
    return UnmodifiableMapView(_memberShares);
  }

  double get totalValue {
    return _roundCurrency(
      _responsibilities.fold<double>(
        0,
        (total, responsibility) {
          return total + responsibility.amount;
        },
      ),
    );
  }

  double shareForMember(String memberId) {
    final responsibility =
        responsibilityForMember(memberId);

    return responsibility?.amount ?? 0;
  }

  FinancialResponsibility? responsibilityForMember(
    String memberId,
  ) {
    final normalizedMemberId = memberId.trim();

    for (final responsibility in _responsibilities) {
      if (responsibility.memberId == normalizedMemberId) {
        return responsibility;
      }
    }

    return null;
  }

  double amountOwedToPayer(String memberId) {
    final responsibility =
        responsibilityForMember(memberId);

    if (responsibility == null ||
        responsibility.isPayer) {
      return 0;
    }

    return responsibility.amount;
  }

  double get amountPaidForOthers {
    return _roundCurrency(
      _responsibilities
          .where(
            (responsibility) =>
                responsibility.owesPayer,
          )
          .fold<double>(
            0,
            (total, responsibility) {
              return total + responsibility.amount;
            },
          ),
    );
  }

  bool containsMember(String memberId) {
    return responsibilityForMember(memberId) != null;
  }

  FinancialSplitResult copyWith({
    String? payerMemberId,
    String? purchaseFor,
    String? splitType,
    List<FinancialResponsibility>? responsibilities,
    Map<String, double>? memberShares,
  }) {
    if (responsibilities != null &&
        memberShares != null) {
      throw ArgumentError(
        'Informe responsibilities ou memberShares, nunca os dois.',
      );
    }

    return FinancialSplitResult(
      payerMemberId:
          payerMemberId ?? this.payerMemberId,
      purchaseFor: purchaseFor ?? this.purchaseFor,
      splitType: splitType ?? this.splitType,
      responsibilities:
          responsibilities ??
          (memberShares == null
              ? _responsibilities
              : null),
      memberShares: memberShares,
    );
  }

  void _validateResponsibilities() {
    if (_responsibilities.isEmpty) {
      throw ArgumentError(
        'A divisão financeira precisa ter pelo menos um responsável.',
      );
    }

    final memberIds = <String>{};

    for (final responsibility in _responsibilities) {
      if (!memberIds.add(responsibility.memberId)) {
        throw ArgumentError(
          'Cada membro pode aparecer apenas uma vez na divisão financeira.',
        );
      }

      final shouldBePayer =
          responsibility.memberId == payerMemberId;

      if (responsibility.isPayer != shouldBePayer) {
        throw ArgumentError(
          'A identificação do pagador não corresponde às responsabilidades financeiras.',
        );
      }
    }

    if (!memberIds.contains(payerMemberId)) {
      throw ArgumentError(
        'O pagador precisa fazer parte da divisão financeira.',
      );
    }
  }

  static List<FinancialResponsibility>
      _resolveResponsibilities({
    required String payerMemberId,
    required List<FinancialResponsibility>?
        responsibilities,
    required Map<String, double>? memberShares,
  }) {
    if (responsibilities != null &&
        memberShares != null) {
      throw ArgumentError(
        'Informe responsibilities ou memberShares, nunca os dois.',
      );
    }

    if (responsibilities == null &&
        memberShares == null) {
      throw ArgumentError(
        'Informe as responsabilidades da divisão financeira.',
      );
    }

    final normalizedPayerMemberId =
        _normalizeMemberId(payerMemberId);

    if (responsibilities != null) {
      return responsibilities;
    }

    return memberShares!.entries.map(
      (entry) {
        final memberId =
            _normalizeMemberId(entry.key);

        return FinancialResponsibility(
          memberId: memberId,
          amount: entry.value,
          isPayer:
              memberId == normalizedPayerMemberId,
        );
      },
    ).toList();
  }

  static String _normalizeMemberId(String value) {
    final normalizedValue = value.trim();

    if (normalizedValue.isEmpty) {
      throw ArgumentError(
        'O membro da divisão financeira precisa ter um memberId.',
      );
    }

    return normalizedValue;
  }

  static double _roundCurrency(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}