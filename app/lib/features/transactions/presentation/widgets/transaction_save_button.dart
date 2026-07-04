import 'package:flutter/material.dart';

class TransactionSaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onPressed;

  const TransactionSaveButton({
    super.key,
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSaving ? null : onPressed,
        child: Text(isSaving ? 'Salvando...' : 'Salvar'),
      ),
    );
  }
}