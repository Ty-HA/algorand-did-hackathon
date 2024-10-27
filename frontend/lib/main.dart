// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/wallet_service.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Retire la bannière debug
      title: 'DID Identity App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(), // Définit HomeScreen comme écran principal
      // home: const MainScreen(), 
    );
  }
}