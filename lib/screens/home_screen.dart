import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bookedlist.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<BookedList>> fetchBookedRides() async {
    final snapshot = await _firestore.collection('bookedride').get();
    return snapshot.docs.map((doc) {
      return BookedList.fromJson(doc.data() as Map<String, dynamic>);
    }).toList();
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
                return ListTile(
                  title: Text('${bookedRides[index].driverName} - ${bookedRides[index].departureTime} to ${bookedRides[index].destination}'),
                  subtitle: Text('Passenger: ${bookedRides[index].passengerName}'),
                  // Removed the onTap navigation
                );
              },
            );
          }
        },
      ),
    );
  }
}
