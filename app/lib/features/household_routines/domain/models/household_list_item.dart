import 'household_list.dart';

enum HouseholdListItemStatus { pending, purchased }

class HouseholdListItem {
  final String id;
  final String listId;
  final String scopeId;
  final String displayName;
  final String identityKey;
  final HouseholdListItemStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? completedBy;
  final num? quantity;
  final String? unit;
  final String? financialReferenceId;

  const HouseholdListItem({
    required this.id,
    required this.listId,
    required this.scopeId,
    required this.displayName,
    required this.identityKey,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.completedBy,
    this.quantity,
    this.unit,
    this.financialReferenceId,
  });

  bool get isPurchased => status == HouseholdListItemStatus.purchased;

  HouseholdListItem markPurchased({
    required DateTime at,
    String? by,
    String? financialReferenceId,
  }) =>
      HouseholdListItem(
        id: id,
        listId: listId,
        scopeId: scopeId,
        displayName: displayName,
        identityKey: identityKey,
        status: HouseholdListItemStatus.purchased,
        createdAt: createdAt,
        updatedAt: at,
        completedAt: at,
        completedBy: by,
        quantity: quantity,
        unit: unit,
        financialReferenceId:
            financialReferenceId ?? this.financialReferenceId,
      );

  HouseholdListItem markPending(DateTime at) => HouseholdListItem(
        id: id,
        listId: listId,
        scopeId: scopeId,
        displayName: displayName,
        identityKey: identityKey,
        status: HouseholdListItemStatus.pending,
        createdAt: createdAt,
        updatedAt: at,
        quantity: quantity,
        unit: unit,
        financialReferenceId: financialReferenceId,
      );

  HouseholdListItem edit({
    required String displayName,
    required String identityKey,
    num? quantity,
    String? unit,
    required DateTime updatedAt,
  }) =>
      HouseholdListItem(
        id: id,
        listId: listId,
        scopeId: scopeId,
        displayName: displayName,
        identityKey: identityKey,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
        completedAt: completedAt,
        completedBy: completedBy,
        quantity: quantity,
        unit: unit,
        financialReferenceId: financialReferenceId,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'listId': listId,
        'scopeId': scopeId,
        'displayName': displayName,
        'identityKey': identityKey,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'completedBy': completedBy,
        'quantity': quantity,
        'unit': unit,
        'financialReferenceId': financialReferenceId,
      };

  factory HouseholdListItem.fromMap(Map<String, dynamic> map) => HouseholdListItem(
        id: map['id']?.toString() ?? '',
        listId: map['listId']?.toString() ?? '',
        scopeId: map['scopeId']?.toString() ?? '',
        displayName: map['displayName']?.toString() ?? map['name']?.toString() ?? '',
        identityKey: map['identityKey']?.toString() ??
            HouseholdListItemIdentity.normalize(
              map['displayName']?.toString() ?? map['name']?.toString() ?? '',
            ),
        status: HouseholdListItemStatus.values.firstWhere(
          (value) => value.name == map['status']?.toString(),
          orElse: () => HouseholdListItemStatus.pending,
        ),
        createdAt: householdListDateFromValue(map['createdAt']) ?? DateTime.now(),
        updatedAt: householdListDateFromValue(map['updatedAt']) ?? DateTime.now(),
        completedAt: householdListDateFromValue(map['completedAt']),
        completedBy: map['completedBy']?.toString(),
        quantity: map['quantity'] as num?,
        unit: map['unit']?.toString(),
        financialReferenceId: map['financialReferenceId']?.toString(),
      );
}

class HouseholdListItemPurchaseEvent {
  final String id;
  final String itemId;
  final String listId;
  final String scopeId;
  final String displayName;
  final String identityKey;
  final DateTime purchasedAt;
  final String? purchasedBy;
  final String? source;
  final String? sourceReferenceId;

  const HouseholdListItemPurchaseEvent({
    required this.id,
    required this.itemId,
    required this.listId,
    required this.scopeId,
    required this.displayName,
    required this.identityKey,
    required this.purchasedAt,
    this.purchasedBy,
    this.source,
    this.sourceReferenceId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'itemId': itemId,
        'listId': listId,
        'scopeId': scopeId,
        'displayName': displayName,
        'identityKey': identityKey,
        'purchasedAt': purchasedAt.toIso8601String(),
        'purchasedBy': purchasedBy,
        'source': source,
        'sourceReferenceId': sourceReferenceId,
      };

  factory HouseholdListItemPurchaseEvent.fromMap(Map<String, dynamic> map) =>
      HouseholdListItemPurchaseEvent(
        id: map['id']?.toString() ?? '',
        itemId: map['itemId']?.toString() ?? '',
        listId: map['listId']?.toString() ?? '',
        scopeId: map['scopeId']?.toString() ?? '',
        displayName: map['displayName']?.toString() ?? '',
        identityKey: map['identityKey']?.toString() ?? '',
        purchasedAt: householdListDateFromValue(map['purchasedAt']) ?? DateTime.now(),
        purchasedBy: map['purchasedBy']?.toString(),
        source: map['source']?.toString(),
        sourceReferenceId: map['sourceReferenceId']?.toString(),
      );
}

class HouseholdListItemIdentity {
  const HouseholdListItemIdentity._();

  static String normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');
}
