class HouseholdScopeId {
  const HouseholdScopeId._();

  static String personal(String userId) => 'user:${userId.trim()}';

  static String shared(Iterable<String> memberIds) {
    final members = memberIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    if (members.length < 2) {
      throw ArgumentError('Uma casa compartilhada precisa de ao menos 2 membros.');
    }
    return 'household:${members.join('|')}';
  }
}
