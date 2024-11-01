import 'package:flutter/material.dart';
import 'package:algorand_hackathon/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class CredentialsScreen extends StatefulWidget {
  final ApiService apiService;

  const CredentialsScreen({Key? key, required this.apiService})
      : super(key: key);

  @override
  State<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends State<CredentialsScreen> {
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _credentials = [
    {
      'title': 'University - Bachelor\'s Degree',
      'issuer':
          'did:algo:ISSUER7G624ETVT2LXD3RRZFQEVK53HQKTBIEREW7EVNU6I6FQMRQFM7B5',
      'date': '2024-11-01',
      'verified': true,
      'type': 'education',
      'details': 'Bachelor of Computer Science',
      'score': 95,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Credentials'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildCredentialsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewCredential,
        label: const Text('Add Credential'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total', 1, Icons.badge),
            _buildStatItem('Verified', 1, Icons.verified),
            _buildStatItem('Active', 1, Icons.timer),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildCredentialsList() {
    var filteredCredentials = _credentials;
    if (_selectedFilter != 'All') {
      filteredCredentials = _credentials
          .where((c) => c['type'] == _selectedFilter.toLowerCase())
          .toList();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCredentials.length,
      itemBuilder: (context, index) {
        final credential = filteredCredentials[index];
        return _buildCredentialCard(credential);
      },
    );
  }

  Widget _buildCredentialCard(Map<String, dynamic> credential) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showCredentialDetails(credential),
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.school, color: Colors.white),
              ),
              title: Text(
                credential['title'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Issuer: ${credential['issuer']}'),
              trailing: const Icon(Icons.verified, color: Colors.green),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Issued: ${credential['date']}'),
                ],
              ),
            ),
            if (credential['score'] != null)
              LinearProgressIndicator(
                value: credential['score'] / 100,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
          ],
        ),
      ),
    );
  }

  void _showCredentialDetails(Map<String, dynamic> credential) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                credential['title'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Issuer', credential['issuer']),
              _buildDetailRow('Date', credential['date']),
              _buildDetailRow('Details', credential['details']),
              _buildDetailRow('Score', '${credential['score']}%'),
              const SizedBox(height: 8),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('View on Pera Explorer'),
                subtitle: const Text('Transaction Details'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openTransaction(
                    '232C55242AQRRNFVE6QVBXQPGUZYVL5BMY6PWKKBYSBD22Z3U6BA'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.share),
                label: const Text('Share Credential'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openTransaction(String txId) async {
    final url = 'https://testnet.explorer.perawallet.app/tx/$txId';
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Pera Explorer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Credentials'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption('All'),
              _buildFilterOption('Education'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String filter) {
    return ListTile(
      title: Text(filter),
      leading: Radio<String>(
        value: filter,
        groupValue: _selectedFilter,
        onChanged: (String? value) {
          setState(() {
            _selectedFilter = value!;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _addNewCredential() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
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
              ListTile(
                leading: const Icon(Icons.school),
                title: const Text('University - Bachelor\'s Degree'),
                onTap: () {
                  Navigator.pop(context);
                  debugPrint('Adding university credential...');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
