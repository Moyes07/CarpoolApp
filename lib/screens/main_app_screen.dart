// main_app_screen.dart
import 'package:carpool_fyp_app/screens/ride_request_screen.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'enlist_ride_screen.dart';
import './bottom_navbar.dart';
import './profile_screen.dart';

class MainAppScreen extends StatefulWidget {
  @override
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0;

  // List of widgets corresponding to each tab
  final List<Widget> _pages = [
    HomeScreen(),
    RideRequestScreen(),
    EnlistRideScreen(),
    ProfileEditScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
