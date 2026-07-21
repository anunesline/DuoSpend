import 'dart:collection';

class FinancialSplitResult {
  final String payerMemberId;
  final String purchaseFor;
  final String splitType;

  final Map<String, double> _memberShares;

  FinancialSplitResult({
    required this.payerMemberId,
    required this.purchaseFor,
    required this.splitType,
    required Map<String, double> memberShares,
  }) : _memberShares = Map<String, double>.unmodifiable(
         memberShares.map(
           (memberId, share) => MapEntry(
             memberId,
             _roundCurrency(share),
           ),
         ),
       );

  Map<String, double> get memberShares {
    return UnmodifiableMapView(_memberShares);
  }

  double get totalValue {
    return _roundCurrency(
      _memberShares.values.fold(
        0,
        (total, share) => total + share,
      ),
    );
  }

  double shareForMember(String memberId) {
    return _roundCurrency(
      _memberShares[memberId] ?? 0,
    );
  }

  double amountOwedToPayer(String memberId) {
    if (memberId == payerMemberId) {
      return 0;
    }

    return shareForMember(memberId);
  }

  double get amountPaidForOthers {
    var total = 0.0;

    for (final entry in _memberShares.entries) {
      if (entry.key != payerMemberId) {
        total += entry.value;
      }
    }

    return _roundCurrency(total);
  }

  bool containsMember(String memberId) {
    return _memberShares.containsKey(memberId);
  }

  FinancialSplitResult copyWith({
    String? payerMemberId,
    String? purchaseFor,
    String? splitType,
    Map<String, double>? memberShares,
  }) {
    return FinancialSplitResult(
      payerMemberId: payerMemberId ?? this.payerMemberId,
      purchaseFor: purchaseFor ?? this.purchaseFor,
      splitType: splitType ?? this.splitType,
      memberShares: memberShares ?? _memberShares,
    );
  }

  static double _roundCurrency(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}