import 'package:flutter/material.dart';

import '../../../../core/design_system/duo_colors.dart';
import '../../application/orbit_appearance_controller.dart';
import '../../data/orbit_reset_service.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await OrbitAppearanceController.instance.loadForCurrentUser();
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
                _themeTile('Usar configuração do sistema', ThemeMode.system, current),
              ]);
            },
          ),
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

    final confirmed = await _confirm(
      title: 'Zerar dados compartilhados?',
      body:
          'MODO DE TESTE: todos os dados compartilhados deste Orbit a Dois serão apagados agora. Não será necessária a confirmação da outra pessoa. A conexão entre vocês será mantida.',
      action: 'Zerar compartilhados',
    );
    if (!confirmed) return;

    await _run(() async {
      await _resetService.resetSharedDataForTesting(walletId);
      _message('Dados compartilhados zerados.');
    });
    await _load();
  }

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
