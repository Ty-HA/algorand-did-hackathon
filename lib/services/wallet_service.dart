// lib/services/wallet_service.dart

import 'package:flutter/material.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletService extends ChangeNotifier {
  late WalletConnect connector;
  String? _account;
  bool _connected = false;

  bool get connected => _connected;
  String? get account => _account;

  WalletService() {
    _initWalletConnect();
  }

  Future<void> _initWalletConnect() async {
    connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      clientMeta: const PeerMeta(
        name: 'NexusID',
        description: 'A Decentralized Identity DApp',
        url: 'https://nexusid.app',
        icons: ['https://your-website.com/icon.png'],
      ),
    );

    connector.on('connect', (session) {
      if (session is SessionStatus) {
        _onConnect(session);
      }
    });

    connector.on('session_update', (payload) {
      if (payload is SessionStatus) {
        _onSessionUpdate(payload);
      }
    });

    connector.on('disconnect', (payload) => _onDisconnect());
  }

  Future<void> connect(BuildContext context) async {
    if (!connector.connected) {
      try {
        final session = await connector.createSession(
          chainId: 416002,
          onDisplayUri: (uri) async {
            debugPrint('Original URI: $uri');
            try {
              // Lien direct vers le Play Store pour Pera Wallet
              const peraPlayStoreUrl = 'https://play.google.com/store/apps/details?id=com.algorand.android';
              
              // Essayer d'ouvrir Pera Wallet
              final peraUrl = Uri.parse('pera://');
              if (await canLaunchUrl(peraUrl)) {
                // Si Pera est installé
                await launchUrl(peraUrl);
                await Future.delayed(const Duration(milliseconds: 1000));
                
                // Envoyer l'URI WalletConnect
                final wcUri = Uri.parse(uri);
                await launchUrl(wcUri, mode: LaunchMode.externalApplication);
              } else {
                // Si Pera n'est pas installé, montrer le dialogue d'installation
                if (context.mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Pera Wallet Required'),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.wallet,
                              size: 50,
                              color: Colors.blue,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'To connect your wallet, you need to install Pera Wallet first.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              // Ouvrir le Play Store
                              final playStoreUri = Uri.parse(peraPlayStoreUrl);
                              await launchUrl(
                                playStoreUri,
                                mode: LaunchMode.externalApplication,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Install Pera Wallet'),
                          ),
                        ],
                      );
                    },
                  );
                }
              }
            } catch (e) {
              debugPrint('Error launching wallet: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error connecting to wallet: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
        
        _account = session.accounts[0];
        _connected = true;
        notifyListeners();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully connected to wallet'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Connection error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        rethrow;
      }
    }
}

  Future<void> disconnect() async {
    try {
      await connector.killSession();
      _account = null;
      _connected = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error disconnecting: $e');
      rethrow;
    }
  }

  void _onConnect(SessionStatus session) {
    _account = session.accounts[0];
    _connected = true;
    notifyListeners();
  }

  void _onSessionUpdate(SessionStatus payload) {
    _account = payload.accounts[0];
    notifyListeners();
  }

  void _onDisconnect() {
    _account = null;
    _connected = false;
    notifyListeners();
  }
}