import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'credentials_screen.dart';
import 'home_screen.dart';  // N'oubliez pas d'importer HomeScreen

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const ProfileScreen(),
    const CredentialsScreen(),
    const Center(child: Text('TTPs Coming Soon')),  // Placeholder
    const Center(child: Text('Wallet Coming Soon')), // Placeholder
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NexusID',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Icône maison qui redirige vers HomeScreen
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            },
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