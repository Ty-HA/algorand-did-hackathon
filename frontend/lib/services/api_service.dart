import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://192.168.1.86:8000';

  Future<Map<String, dynamic>> registerUser() async {
    try {
      final url = Uri.parse('$baseUrl/register');
      debugPrint('Sending registration request to: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
          'Host': '192.168.1.86:8000',
        },
        body: '{}',
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Request timed out');
          throw Exception('Connection timed out');
        },
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Vérifier la présence de tous les champs requis
        if (!data.containsKey('did') || 
            !data.containsKey('address') || 
            !data.containsKey('passphrase')) {
          throw Exception('Invalid server response: missing required fields');
        }
        
        return data;
      } else {
        throw Exception(
          'Server error (${response.statusCode}): ${response.body}'
        );
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    }
  }

  Future<bool> testRegistration() async {
    try {
      debugPrint('Testing registration endpoint');
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
          'Host': '192.168.1.86:8000',
        },
        body: '{}',
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Test timed out after 5 seconds'),
      );
      
      debugPrint('Test response status: ${response.statusCode}');
      debugPrint('Test response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data.containsKey('did') && 
               data.containsKey('address') && 
               data.containsKey('passphrase');
      }
      return false;
    } catch (e) {
      debugPrint('Test registration failed: $e');
      return false;
    }
  }
}