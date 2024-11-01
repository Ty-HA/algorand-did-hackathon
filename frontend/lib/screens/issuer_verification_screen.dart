import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

// Écran principal du scanner
class IssuerVerificationScreen extends StatefulWidget {
  final ApiService apiService;
  const IssuerVerificationScreen({
    Key? key,
    required this.apiService,
  }) : super(key: key);

  @override
  State<IssuerVerificationScreen> createState() => _IssuerVerificationScreenState();
}

class _IssuerVerificationScreenState extends State<IssuerVerificationScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isVerifying = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify DID as Issuer'),
        actions: [
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _processQRCode(barcode.rawValue!);
                  }
                }
              },
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: isVerifying
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Scan DID QR Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _processQRCode(String qrData) async {
    if (isVerifying) return;

    setState(() {
      isVerifying = true;
    });

    try {
      debugPrint('QR Code scanned: $qrData');
      await cameraController.stop();
      
      final data = json.decode(qrData);
      
      if (mounted) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => IssuerCredentialScreen(
              did: data['did'],
              didDocument: data['didDocument'],
              apiService: widget.apiService,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error processing QR code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        await cameraController.start();
      }
    } finally {
      if (mounted) {
        setState(() {
          isVerifying = false;
        });
      }
    }
  }
}

// Écran du formulaire de credentials
class IssuerCredentialScreen extends StatefulWidget {
  final String did;
  final Map<String, dynamic> didDocument;
  final ApiService apiService;

  const IssuerCredentialScreen({
    Key? key,
    required this.did,
    required this.didDocument,
    required this.apiService,
  }) : super(key: key);

  @override
  State<IssuerCredentialScreen> createState() => _IssuerCredentialScreenState();
}

class _IssuerCredentialScreenState extends State<IssuerCredentialScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? startDate;
  DateTime? endDate;
  String? category;
  String? firstName;
  String? lastName;
  final String issuerDid = 'did:algo:ISSUER7G624ETVT2LXD3RRZFQEVK53HQKTBIEREW7EVNU6I6FQMRQFM7B5';

  final List<String> categories = [
    'University - Bachelor\'s Degree',
    'Professional Certification',
    'Employment Verification',
    'Income Verification',
    'Health Screening Certificate',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Credential'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDidInfoCard(),
              const SizedBox(height: 24),
              _buildCategoryDropdown(),
              const SizedBox(height: 24),
              _buildPeriodSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDidInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DID Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: 'John',
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter first name';
                }
                return null;
              },
              onSaved: (value) => firstName = value,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: 'Doe',
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter last name';
                }
                return null;
              },
              onSaved: (value) => lastName = value,
            ),
            const SizedBox(height: 16),
            const Text(
              'User DID:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SelectableText(
              widget.did,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            const Text(
              'Issuer DID:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SelectableText(
              issuerDid,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      value: category,
      items: categories.map((String category) {
        return DropdownMenuItem(
          value: category,
          child: Text(
            category,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a category';
        }
        return null;
      },
      onChanged: (String? newValue) {
        setState(() {
          category = newValue;
        });
      },
    );
  }

  Widget _buildPeriodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Period',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(
                'Start Date',
                startDate,
                (date) => setState(() => startDate = date),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDatePicker(
                'End Date',
                endDate,
                (date) => setState(() => endDate = date),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? selectedDate,
    Function(DateTime) onSelect,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          onSelect(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          selectedDate != null
              ? DateFormat('yyyy-MM-dd').format(selectedDate)
              : 'Select Date',
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        onPressed: _submitCredential,
        child: const Text(
          'Issue Credential',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  void _submitCredential() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      if (startDate == null || endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both dates')),
        );
        return;
      }

      try {
        final credential = {
          'type': category,
          'issuer': issuerDid,
          'issuanceDate': DateTime.now().toIso8601String(),
          'credentialSubject': {
            'id': widget.did,
            'firstName': firstName,
            'lastName': lastName,
            'startDate': startDate!.toIso8601String(),
            'endDate': endDate!.toIso8601String(),
          },
        };

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Credential issued successfully!'),
                const SizedBox(height: 16),
                Text('Category: $category'),
                Text('Issued to: $firstName $lastName'),
                Text('Period: ${DateFormat('yyyy-MM-dd').format(startDate!)} to ${DateFormat('yyyy-MM-dd').format(endDate!)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error issuing credential: $e')),
        );
      }
    }
  }
}