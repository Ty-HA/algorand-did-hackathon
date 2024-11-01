import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'verification_screen.dart';
import 'credentials_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';
import 'ttp_screen.dart';
import 'package:algorand_hackathon/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final ApiService apiService;

  const HomeScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final String _didAddress =
      'did:algo:J4PCC5KTBIEREW7EVNU6I6FQMRQFM7B57G624ETVT2LXD3RRZFQEVK53HQ';
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

  Widget _getScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildMainContent();
      case 1:
        return CredentialsScreen(apiService: widget.apiService);
      case 2:
        return TTPScreen(apiService: widget.apiService);
      case 3:
        return const WalletScreen();
      default:
        return _buildMainContent();
    }
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIdentityCard(),
            const SizedBox(height: 24),
            _buildInfoCards(),
            const SizedBox(height: 24),
            _buildDidInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard() {
    return Center(
        child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'My DID Address',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                _didAddress,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildIdentityScore(),
          ],
        ),
      ),
    ));
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
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(
                value: 0.25, // Changed to 25%
                backgroundColor: Colors.grey[300],
                strokeWidth: 10,
                color: Colors.orange, // Changed color to reflect lower score
              ),
            ),
            const Text(
              '25%', // Changed to 25%
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DID Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildInfoCard(
              title: 'KYC Status',
              value: 'Initial',  // Changed from 'Pending'
              icon: Icons.verified_user,
              color: Colors.orange,
            ),
            _buildInfoCard(
              title: 'Network',
              value: 'Algorand Testnet',
              icon: Icons.network_check,
              color: Colors.blue,
            ),
            _buildInfoCard(
              title: 'Wallet',
              value: 'Pera Wallet',  // Changed from 'Created On'
              icon: Icons.account_balance_wallet,
              color: Colors.green,
            ),
            _buildInfoCard(
              title: 'Credentials',
              value: '0 Verified',  // Changed from 'Personal'
              icon: Icons.badge,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDidInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'About Your DID',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              title: 'Identity Status',
              content: 'Basic DID created. KYC verification needed to access full features.',
            ),
            _buildInfoRow(
              title: 'Available Actions',
              content: 'Complete KYC verification to increase your trust score and access more features.',
            ),
            _buildInfoRow(
              title: 'Benefits',
              content: 'After verification: Create and manage verifiable credentials, participate in the trusted network.',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
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
                  backgroundColor:
                      credential['verified'] ? Colors.green : Colors.orange,
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

  Future<void> _showQRCode() async {
    try {
      // Créer un mock des données DID pour le QR code
      final mockProfileData = {
        'did': _didAddress,
        'didDocument': {
          '@context': ['https://www.w3.org/ns/did/v1'],
          'id': _didAddress,
          'verificationMethod': [
            {
              'id': '$_didAddress#key-1',
              'type': 'Ed25519VerificationKey2018',
              'controller': _didAddress,
              'publicKeyBase58': _didAddress.replaceAll('did:algo:', '')
            }
          ],
          'authentication': ['$_didAddress#key-1']
        },
        'transaction_id':
            'DJ7PFIKRVZSZQYGAEDIORY2M4DLE3O7JHBWYT4SPM7QO445BTSPQ',
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Convertir en JSON string
      final qrData = json.encode(mockProfileData);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Your DID QR Code',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 300,
                  height: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 280,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scan this code to verify your identity',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'DID: $_didAddress',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy Data'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: qrData));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('QR data copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ProfileScreen(apiService: widget.apiService)),
    );
  }

  void _startVerification() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerificationScreen(
          apiService: widget.apiService,
        ),
      ),
    );
  }

  void _viewAllCredentials() {
    setState(() => _selectedIndex = 1); // Switch to Credentials tab
  }

  void _viewCredentialDetails(Map<String, dynamic> credential) {
    debugPrint('Viewing credential details: ${credential['title']}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png',
          height: 32.0, // Ajustez la taille de l'image selon vos besoins
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => _showQRCode(),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => _navigateToProfile(),
          ),
        ],
        elevation: 2,
      ),
      body: _getScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 229, 16, 162),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge),
            label: 'Credentials',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user),
            label: 'TTPs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
        ],
      ),
    );
  }
}
