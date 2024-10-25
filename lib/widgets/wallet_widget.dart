// lib/widgets/wallet_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';

class WalletWidget extends StatelessWidget {
  const WalletWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletService>(
      builder: (context, wallet, _) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Wallet Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      wallet.connected ? Icons.check_circle : Icons.error,
                      color: wallet.connected ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (wallet.account != null)
                  Text(
                    'Connected Account:\n${wallet.account}',
                    style: const TextStyle(fontSize: 16),
                  )
                else
                  const Text(
                    'No wallet connected',
                    style: TextStyle(fontSize: 16),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (wallet.connected) {
                        await wallet.disconnect();
                      } else {
                        await wallet.connect(context); // Passage du context ici
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: Text(wallet.connected ? 'Disconnect' : 'Connect Wallet'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}