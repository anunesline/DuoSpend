class CreditCardInvoiceModel {
  static const String openStatus = 'open';
  static const String closedStatus = 'closed';
  static const String paidStatus = 'paid';

  final String id;
  final String cardId;
  final String ownerMemberId;
  final int referenceYear;
  final int referenceMonth;
  final DateTime closingDate;
  final DateTime dueDate;
  final double total;
  final String status;
  final DateTime? paidAt;
  final String? paymentWalletId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CreditCardInvoiceModel({
    required this.id,
    required this.cardId,
    required this.ownerMemberId,
    required this.referenceYear,
    required this.referenceMonth,
    required this.closingDate,
    required this.dueDate,
    this.total = 0,
    this.status = openStatus,
    this.paidAt,
    this.paymentWalletId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOpen => status == openStatus;
  bool get isClosed => status == closedStatus;
  bool get isPaid => status == paidStatus;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cardId': cardId,
      'ownerMemberId': ownerMemberId,
      'referenceYear': referenceYear,
      'referenceMonth': referenceMonth,
      'closingDate': closingDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'total': total,
      'status': status,
      'paidAt': paidAt?.toIso8601String(),
      'paymentWalletId': paymentWalletId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CreditCardInvoiceModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final now = DateTime.now();

    return CreditCardInvoiceModel(
      id: map['id']?.toString() ?? '',
      cardId: map['cardId']?.toString() ?? '',
      ownerMemberId: map['ownerMemberId']?.toString() ?? '',
      referenceYear: _parseInt(map['referenceYear']),
      referenceMonth: _parseInt(map['referenceMonth']),
      closingDate: _parseDateTime(map['closingDate']) ?? now,
      dueDate: _parseDateTime(map['dueDate']) ?? now,
      total: _parseDouble(map['total']),
      status: map['status']?.toString() ?? openStatus,
      paidAt: _parseDateTime(map['paidAt']),
      paymentWalletId:
          _parseNullableString(map['paymentWalletId']),
      createdAt: _parseDateTime(map['createdAt']) ?? now,
      updatedAt: _parseDateTime(map['updatedAt']) ?? now,
    );
  }

  static String? _parseNullableString(dynamic value) {
    final normalized = value?.toString().trim();
    return normalized == null || normalized.isEmpty
        ? null
        : normalized;
  }

  static int _parseInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    return DateTime.tryParse(value?.toString() ?? '');
  }
}
