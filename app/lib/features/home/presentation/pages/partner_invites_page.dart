import 'package:flutter/material.dart';

import '../../data/models/partner_invite_model.dart';
import '../../data/repositories/partner_invite_repository.dart';

class PartnerInvitesPage extends StatefulWidget {
  const PartnerInvitesPage({
    super.key,
  });

  @override
  State<PartnerInvitesPage> createState() => _PartnerInvitesPageState();
}

class _PartnerInvitesPageState extends State<PartnerInvitesPage> {
  final PartnerInviteRepository _inviteRepository =
      PartnerInviteRepository();

  bool _loading = true;

  List<PartnerInviteModel> _invites = [];

  final Map<String, String> _inviterDisplayNames = {};

  final Set<String> _processingInviteIds = {};

  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  Future<void> _loadInvites() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final invites = await _inviteRepository.getReceivedInvites();

      final inviterNames = await Future.wait(
        invites.map((invite) async {
          final displayName =
              await _inviteRepository.getInviterDisplayName(invite);

          return MapEntry(
            invite.id,
            displayName,
          );
        }),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _invites = invites;

        _inviterDisplayNames
          ..clear()
          ..addEntries(inviterNames);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _messageFromError(
          error,
          fallback: 'Não foi possível carregar os convites.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _acceptInvite(
    PartnerInviteModel invite,
  ) async {
    if (_processingInviteIds.contains(invite.id)) {
      return;
    }

    setState(() {
      _processingInviteIds.add(invite.id);
    });

    try {
      await _inviteRepository.acceptInvite(invite);

      if (!mounted) {
        return;
      }

      setState(() {
        _invites.removeWhere(
          (currentInvite) => currentInvite.id == invite.id,
        );

        _inviterDisplayNames.remove(invite.id);
      });

      _showMessage(
        'Convite aceito com sucesso.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _messageFromError(
          error,
          fallback: 'Não foi possível aceitar o convite.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingInviteIds.remove(invite.id);
        });
      }
    }
  }

  Future<void> _declineInvite(
    PartnerInviteModel invite,
  ) async {
    if (_processingInviteIds.contains(invite.id)) {
      return;
    }

    setState(() {
      _processingInviteIds.add(invite.id);
    });

    try {
      await _inviteRepository.declineInvite(invite);

      if (!mounted) {
        return;
      }

      setState(() {
        _invites.removeWhere(
          (currentInvite) => currentInvite.id == invite.id,
        );

        _inviterDisplayNames.remove(invite.id);
      });

      _showMessage(
        'Convite recusado.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _messageFromError(
          error,
          fallback: 'Não foi possível recusar o convite.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingInviteIds.remove(invite.id);
        });
      }
    }
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  String _messageFromError(
    Object error, {
    required String fallback,
  }) {
    if (error is StateError) {
      return error.message;
    }

    if (error is ArgumentError) {
      return error.message?.toString() ?? fallback;
    }

    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Convites',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInvites,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_invites.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 160),
          Icon(
            Icons.mark_email_read_outlined,
            size: 48,
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              'Nenhum convite recebido.',
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _invites.length,
      itemBuilder: (context, index) {
        final invite = _invites[index];
        final isProcessing =
            _processingInviteIds.contains(invite.id);

        final inviterDisplayName =
            _inviterDisplayNames[invite.id] ??
            'Usuário do DuoSpend';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Convite para carteira compartilhada',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Convidado por: $inviterDisplayName',
                ),
                Text(
                  invite.invitedEmail,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                await _acceptInvite(invite);
                              },
                        child: isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Aceitar',
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                await _declineInvite(invite);
                              },
                        child: const Text(
                          'Recusar',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}