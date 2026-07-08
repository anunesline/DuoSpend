enum CognitionScopeType {
  individual,
  shared,
  household,
  family,
  system,
}

class CognitionScope {
  final CognitionScopeType type;
  final String ownerId;

  const CognitionScope({
    required this.type,
    required this.ownerId,
  });

  bool get isIndividual => type == CognitionScopeType.individual;
  bool get isShared => type == CognitionScopeType.shared;
  bool get isHousehold => type == CognitionScopeType.household;
  bool get isFamily => type == CognitionScopeType.family;
  bool get isSystem => type == CognitionScopeType.system;
}