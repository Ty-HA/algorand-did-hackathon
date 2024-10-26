import 'package:flutter/material.dart';
import 'verification_screen.dart';
import 'credentials_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';
import 'ttp_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
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

  Widget _getScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildMainContent();
      case 1:
        return const CredentialsScreen();
      case 2:
        return const TTPScreen();
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
        title: const Text(
          'SerendID',
          style: TextStyle(fontWeight: FontWeight.bold),
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
        selectedItemColor: Colors.blue,
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