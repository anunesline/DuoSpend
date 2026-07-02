class WalletModel {
  final String id;
  final String name;
  final double balance;

  WalletModel({
    required this.id,
    required this.name,
    required this.balance,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "balance": balance,
    };
  }

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      id: map["id"] ?? "",
      name: map["name"] ?? "",
      balance: (map["balance"] ?? 0).toDouble(),
    );
  }
}