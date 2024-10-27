// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'verification_screen.dart';
import 'credentials_screen.dart';
import 'profile_screen.dart';
import '../widgets/wallet_widget.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variables pour simuler les données
  final String _didAddress = 'did:algo:0x1234...5678';
  final double _identityScore = 75.0;
  final List<Map<String, dynamic>> _credentials = [
    {
      'title': 'Education Certificate',
      'issuer': 'Local School',
      'date': '2024-03-15',
      'verified': true,
    },
    {
      'title': 'Identity Verification',
      'issuer': 'NGO Partner',
      'date': '2024-03-10',
      'verified': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
  onPressed: _addNewCredential,
  label: const Text('Add Credential'),
  icon: const Icon(Icons.add),
),
    );
  }

AppBar _buildAppBar() {
  return AppBar(
    title: const Text(
      'NexusID',
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    actions: [
      Consumer<WalletService>(
  builder: (context, wallet, _) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: wallet.connected
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${wallet.account?.substring(0, 4)}...${wallet.account?.substring(wallet.account!.length - 4)}',
                  style: const TextStyle(fontSize: 12),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 16),
                  onPressed: () => wallet.disconnect(),
                ),
              ],
            ),
          )
        : ElevatedButton.icon(
  onPressed: () async {
    try {
      await wallet.connect(context); // Passage du context ici
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  },
  icon: const Icon(Icons.account_balance_wallet, size: 16),
  label: const Text('Connect'),
),
    );
  },
),
      IconButton(
        icon: const Icon(Icons.qr_code),
        onPressed: () => _showQRCode(),
      ),
      IconButton(
        icon: const Icon(Icons.person),
        onPressed: () => _navigateToProfile(),
      ),
    ],
  );
}

  Widget _buildBody() {
  return RefreshIndicator(
    onRefresh: () async {
      // Simuler un rafraîchissement des données
      await Future.delayed(const Duration(seconds: 1));
    },
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIdentityCard(),
          const SizedBox(height: 20),
          const WalletWidget(), // Ajouté ici
          const SizedBox(height: 20),
          _buildActionButtons(),
          const SizedBox(height: 20),
          _buildCredentialsList(),
        ],
      ),
    ),
  );
}

  Widget _buildIdentityCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Photo de profil
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            
            // DID Address
            Text(
              'DID Address',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _didAddress,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Score d'identité
            _buildIdentityScore(),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityScore() {
    return Column(
      children: [
        const Text(
          'Identity Score',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(
                value: _identityScore / 100,
                backgroundColor: Colors.grey[300],
                strokeWidth: 10,
              ),
            ),
            Text(
              '${_identityScore.toInt()}%',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _startVerification(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.verified_user),
            label: const Text('Verify Identity'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _viewAllCredentials(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.badge),
            label: const Text('Credentials'),
          ),
        ),
      ],
    );
  }

  Widget _buildCredentialsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Credentials',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _credentials.length,
          itemBuilder: (context, index) {
            final credential = _credentials[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: credential['verified'] ? Colors.green : Colors.orange,
                  child: Icon(
                    credential['verified'] ? Icons.verified : Icons.pending,
                    color: Colors.white,
                  ),
                ),
                title: Text(credential['title']),
                subtitle: Text(
                  'Issued by: ${credential['issuer']}\n${credential['date']}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () => _viewCredentialDetails(credential),
                ),
              ),
            );
          },
        ),
      ],
    );
  }


  // Méthodes de navigation et d'action
  void _showQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your DID QR Code'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code, size: 200),
            SizedBox(height: 16),
            Text('Scan this code to verify your identity'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

void _navigateToProfile() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const ProfileScreen()),
  );
}

void _startVerification() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const VerificationScreen()),
  );
}

void _viewAllCredentials() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const CredentialsScreen()),
  );
}

  void _viewCredentialDetails(Map<String, dynamic> credential) {
    // Voir les détails d'un credential
    debugPrint('Viewing credential details: ${credential['title']}');
  }

  void _addNewCredential() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add New Credential',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Options pour ajouter des credentials
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Education Credential'),
              onTap: () {
                Navigator.pop(context);
                // Naviguer vers l'écran d'ajout de credential éducatif
                debugPrint('Adding education credential...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text('Identity Verification'),
              onTap: () {
                Navigator.pop(context);
                // Naviguer vers l'écran de vérification d'identité
                debugPrint('Starting identity verification...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Professional Credential'),
              onTap: () {
                Navigator.pop(context);
                // Naviguer vers l'écran d'ajout de credential professionnel
                debugPrint('Adding professional credential...');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}
}