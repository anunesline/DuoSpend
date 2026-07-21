import 'package:flutter/material.dart';

import '../../data/models/partner_invite_model.dart';
import '../../data/repositories/partner_invite_repository.dart';
import '../../data/repositories/wallet_repository.dart';

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

  final WalletRepository _walletRepository = WalletRepository();

  bool _loading = true;

  List<PartnerInviteModel> _invites = [];

  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  Future<void> _loadInvites() async {
    setState(() {
      _loading = true;
    });

    try {
      _invites = await _inviteRepository.getReceivedInvites();
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
    await _inviteRepository.acceptInvite(invite);

    await _walletRepository.addMember(
      walletId: invite.walletId,
      memberId: _walletRepository.currentUserId!,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Convite aceito com sucesso.',
        ),
      ),
    );

    await _loadInvites();
  }

  Future<void> _declineInvite(
    PartnerInviteModel invite,
  ) async {
    await _inviteRepository.declineInvite(invite);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Convite recusado.',
        ),
      ),
    );

    await _loadInvites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Convites',
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _invites.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum convite recebido.',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _invites.length,
                  itemBuilder: (context, index) {
                    final invite = _invites[index];

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Convite para carteira compartilhada',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Convidado por: ${invite.inviterUserId}',
                            ),
                            Text(
                              invite.invitedEmail,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () {
                                      _acceptInvite(invite);
                                    },
                                    child: const Text(
                                      'Aceitar',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      _declineInvite(invite);
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
                ),
    );
  }
}