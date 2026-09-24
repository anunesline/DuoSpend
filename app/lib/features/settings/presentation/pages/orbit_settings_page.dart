import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../application/orbit_appearance_controller.dart';
import '../../data/orbit_reset_service.dart';
import '../../../orbit_intelligence/data/orbit_personality_preferences.dart';
import '../../../orbit_intelligence/domain/orbit_personality.dart';

class OrbitSettingsPage extends StatefulWidget {
  final String? sharedWalletId;
  final List<String> sharedMemberIds;

  const OrbitSettingsPage({
    super.key,
    required this.sharedWalletId,
    required this.sharedMemberIds,
  });

  @override
  State<OrbitSettingsPage> createState() => _OrbitSettingsPageState();
}

class _OrbitSettingsPageState extends State<OrbitSettingsPage> {
  final _resetService = OrbitResetService();
  OrbitResetRequest? _pendingRequest;
  bool _busy = false;
  OrbitPersonality? _personality;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await OrbitAppearanceController.instance.loadForCurrentUser();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _personality = await OrbitPersonalityPreferences.instance.loadPersonality(
        userId,
      );
    }
    final walletId = widget.sharedWalletId;
    final pending = walletId == null
        ? null
        : await _resetService.getPendingSharedReset(walletId);
    if (!mounted) return;
    setState(() => _pendingRequest = pending);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.background,
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _sectionTitle('Aparência'),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: OrbitAppearanceController.instance,
            builder: (context, _) {
              final current = OrbitAppearanceController.instance.themeMode;
              return _card([
                _themeTile('Escuro', ThemeMode.dark, current),
                _themeTile('Claro', ThemeMode.light, current),
                _themeTile(
                  'Usar configuração do sistema',
                  ThemeMode.system,
                  current,
                ),
              ]);
            },
          ),
          const SizedBox(height: 26),
          _sectionTitle('Personalidade do Orbit'),
          const SizedBox(height: 8),
          _card([
            for (final personality in OrbitPersonality.values)
              ListTile(
                title: Text(personality.label),
                trailing: Icon(
                  _personality == personality
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                ),
                onTap: _busy ? null : () => _selectPersonality(personality),
              ),
          ]),
          const SizedBox(height: 26),
          _sectionTitle('Dados do Orbit'),
          const SizedBox(height: 8),
          _card([
            ListTile(
              leading: const Icon(Icons.restart_alt_rounded),
              title: const Text('Zerar meus dados'),
              subtitle: const Text(
                'Apaga somente seus dados individuais. Sua conta e o Orbit a Dois são preservados.',
              ),
              onTap: _busy ? null : _resetMine,
            ),
            if (widget.sharedWalletId != null) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.people_outline_rounded),
                title: const Text('Reiniciar nosso Orbit'),
                subtitle: Text(
                  _pendingRequest == null
                      ? 'Os dados compartilhados só serão apagados após a confirmação dos dois.'
                      : 'Existe uma solicitação aguardando confirmação.',
                ),
                onTap: _busy ? null : _sharedReset,
              ),
            ],
          ]),
          if (_busy) ...[
            const SizedBox(height: 18),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Future<void> _selectPersonality(OrbitPersonality personality) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    await OrbitPersonalityPreferences.instance.savePersonality(
      userId,
      personality,
    );
    if (mounted) setState(() => _personality = personality);
  }

  Widget _themeTile(String title, ThemeMode value, ThemeMode current) {
    final selected = value == current;
    return ListTile(
      title: Text(title),
      trailing: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
      ),
      onTap: _busy
          ? null
          : () => OrbitAppearanceController.instance.setThemeMode(value),
    );
  }

  Future<void> _resetMine() async {
    final confirmed = await _confirm(
      title: 'Zerar meus dados?',
      body:
          'Transações, orçamentos, metas, cartões, compras e rotinas individuais serão apagados. '
          'Seu login, nome, e-mail, foto e dados compartilhados não serão apagados.',
      action: 'Zerar meus dados',
    );
    if (!confirmed) return;
    await _run(() async {
      await _resetService.resetMyData();
      _message('Seus dados individuais foram zerados.');
    });
  }

  Future<void> _sharedReset() async {
    final walletId = widget.sharedWalletId;
    if (walletId == null) return;

    final pending = _pendingRequest;
    if (pending == null) {
      final confirmed = await _confirm(
        title: 'Solicitar reset compartilhado?',
        body:
            'Os dados compartilhados só serão apagados após a confirmação dos dois membros. A conexão entre vocês será mantida.',
        action: 'Solicitar confirmação',
      );
      if (!confirmed) return;
      await _run(() async {
        await _resetService.requestSharedReset(
          walletId: walletId,
          memberIds: widget.sharedMemberIds,
        );
        _message('Solicitação enviada. Aguarde a confirmação da outra pessoa.');
      });
    } else if (pending.hasConfirmed(_currentUserId)) {
      final confirmed = await _confirm(
        title: 'Cancelar solicitação?',
        body: 'O reset compartilhado ainda não foi confirmado pelos dois.',
        action: 'Cancelar solicitação',
      );
      if (!confirmed) return;
      await _run(() async {
        await _resetService.cancelSharedReset(
          walletId: walletId,
          requestId: pending.id,
        );
        _message('Solicitação de reset cancelada.');
      });
    } else {
      final confirmed = await _confirm(
        title: 'Confirmar reset compartilhado?',
        body: 'Ao confirmar, os dados compartilhados serão apagados.',
        action: 'Confirmar reset',
      );
      if (!confirmed) return;
      await _run(() async {
        final reset = await _resetService.confirmSharedReset(
          walletId: walletId,
          requestId: pending.id,
          memberIds: widget.sharedMemberIds,
        );
        _message(
          reset ? 'Dados compartilhados zerados.' : 'Confirmação registrada.',
        );
      });
    }
    await _load();
  }

  String get _currentUserId => _resetService.auth.currentUser?.uid ?? '';

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      _message('Não foi possível concluir: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: DuoColors.textSecondary,
    ),
  );

  Widget _card(List<Widget> children) => DecoratedBox(
    decoration: BoxDecoration(
      color: DuoColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: DuoColors.divider),
    ),
    child: Column(children: children),
  );
}
