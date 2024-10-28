import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'credentials_screen.dart';
import 'home_screen.dart';  
import 'package:algorand_hackathon/services/api_service.dart';

class MainScreen extends StatefulWidget {
  final ApiService apiService;

  const MainScreen({Key? key, required this.apiService}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ProfileScreen(apiService: widget.apiService),
      CredentialsScreen(apiService: widget.apiService),
      const Center(child: Text('TTPs Coming Soon')),  // Placeholder
      const Center(child: Text('Wallet Coming Soon')), // Placeholder
    ];
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(apiService: widget.apiService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NexusID',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: _navigateToHome,
          ),
        ],
        elevation: 2,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge),
            label: 'Credentials',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user),
            label: 'TTPs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
        ],
      ),
    );
  }
}