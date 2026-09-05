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

  static List<String> members(String scopeId) {
    final normalized = scopeId.trim();
    if (normalized.startsWith('user:')) {
      final userId = normalized.substring('user:'.length).trim();
      return userId.isEmpty ? const [] : [userId];
    }
    if (!normalized.startsWith('household:')) return const [];
    final members = normalized
        .substring('household:'.length)
        .split('|')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return List.unmodifiable(members);
  }
}
