import 'package:flutter/material.dart';

class WalletCard extends StatelessWidget {
  final String walletName;
  final double balance;

  const WalletCard({
    super.key,
    required this.walletName,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF4F46E5),
          child: Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
          ),
        ),
        title: Text(
          walletName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "Saldo: R\$ ${balance.toStringAsFixed(2)}",
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}