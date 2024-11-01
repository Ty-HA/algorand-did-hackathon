import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';

class VerificationScreen extends StatefulWidget {
  final ApiService apiService;

  const VerificationScreen({super.key, required this.apiService});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _faceVerified = false;
  bool _documentsVerified = false;

  String? _didAddress;
  String? _didPassphrase;
  String? _did;
  String? _transactionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity Verification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /* Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: _testRegistration,
                icon: const Icon(Icons.bug_report),
                label: const Text('Test Register API'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            ), */
            // Progress Stepper
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  _buildStepCircle(1, true, "Face"),
                  _buildStepLine(_faceVerified),
                  _buildStepCircle(2, _faceVerified, "Document"),
                  _buildStepLine(_documentsVerified),
                  _buildStepCircle(3, _documentsVerified, "Complete"),
                ],
              ),
            ),

            // Face Verification Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.face, size: 60, color: Colors.blue),
                    const SizedBox(height: 16),
                    const Text(
                      'Face Verification',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please take a clear photo of your face',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _faceVerified ? null : _startFaceVerification,
                      icon: const Icon(Icons.camera_alt),
                      label:
                          Text(_faceVerified ? 'Verified' : 'Start Face Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _faceVerified ? Colors.green : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Document Verification Section

// Document Verification Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.document_scanner,
                        size: 60, color: Colors.blue),
                    const SizedBox(height: 16),
                    const Text(
                      'Document Verification',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please scan your identity document (optional)',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      // Wrap buttons in a Row
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: !_faceVerified
                              ? null
                              : (_documentsVerified
                                  ? null
                                  : _startDocumentScan),
                          icon: const Icon(Icons.upload_file),
                          label: Text(_documentsVerified
                              ? 'Verified'
                              : 'Scan Document'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _documentsVerified ? Colors.green : null,
                          ),
                        ),
                        const SizedBox(width: 12), // Spacing between buttons
                        if (!_documentsVerified &&
                            _faceVerified) // Only show skip when document not verified
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _documentsVerified = true;
                              });
                            },
                            icon: const Icon(Icons.skip_next),
                            label: const Text('Skip'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.purple,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Complete Button
            ElevatedButton(
              onPressed: (_faceVerified && _documentsVerified)
                  ? _completeVerification
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Complete Verification',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCircle(int step, bool active, String label) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: active ? Colors.blue : Colors.grey,
            child: Text(
              step.toString(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.blue : Colors.grey,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? Colors.blue : Colors.grey,
      ),
    );
  }

  void _launch(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      // Handle the case where the URL cannot be launched
      print('Cannot launch URL: $url');
    }
  }

  void _startFaceVerification() async {
    try {
      showLoadingDialog('Scanning face...');

      final result = await widget.apiService.verifyFace();

      if (mounted)
        Navigator.of(context).pop(); // Fermer le dialogue de chargement

      if (result['verified'] == true) {
        setState(() {
          _faceVerified = true;
        });
      } else {
        throw Exception(result['message'] ?? 'Face verification failed');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fermer le dialogue de chargement
        showErrorDialog(e.toString());
      }
    }
  }

  void _startDocumentScan() async {
    try {
      showLoadingDialog('Scanning document...');

      final result = await widget.apiService.verifyDocument();

      if (mounted)
        Navigator.of(context).pop(); // Fermer le dialogue de chargement

      if (result['verified'] == true) {
        setState(() {
          _documentsVerified = true;
        });
      } else {
        throw Exception(result['message'] ?? 'Document verification failed');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fermer le dialogue de chargement
        showErrorDialog(e.toString());
      }
    }
  }

  void _completeVerification() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Registering your identity on Algorand...'),
              ],
            ),
          );
        },
      );

      final result = await widget.apiService.registerUser();
      debugPrint('Complete registration result: $result');

      if (result['status'] == 'success') {
        setState(() {
          _did = result['did'];
          _didAddress = result['address'];
          _didPassphrase = result['passphrase'];
          _transactionId = result['transaction_id'];
        });

        // Fermer le dialogue de chargement
        if (mounted) Navigator.of(context).pop();

        // Afficher le dialogue de succès
        if (mounted) {
          showSuccessDialog();
        }
      } else {
        throw Exception('Registration failed: Invalid response from server');
      }
    } catch (e) {
      debugPrint('Complete verification error: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Fermer le dialogue de chargement
        showErrorDialog(e.toString());
      }
    }
  }

  void _openAlgoExplorer(String txId) async {
    final uri = Uri.parse('https://testnet.explorer.perawallet.app/tx/$txId');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Perawallet Explorer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _testRegistration() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Testing registration...'),
            ],
          ),
        ),
      );

      final success = await widget.apiService.testRegistration();

      if (mounted) Navigator.pop(context); // Ferme le dialogue de chargement

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              success ? 'Test Successful' : 'Test Failed',
              style: TextStyle(
                color: success ? Colors.green : Colors.red,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(success
                    ? 'The registration API is working correctly!'
                    : 'The registration API test failed.'),
                const SizedBox(height: 16),
                const Text('Technical Details:'),
                Text('Endpoint: ${widget.apiService.baseUrl}/register'),
                const Text('Method: POST'),
                const Text('Headers:'),
                const Text('  Content-Type: application/json'),
                const Text('  Accept: */*'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Ferme le dialogue de chargement

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title:
                const Text('Test Error', style: TextStyle(color: Colors.red)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Error: $e'),
                const SizedBox(height: 16),
                const Text('Technical Details:'),
                Text('Endpoint: ${widget.apiService.baseUrl}/register'),
                const Text('Method: POST'),
                const Text('Headers:'),
                const Text('  Content-Type: application/json'),
                const Text('  Accept: */*'),
              ],
            ),
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
  }

void showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Verification Complete'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your identity has been successfully verified and registered on Algorand!',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                const Text('Your DID:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText(_did ?? 'Error retrieving DID'),
                const SizedBox(height: 8),

                const Text('Algorand Address:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText(_didAddress ?? 'Error retrieving address'),
                const SizedBox(height: 8),

                if (_transactionId != null) ...[
                  const Text('Transaction ID:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SelectableText(_transactionId!),
                  TextButton.icon(
                    onPressed: () => _openAlgoExplorer(_transactionId!),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('View on Pera Explorer'),
                  ),
                ],

                if (_didPassphrase != null) ...[
                  const Divider(),
                  const Text(
                    'Important: Save your passphrase securely',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _didPassphrase!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer le dialogue
                // Remplacer toute la pile de navigation avec HomeScreen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(
                      apiService: widget.apiService,
                    ),
                  ),
                  (route) => false, // Cela supprime toutes les routes précédentes
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error', style: TextStyle(color: Colors.red)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registration failed: $errorMessage'),
                const SizedBox(height: 16),
                const Text(
                  'Please try again or contact support if the problem persists.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        );
      },
    );
  }
}
