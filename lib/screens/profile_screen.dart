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

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      String userEmail = currentUser.email!;
      // Query Firestore for the document where email matches the current user's email
      QuerySnapshot userSnapshot = await _usersCollection
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = userSnapshot.docs.first;

        // Safely check each field and populate the controllers, even if fields are null
        setState(() {
          _nameController.text = doc['name']?.toString() ?? ''; // If null, set as empty string
          _emailController.text = doc['email']?.toString() ?? ''; // If null, set as empty string
          _phoneController.text = doc['phone']?.toString() ?? ''; // If null, set as empty string
          _loading = false;
        });
      }
    }
  }

  Future<void> _updateUserProfile() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        // Query Firestore for the document where email matches the current user's email
        QuerySnapshot userSnapshot = await _usersCollection
            .where('email', isEqualTo: currentUser.email)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          DocumentSnapshot doc = userSnapshot.docs.first;

          // Update the user's profile in Firestore
          await _usersCollection.doc(doc.id).update({
            'name': _nameController.text.isNotEmpty ? _nameController.text : '',
            'email': _emailController.text.isNotEmpty ? _emailController.text : '',
            'phone': _phoneController.text.isNotEmpty ? _phoneController.text : '',
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
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
