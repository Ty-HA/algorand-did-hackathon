import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
                      'Please scan your identity document',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: !_faceVerified
                          ? null
                          : (_documentsVerified ? null : _startDocumentScan),
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                          _documentsVerified ? 'Verified' : 'Scan Document'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _documentsVerified ? Colors.green : null,
                      ),
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

  void _startFaceVerification() async {
    // Simuler un processus de vérification
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
              Text('Scanning face...'),
            ],
          ),
        );
      },
    );

    // Simuler un délai
    await Future.delayed(const Duration(seconds: 2));

    // Fermer le dialogue de chargement
    if (mounted) Navigator.of(context).pop();

    // Mettre à jour l'état
    setState(() {
      _faceVerified = true;
    });
  }

  void _startDocumentScan() async {
    // Simuler un processus de scan
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
              Text('Scanning document...'),
            ],
          ),
        );
      },
    );

    // Simuler un délai
    await Future.delayed(const Duration(seconds: 2));

    // Fermer le dialogue de chargement
    if (mounted) Navigator.of(context).pop();

    // Mettre à jour l'état
    setState(() {
      _documentsVerified = true;
    });
  }

  void _completeVerification() async {
    try {
      // Afficher un dialogue de chargement
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Verification Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your identity has been successfully verified!'),
                const SizedBox(height: 16),
                const Text('Your DID:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText(_did ?? 'Error retrieving DID'),
                const SizedBox(height: 8),
                const Text('Algorand Address:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText(_didAddress ?? 'Error retrieving address'),
                const SizedBox(height: 8),
                const Text('Important: Please save your passphrase securely',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red)),
                SelectableText(_didPassphrase ?? 'Error retrieving passphrase',
                    style: TextStyle(fontSize: 12)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fermer le dialogue
                  Navigator.of(context).pop(); // Retourner à l'écran précédent
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      // Appeler l'API pour enregistrer l'utilisateur
      final result = await widget.apiService.registerUser();

      // Stocker les informations DID
      setState(() {
        _did = result['did'];
        _didAddress = result['address'];
        _didPassphrase = result['passphrase'];
      });

      // Fermer le dialogue de chargement
      if (mounted) Navigator.of(context).pop();

      // Afficher le dialogue de succès avec les informations DID
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Verification Complete'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your identity has been successfully verified!'),
                  const SizedBox(height: 16),
                  const Text('Your DID Address:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_did ?? 'Error retrieving address'),
                  const SizedBox(height: 8),
                  const Text('Important: Please save your passphrase securely',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red)),
                  Text(_didPassphrase ?? 'Error retrieving passphrase',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Fermer le dialogue
                    Navigator.of(context)
                        .pop(); // Retourner à l'écran précédent
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Fermer le dialogue de chargement
      if (mounted) Navigator.of(context).pop();

      // Afficher un dialogue d'erreur
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
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
}
