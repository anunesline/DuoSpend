class CreatePurchaseCommand {
  final String id;
  final String userId;
  final String walletId;
  final String? consumerId;
  final DateTime purchaseDate;

  const CreatePurchaseCommand({
    required this.id,
    required this.userId,
    required this.walletId,
    this.consumerId,
    required this.purchaseDate,
  });

  void validate() {
    if (id.trim().isEmpty) {
      throw Exception('A compra precisa ter um ID.');
    }

    if (userId.trim().isEmpty) {
      throw Exception('A compra precisa estar vinculada a um usuário.');
    }

    if (walletId.trim().isEmpty) {
      throw Exception('A compra precisa estar vinculada a uma carteira.');
    }
  }
}