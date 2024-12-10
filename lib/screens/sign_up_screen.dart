import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedUserType = "Passenger"; // Default user type

  Future<void> _signUp() async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Get the user ID
      String userId = userCredential.user!.uid;

      // Prepare user data
      Map<String, dynamic> userData = {
        'email': _emailController.text,
        'name': '',
        'phone': '',
        'createdAt': Timestamp.now(),
        'userType': _selectedUserType,
      };

      // Store user data in appropriate collection
      if (_selectedUserType == "Passenger") {
        await _firestore.collection('users').doc(userId).set(userData);
      } else if (_selectedUserType == "Driver") {
        await _firestore.collection('Drivers').doc(userId).set(userData);
      }

      // Navigate to home screen or show success message
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            DropdownButton<String>(
              value: _selectedUserType,
              items: [
                DropdownMenuItem(
                  value: "Passenger",
                  child: Text("Passenger"),
                ),
                DropdownMenuItem(
                  value: "Driver",
                  child: Text("Driver"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedUserType = value!;
                });
              },
              hint: Text("Select User Type"),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _signUp,
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}