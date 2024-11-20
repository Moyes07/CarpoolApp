import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bookedlist.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<BookedList>> fetchBookedRides() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      String userEmail = currentUser.email!;
      print(userEmail);

      // Query Firestore for the records that match the current user's email
      final snapshot = await _firestore
          .collection('bookedride')
          .where('passengerEmail', isEqualTo: userEmail)
          .get();

      return snapshot.docs.map((doc) {
        return BookedList.fromJson(
          doc.data() as Map<String, dynamic>, // Document data
          doc.id, // Firestore document ID
        );
      }).toList();
    } else {
      return []; // Return an empty list if no user is logged in
    }
  }

  Future<void> updateRideStatus(String rideId, bool currentStatus) async {
    try {
      if (currentStatus) {
        // If the ride was already started and is now ending, delete the ride
        await _firestore.collection('bookedride').doc(rideId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ride ended and removed from the list.')),
        );
      } else {
        // If the ride is just starting, update the status
        await _firestore.collection('bookedride').doc(rideId).update({
          'isRideStarted': !currentStatus, // Toggle the status to true (start ride)
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ride started.')),
        );
      }
      setState(() {}); // Refresh UI after update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update ride status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Carpool App')),
      body: FutureBuilder<List<BookedList>>(
        future: fetchBookedRides(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No rides available.'));
          } else {
            final bookedRides = snapshot.data!;
            return ListView.builder(
              itemCount: bookedRides.length,
              itemBuilder: (context, index) {
                final ride = bookedRides[index];
                return ListTile(
                  title: Text(
                      '${ride.driverName} : ${ride.driverNumber} - ${ride.departureTime} to ${ride.destinationName}'
                  ),
                  subtitle: Text('Passenger: ${ride.passengerName}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      updateRideStatus(ride.id, ride.isRideStarted); // Start or end the ride
                    },
                    child: Text(ride.isRideStarted ? 'End Ride' : 'Start Ride'),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
