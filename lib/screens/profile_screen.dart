import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileEditScreen extends StatefulWidget {
  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(); // New controller for phone number
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference _driversCollection = FirebaseFirestore.instance.collection('Drivers');

  bool _loading = true;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      String userEmail = currentUser.email!;


      // Fetch user type first from users collection
      QuerySnapshot userSnapshot = await _usersCollection
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      QuerySnapshot driverSnapshot = await _driversCollection
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = userSnapshot.docs.first;

        setState(() {
          _userType = doc['userType'];  // Assuming 'userType' is a field that stores either "passenger" or "driver"
        });

      }
      if (driverSnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = driverSnapshot.docs.first;

        setState(() {
          _userType = doc['userType'];  // Assuming 'userType' is a field that stores either "passenger" or "driver"
        });

      }

      // Based on user type, fetch data from the appropriate collection
      if (_userType == 'Passenger') {
        _fetchPassengerData(userEmail);
      } else if (_userType == 'Driver') {
        print("moeezz");
        _fetchDriverData(userEmail);
      }
    }
  }

  Future<void> _fetchPassengerData(String userEmail) async {
    QuerySnapshot userSnapshot = await _usersCollection
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      DocumentSnapshot doc = userSnapshot.docs.first;

      setState(() {
        _nameController.text = doc['name']?.toString() ?? '';
        _emailController.text = doc['email']?.toString() ?? '';
        _phoneController.text = doc['phone']?.toString() ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _fetchDriverData(String userEmail) async {
    try {
      print('Querying Drivers collection for email: $userEmail');  // Log before querying Firestore

      QuerySnapshot driverSnapshot = await _driversCollection
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      // Check if any documents are returned
      if (driverSnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = driverSnapshot.docs.first;

        setState(() {
          _nameController.text = doc['name'] != null ? doc['name'].toString() : '';
          _emailController.text = doc['email'] != null ? doc['email'].toString() : '';
          _phoneController.text = doc['phone'] != null ? doc['phone'].toString() : '';
          _loading = false;
        });

        print('Driver data fetched successfully');
      } else {
        print('No driver found for email: $userEmail');
      }
    } catch (e) {
      print('Error fetching driver data: $e');
    }
  }


  Future<void> _updateUserProfile() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        if (_userType == 'Passenger') {
          await _updatePassengerProfile(currentUser.email!);
        } else if (_userType == 'Driver') {
          await _updateDriverProfile(currentUser.email!);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  Future<void> _updatePassengerProfile(String userEmail) async {
    QuerySnapshot userSnapshot = await _usersCollection
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      DocumentSnapshot doc = userSnapshot.docs.first;

      // Update the passenger's profile in Firestore
      await _usersCollection.doc(doc.id).update({
        'name': _nameController.text.isNotEmpty ? _nameController.text : '',
        'email': _emailController.text.isNotEmpty ? _emailController.text : '',
        'phone': _phoneController.text.isNotEmpty ? _phoneController.text : '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  Future<void> _updateDriverProfile(String userEmail) async {
    QuerySnapshot driverSnapshot = await _driversCollection
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();

    if (driverSnapshot.docs.isNotEmpty) {
      DocumentSnapshot doc = driverSnapshot.docs.first;

      // Update the driver's profile in Firestore
      await _driversCollection.doc(doc.id).update({
        'name': _nameController.text.isNotEmpty ? _nameController.text : '',
        'email': _emailController.text.isNotEmpty ? _emailController.text : '',
        'phone': _phoneController.text.isNotEmpty ? _phoneController.text : '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              readOnly: true, // Make email read-only, as it's usually not editable
            ),
            SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone Number'), // Phone number input field
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateUserProfile,
              child: Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
