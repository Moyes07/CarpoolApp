import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'ride_request_screen.dart';
import 'enlist_ride_screen.dart';
import './bottom_navbar.dart';
import './profile_screen.dart';

class MainAppScreen extends StatefulWidget {
  final String userType;

  // Constructor to accept userType
  const MainAppScreen({Key? key, required this.userType}) : super(key: key);


  @override
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0;

  // List of widgets corresponding to each tab
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Dynamically set pages based on user type
    _pages = widget.userType == "Passenger"
        ? [
      HomeScreen(),
      RideRequestScreen(),
      ProfileEditScreen(),
    ]
        : [
      HomeScreen(),
      EnlistRideScreen(),
      ProfileEditScreen(),
    ];
  }

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
        userType: widget.userType, // Pass userType to BottomNavBar
      ),
    );
  }
}
