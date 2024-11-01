import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class IssuerVerificationScreen extends StatefulWidget {
  final ApiService apiService;
  const IssuerVerificationScreen({
    Key? key,
    required this.apiService, // Rendu requis
  }) : super(key: key);

 @override
  State<IssuerVerificationScreen> createState() => _IssuerVerificationScreenState();
}

class _IssuerVerificationScreenState extends State<IssuerVerificationScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  MobileScannerController cameraController = MobileScannerController();
  bool isVerifying = false;

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
            child: _buildQRView(context),
          ),
          Expanded(
            child: _buildResult(),
          ),
        ],
      ),
    );
  }

  Widget _buildQRView(BuildContext context) {
    return MobileScanner(
      controller: cameraController,
      onDetect: (capture) {
        final List<Barcode> barcodes = capture.barcodes;
        for (final barcode in barcodes) {
          if (barcode.rawValue != null) {
            _verifyAndShowForm(barcode.rawValue!);
          }
        }
      },
    );
  }

  Widget _buildResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: isVerifying
          ? const CircularProgressIndicator()
          : const Text('Scan DID QR Code'),
    );
  }

  void _verifyAndShowForm(String qrData) async {
    if (isVerifying) return;

    setState(() {
      isVerifying = true;
    });

    try {
      cameraController.stop();
      final data = json.decode(qrData);
      
      // Passez l'apiService depuis le widget parent
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => IssuerCredentialScreen(
              did: data['did'],
              didDocument: data['didDocument'],
              apiService: widget.apiService, // Utilisez l'apiService du widget
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        isVerifying = false;
      });
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

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
  String? degree;
  String? institution;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Education Credential'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
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
                      const SizedBox(height: 8),
                      Text('DID: ${widget.did}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Degree/Certificate Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the degree name';
                  }
                  return null;
                },
                onSaved: (value) => degree = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Institution',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the institution name';
                  }
                  return null;
                },
                onSaved: (value) => institution = value,
              ),
              const SizedBox(height: 16),
              _buildDatePicker(
                'Start Date',
                startDate,
                (date) => setState(() => startDate = date),
              ),
              const SizedBox(height: 16),
              _buildDatePicker(
                'End Date',
                endDate,
                (date) => setState(() => endDate = date),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitCredential,
                  child: const Text('Issue Credential'),
                ),
              ),
            ],
          ),
        ),
      ),
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

  void _submitCredential() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      if (startDate == null || endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both dates')),
        );
        return;
      }

      // Créer le credential
      final credential = {
        'type': 'EducationCredential',
        'issuer': 'School District',
        'issuanceDate': DateTime.now().toIso8601String(),
        'credentialSubject': {
          'id': widget.did,
          'degree': degree,
          'institution': institution,
          'startDate': startDate!.toIso8601String(),
          'endDate': endDate!.toIso8601String(),
        },
      };

      try {
        // Ici, vous devriez appeler votre API pour mettre à jour le DID document
        // et ajouter le credential

        // Pour le moment, affichons juste un succès
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Credential issued successfully!'),
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