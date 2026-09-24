import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/orbit_personality.dart';

abstract class OrbitPersonalityKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SharedPreferencesOrbitPersonalityStore
    implements OrbitPersonalityKeyValueStore {
  @override
  Future<String?> read(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String key, String value) async {
    await (await SharedPreferences.getInstance()).setString(key, value);
  }
}

class OrbitPersonalityPreferences {
  OrbitPersonalityPreferences({OrbitPersonalityKeyValueStore? store})
    : _store = store ?? SharedPreferencesOrbitPersonalityStore();

  static final instance = OrbitPersonalityPreferences();
  static const _recentLimit = 3;
  final OrbitPersonalityKeyValueStore _store;

  Future<OrbitPersonality?> loadPersonality(String userId) async {
    final value = await _store.read(_personalityKey(userId));
    for (final personality in OrbitPersonality.values) {
      if (personality.name == value) return personality;
    }
    return null;
  }

  Future<void> savePersonality(String userId, OrbitPersonality personality) =>
      _store.write(_personalityKey(userId), personality.name);

  Future<List<String>> recentVariants({
    required String userId,
    required OrbitPersonality personality,
    required String factType,
    required String family,
  }) async {
    final value = await _store.read(
      _recentKey(userId, personality, factType, family),
    );
    if (value == null) return const [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is List)
        return decoded.whereType<String>().toList(growable: false);
    } catch (_) {}
    return const [];
  }

  Future<void> recordVariant({
    required String userId,
    required OrbitPersonality personality,
    required String factType,
    required String family,
    required String variantId,
  }) async {
    final recent = await recentVariants(
      userId: userId,
      personality: personality,
      factType: factType,
      family: family,
    );
    final updated = [...recent.where((id) => id != variantId), variantId];
    final kept = updated.length <= _recentLimit
        ? updated
        : updated.sublist(updated.length - _recentLimit);
    await _store.write(
      _recentKey(userId, personality, factType, family),
      jsonEncode(kept),
    );
  }

  String _personalityKey(String userId) => 'orbit.personality.$userId';
  String _recentKey(
    String userId,
    OrbitPersonality p,
    String type,
    String family,
  ) => 'orbit.personality.recent.$userId.${p.name}.$type.$family';
}
