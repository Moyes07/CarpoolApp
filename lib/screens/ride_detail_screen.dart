import 'package:flutter/material.dart';
import '../models/ride.dart';

class RideDetailScreen extends StatelessWidget {
  final Ride ride;

  RideDetailScreen({required this.ride});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ride Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Driver: ${ride.driverName}', style: TextStyle(fontSize: 20)),
            SizedBox(height: 8),
            Text('From: ${ride.startLocation}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('To: ${ride.destination}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Departure: ${ride.departureTime}', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
