import 'package:flutter/material.dart';
import 'package:algorand_hackathon/services/api_service.dart'; 

class CredentialsScreen extends StatefulWidget {
  final ApiService apiService;

  const CredentialsScreen({Key? key, required this.apiService}) : super(key: key);

  @override
  State<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends State<CredentialsScreen> {
  // Simuler des données de credentials plus détaillées
  final List<Map<String, dynamic>> _credentials = [
    {
      'title': 'Education Certificate',
      'issuer': 'Local School',
      'date': '2024-03-15',
      'verified': true,
      'type': 'education',
      'details': 'Bachelor of Computer Science',
      'validUntil': '2029-03-15',
      'score': 95,
    },
    {
      'title': 'Identity Verification',
      'issuer': 'NGO Partner',
      'date': '2024-03-10',
      'verified': true,
      'type': 'identity',
      'details': 'Government ID Verification',
      'validUntil': '2029-03-10',
      'score': 100,
    },
    {
      'title': 'Professional Certificate',
      'issuer': 'Tech Company',
      'date': '2024-02-20',
      'verified': true,
      'type': 'professional',
      'details': 'Blockchain Developer Certification',
      'validUntil': '2026-02-20',
      'score': 88,
    }
  ];

  String _selectedFilter = 'All';

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
    int totalCredentials = _credentials.length;
    int verifiedCredentials = _credentials.where((c) => c['verified']).length;
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total', totalCredentials, Icons.badge),
            _buildStatItem('Verified', verifiedCredentials, Icons.verified),
            _buildStatItem('Active', totalCredentials, Icons.timer),
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
    Color typeColor;
    IconData typeIcon;

    switch (credential['type']) {
      case 'education':
        typeColor = Colors.blue;
        typeIcon = Icons.school;
        break;
      case 'professional':
        typeColor = Colors.green;
        typeIcon = Icons.business;
        break;
      case 'identity':
        typeColor = Colors.purple;
        typeIcon = Icons.badge;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.document_scanner;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showCredentialDetails(credential),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: typeColor,
                child: Icon(typeIcon, color: Colors.white),
              ),
              title: Text(
                credential['title'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Issued by: ${credential['issuer']}'),
              trailing: credential['verified']
                  ? const Icon(Icons.verified, color: Colors.green)
                  : const Icon(Icons.pending, color: Colors.orange),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Issued: ${credential['date']}'),
                  Text('Valid until: ${credential['validUntil']}'),
                ],
              ),
            ),
            if (credential['score'] != null)
              LinearProgressIndicator(
                value: credential['score'] / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(typeColor),
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
              _buildDetailRow('Valid Until', credential['validUntil']),
              _buildDetailRow('Details', credential['details']),
              _buildDetailRow('Score', '${credential['score']}%'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // Ajouter la logique de partage ici
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
              _buildFilterOption('Professional'),
              _buildFilterOption('Identity'),
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
              ListTile(
                leading: const Icon(Icons.school),
                title: const Text('Education Credential'),
                onTap: () {
                  Navigator.pop(context);
                  debugPrint('Adding education credential...');
                },
              ),
              ListTile(
                leading: const Icon(Icons.badge),
                title: const Text('Identity Verification'),
                onTap: () {
                  Navigator.pop(context);
                  debugPrint('Starting identity verification...');
                },
              ),
              ListTile(
                leading: const Icon(Icons.business),
                title: const Text('Professional Credential'),
                onTap: () {
                  Navigator.pop(context);
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

