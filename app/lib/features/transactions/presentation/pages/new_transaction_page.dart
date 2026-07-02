import 'package:flutter/material.dart';
import '../controllers/transaction_controller.dart';

class NewTransactionPage extends StatefulWidget {
  const NewTransactionPage({super.key});

  @override
  State<NewTransactionPage> createState() => _NewTransactionPageState();
}

class _NewTransactionPageState extends State<NewTransactionPage> {
  final descriptionController = TextEditingController();
  final valueController = TextEditingController();
  final controller = TransactionController();

  String type = "expense";

  @override
  void dispose() {
    descriptionController.dispose();
    valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nova Transação"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Descrição",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: valueController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: "Valor",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            RadioListTile<String>(
              title: const Text("Receita"),
              value: "income",
              groupValue: type,
              onChanged: (value) {
                setState(() {
                  type = value!;
                });
              },
            ),

            RadioListTile<String>(
              title: const Text("Despesa"),
              value: "expense",
              groupValue: type,
              onChanged: (value) {
                setState(() {
                  type = value!;
                });
              },
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final description =
                      descriptionController.text.trim();

                  final value = double.tryParse(
                    valueController.text.replaceAll(",", "."),
                  );

                  if (description.isEmpty || value == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Preencha todos os campos."),
                      ),
                    );
                    return;
                  }

                  await controller.saveTransaction(
                    description: description,
                    value: value,
                    type: type,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text("Salvar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}