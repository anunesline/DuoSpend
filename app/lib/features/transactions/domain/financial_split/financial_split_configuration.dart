import 'dart:collection';

class FinancialSplitConfiguration {
  final bool isFinancialSplitAvailable;
  final bool hasPartner;

  final String currentUserMemberId;
  final String? partnerMemberId;

  final List<String> _allowedPayerMemberIds;
  final List<String> _allowedPurchaseDestinations;
  final List<String> _allowedSplitTypes;

  final String defaultPayerMemberId;
  final String defaultPurchaseDestination;
  final String defaultSplitType;

  FinancialSplitConfiguration({
    required this.isFinancialSplitAvailable,
    required this.hasPartner,
    required this.currentUserMemberId,
    required this.partnerMemberId,
    required List<String> allowedPayerMemberIds,
    required List<String> allowedPurchaseDestinations,
    required List<String> allowedSplitTypes,
    required this.defaultPayerMemberId,
    required this.defaultPurchaseDestination,
    required this.defaultSplitType,
  }) : _allowedPayerMemberIds = List<String>.unmodifiable(
         allowedPayerMemberIds,
       ),
       _allowedPurchaseDestinations = List<String>.unmodifiable(
         allowedPurchaseDestinations,
       ),
       _allowedSplitTypes = List<String>.unmodifiable(
         allowedSplitTypes,
       );

  List<String> get allowedPayerMemberIds {
    return UnmodifiableListView(_allowedPayerMemberIds);
  }

  List<String> get allowedPurchaseDestinations {
    return UnmodifiableListView(
      _allowedPurchaseDestinations,
    );
  }

  List<String> get allowedSplitTypes {
    return UnmodifiableListView(_allowedSplitTypes);
  }

  bool get canSelectPayer {
    return _allowedPayerMemberIds.length > 1;
  }

  bool get canSelectPurchaseDestination {
    return _allowedPurchaseDestinations.length > 1;
  }

  bool get canSelectSplitType {
    return _allowedSplitTypes.length > 1;
  }

  bool isPayerAllowed(String memberId) {
    return _allowedPayerMemberIds.contains(
      memberId.trim(),
    );
  }

  bool isPurchaseDestinationAllowed(
    String purchaseDestination,
  ) {
    return _allowedPurchaseDestinations.contains(
      purchaseDestination,
    );
  }

  bool isSplitTypeAllowed(String splitType) {
    return _allowedSplitTypes.contains(splitType);
  }

  String resolvePayerMemberId(String? selectedMemberId) {
    final normalizedMemberId =
        selectedMemberId?.trim() ?? '';

    if (isPayerAllowed(normalizedMemberId)) {
      return normalizedMemberId;
    }

    return defaultPayerMemberId;
  }

  String resolvePurchaseDestination(
    String? selectedPurchaseDestination,
  ) {
    if (selectedPurchaseDestination != null &&
        isPurchaseDestinationAllowed(
          selectedPurchaseDestination,
        )) {
      return selectedPurchaseDestination;
    }

    return defaultPurchaseDestination;
  }

  String resolveSplitType(String? selectedSplitType) {
    if (selectedSplitType != null &&
        isSplitTypeAllowed(selectedSplitType)) {
      return selectedSplitType;
    }

    return defaultSplitType;
  }
}