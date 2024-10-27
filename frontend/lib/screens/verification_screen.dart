import 'package:flutter/material.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _faceVerified = false;
  bool _documentsVerified = false;

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
            // Progress Stepper
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  _buildStepCircle(1, true, "Face"),
                  _buildStepLine(_faceVerified),
                  _buildStepCircle(2, _faceVerified, "Documents"),
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
                      label: Text(_faceVerified ? 'Verified' : 'Start Face Scan'),
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
                    const Icon(Icons.document_scanner, size: 60, color: Colors.blue),
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
                      onPressed: !_faceVerified ? null : (_documentsVerified ? null : _startDocumentScan),
                      icon: const Icon(Icons.upload_file),
                      label: Text(_documentsVerified ? 'Verified' : 'Scan Document'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _documentsVerified ? Colors.green : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Complete Button
            ElevatedButton(
              onPressed: (_faceVerified && _documentsVerified) ? _completeVerification : null,
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

  void _completeVerification() {
    // Afficher un message de succès
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Verification Complete'),
          content: const Text('Your identity has been successfully verified!'),
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
  }
}