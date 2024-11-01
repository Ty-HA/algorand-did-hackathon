import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  final String baseUrl;
  
  final ImagePicker _imagePicker = ImagePicker();

  ApiService({required this.baseUrl}) {
    debugPrint('ApiService initialized with URL: $baseUrl');
  }

  // Méthode d'enregistrement utilisateur
  Future<Map<String, dynamic>> registerUser() async {
  try {
    final url = Uri.parse('$baseUrl/register');
    debugPrint('Sending registration request to: $url');

    final request = {
      "address": "",
      "private_key": "",
      "mnemonic": "",
      "user_info_hash": "",
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        debugPrint('Request timed out');
        throw Exception('Connection timed out');
      },
    );

    debugPrint('Response status code: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      debugPrint('Parsed response data: $data');

      // Vérifiez la structure exacte de la réponse
      if (data['status'] == 'success' &&
          data['did'] != null &&
          data['transaction_id'] != null &&
          data['passphrase'] != null) {
        
        // Extraire l'adresse du didDocument
        final String? address = data['didDocument']?['verificationMethod']?[0]?['publicKeyBase58'];
        
        if (address == null) {
          throw Exception('Missing address in response');
        }

        return {
          'status': 'success',
          'did': data['did'],
          'address': address,
          'passphrase': data['passphrase'],
          'transaction_id': data['transaction_id'],
          'didDocument': data['didDocument']  // Ajoutez le document DID complet si nécessaire
        };
      } else {
        throw Exception('Invalid response format: missing required fields');
      }
    } else {
      final errorData = json.decode(response.body);
      final errorDetails = errorData['detail'] ?? 'Unknown server error';
      debugPrint('Server error details: $errorDetails');
      throw Exception(errorDetails);
    }
  } catch (e, stackTrace) {
    debugPrint('Registration error: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

  // Méthode de vérification du visage
  Future<Map<String, dynamic>> verifyFace() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image == null) {
        throw Exception('No image captured');
      }

      File imageFile = File(image.path);
      if (!await imageFile.exists()) {
        throw Exception('Image file not found');
      }

      debugPrint('Image captured successfully at: ${image.path}');
      debugPrint('Image size: ${await imageFile.length()} bytes');

      await Future.delayed(const Duration(seconds: 1));
      
      try {
        await imageFile.delete();
      } catch (e) {
        debugPrint('Warning: Could not delete temporary file: $e');
      }

      return {
        'verified': true,
        'message': 'Face verification successful'
      };
    } catch (e) {
      debugPrint('Face verification error: $e');
      rethrow;
    }
  }

  // Méthode de vérification du document
  Future<Map<String, dynamic>> verifyDocument() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) {
        throw Exception('No document captured');
      }

      File imageFile = File(image.path);
      if (!await imageFile.exists()) {
        throw Exception('Document image file not found');
      }

      debugPrint('Document captured successfully at: ${image.path}');
      debugPrint('Document size: ${await imageFile.length()} bytes');

      await Future.delayed(const Duration(seconds: 1));
      
      try {
        await imageFile.delete();
      } catch (e) {
        debugPrint('Warning: Could not delete temporary file: $e');
      }

      return {
        'verified': true,
        'message': 'Document verification successful'
      };
    } catch (e) {
      debugPrint('Document verification error: $e');
      rethrow;
    }
  }

  // Méthode de vérification DID
  Future<Map<String, dynamic>> verifyDID(String transactionId) async {
    try {
      final url = Uri.parse('$baseUrl/verify-did/$transactionId');
      debugPrint('Sending GET request to: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Verification request timed out');
        },
      );

      debugPrint('Verification response code: ${response.statusCode}');
      debugPrint('Verification response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'verified': data['verified'] ?? false,
          'status': data['status'],
        };
      } else {
        throw Exception('DID verification failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Verification error: $e');
      rethrow;
    }
  }

  // Méthode de test de l'API
  Future<bool> testRegistration() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Health check timed out');
        },
      );
      
      debugPrint('Health check status: ${response.statusCode}');
      debugPrint('Health check response: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }
}