import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://192.168.1.86:8000';

  Future<Map<String, dynamic>> registerUser() async {
    try {
      final url = Uri.parse('$baseUrl/register');
      debugPrint('Sending POST request to: $url');

      // Envoyer une requête POST avec un corps vide mais avec les bons headers
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',           // Similaire à curl
          'Host': '192.168.1.86:8000', // Similaire à curl
        },
        body: '{}',  // Corps vide mais en JSON valide
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Request timed out');
          throw Exception('Connection timed out');
        },
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response headers: ${response.headers}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        debugPrint('Parsed response data: $data');
        
        // Vérifier que les champs requis sont présents
        if (!data.containsKey('address') || !data.containsKey('passphrase')) {
          throw Exception('Invalid response format: missing required fields');
        }
        
        return data;
      } else {
        throw Exception(
          'Server error (${response.statusCode}): ${response.body}'
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Registration error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Méthode de test qui reproduit exactement le curl
  Future<bool> testRegistration() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
          'Host': '192.168.1.86:8000',
        },
      );
      
      debugPrint('Test response status: ${response.statusCode}');
      debugPrint('Test response body: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Test failed: $e');
      return false;
    }
  }
}