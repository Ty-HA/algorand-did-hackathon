import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/wallet_service.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'package:algorand_hackathon/services/api_service.dart';

void main() {
  final apiService = ApiService(baseUrl: 'http://192.168.1.86:8000');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletService()),
        // Ajouter ApiService comme Provider
        Provider.value(value: apiService),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupérer l'instance de ApiService depuis le Provider
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NexusID',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}