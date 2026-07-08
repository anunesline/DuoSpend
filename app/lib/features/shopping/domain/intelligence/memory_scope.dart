enum MemoryScopeType {
  individual,
  shared,
  household,
  family,
}

class MemoryScope {
  final MemoryScopeType type;
  final String ownerId;

  const MemoryScope({
    required this.type,
    required this.ownerId,
  });

  bool get isIndividual => type == MemoryScopeType.individual;

  bool get isShared => type == MemoryScopeType.shared;

  bool get isHousehold => type == MemoryScopeType.household;

  bool get isFamily => type == MemoryScopeType.family;
}