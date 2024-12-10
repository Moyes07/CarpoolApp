import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_app_screen.dart'; // Import the MainAppScreen

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedUserType = "Passenger"; // Default user type

  Future<void> _login() async {
    try {
      // Authenticate user with Firebase Authentication
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Get the authenticated user's UID
      String userId = userCredential.user!.uid;

      // Verify the user type by checking the corresponding Firestore collection
      final userDoc = await _firestore
          .collection(_selectedUserType == "Passenger" ? "users" : "Drivers")
          .doc(userId)
          .get();

      if (userDoc.exists) {
        // Navigate to the MainAppScreen with userType
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainAppScreen(userType: _selectedUserType),
          ),
        );
      } else {
        // Sign out if user type does not match the database
        await _auth.signOut();
        throw Exception(
            "No ${_selectedUserType.toLowerCase()} record found for this user.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
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
              onPressed: _login,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
