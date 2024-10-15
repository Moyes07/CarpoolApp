import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RideRequestScreen extends StatefulWidget {
  @override
  _RideRequestScreenState createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _startLocationNameController = TextEditingController();
  final TextEditingController _destinationNameController = TextEditingController();
  DateTime? _selectedDate;

  LatLng? _startLocation;
  LatLng? _destination;
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _loading = true;
  List<Map<String, dynamic>> _matchingRides = [];

  final CollectionReference _ridesCollection = FirebaseFirestore.instance.collection('enlistedrides');

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _loading = false;
    });
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(pickedDate.year, pickedDate.month,
              pickedDate.day, pickedTime.hour, pickedTime.minute);
        });
      }
    }
  }

  // Function to convert LatLng to string format
  String _latLngToString(LatLng latLng) {
    return 'LatLng(${latLng.latitude}, ${latLng.longitude})';
  }

// Function to convert user input into LatLng format
  LatLng _convertUserInputToLatLng(String userInput) {
    // Here you can implement any logic to convert user input to LatLng.
    // For example, if the input is two separate fields for latitude and longitude,
    // you might use them directly.
    // Let's assume the user inputs latitude and longitude as a comma-separated string
    final parts = userInput.split(',');
    if (parts.length == 2) {
      double latitude = double.parse(parts[0].trim());
      double longitude = double.parse(parts[1].trim());
      return LatLng(latitude, longitude);
    }
    throw FormatException('Invalid LatLng input format');
  }

// Updated comparison function for string lat/lng
  bool _compareLatLng(String latLng1, String latLng2) {
    const double threshold = 0.1; // Adjust this value based on your needs

    // Parse string coordinates
    final parts1 = latLng1.replaceAll('LatLng(', '').replaceAll(')', '').split(',');
    final parts2 = latLng2.replaceAll('LatLng(', '').replaceAll(')', '').split(',');

    if (parts1.length == 2 && parts2.length == 2) {
      double latitude1 = double.parse(parts1[0].trim());
      double longitude1 = double.parse(parts1[1].trim());
      double latitude2 = double.parse(parts2[0].trim());
      double longitude2 = double.parse(parts2[1].trim());

      return (latitude1 - latitude2).abs() < threshold &&
          (longitude1 - longitude2).abs() < threshold;
    }

    throw FormatException('Invalid LatLng format');
  }

// Use _compareLatLng in your ride matching logic
  Future<void> _submitRequest() async {
    if (_startLocation != null &&
        _destination != null &&
        _selectedDate != null &&
        _startLocationNameController.text.isNotEmpty &&
        _destinationNameController.text.isNotEmpty) {

      // Fetch existing ride requests from Firestore
      QuerySnapshot querySnapshot = await _ridesCollection.get();
      List<Map<String, dynamic>> existingRides = querySnapshot.docs
          .map((doc) => Map<String, dynamic>.from(doc.data() as Map))
          .toList();

      // Print the records extracted from the database
      print('Existing Rides from Database:');
      for (var ride in existingRides) {
        print('Driver Name: ${ride['driverName']}, Departure Time: ${ride['departureTime']}, Destination: ${ride['destination']}');
      }

      // Print user-entered values
      print('User Input:');
      print('Passenger Name: ${_driverNameController.text}');
      print('Start Location: ${_startLocation}');
      print('Destination: ${_destination}');
      print('Selected Date: ${_selectedDate}');

      // Format user destination in LatLng format
      String userDestination = 'LatLng(${_destination!.latitude}, ${_destination!.longitude})';

      // Compare the new request with existing rides
      _matchingRides = existingRides.where((ride) {
        try {
          // Parse ride['departureTime'] from String to DateTime
          DateTime rideDateTime = DateTime.parse(ride['departureTime']);

          // Check if the time difference is within 1 hour (either direction)
          Duration timeDifference = rideDateTime.difference(_selectedDate!).abs();

          // Match if the time difference is less than or equal to 1 hour (60 minutes)
          if (timeDifference.inMinutes <= 60) {
            // Use the existing destination string from the database
            String destinationString = ride['destination'];

            // Compare lat/lng for destination using the updated function
            return _compareLatLng(destinationString, userDestination);
          }
        } catch (e) {
          print('Error parsing date or coordinates: $e');
          return false; // Skip this ride if parsing fails
        }

        return false; // Skip if parsing fail
      }).toList();

      print('Matching Rides: $_matchingRides');

      if (_matchingRides.isNotEmpty) {
        _showMatchingRidesDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No matching rides found.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields.')),
      );
    }
  }



// Helper function to parse LatLng string to LatLng object
  LatLng _parseLatLng(String latLngString) {
    final RegExp latLngRegex = RegExp(r'LatLng\(([^,]+),\s?([^)]+)\)');
    final Match? match = latLngRegex.firstMatch(latLngString);

    if (match != null) {
      double latitude = double.parse(match.group(1)!);
      double longitude = double.parse(match.group(2)!);
      return LatLng(latitude, longitude);
    } else {
      throw FormatException('Invalid LatLng format');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng location) {
    setState(() {
      if (_startLocation == null) {
        _startLocation = location;
      } else {
        _destination = location;
      }
    });
  }

  void _showMatchingRidesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Matching Rides'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: _matchingRides.length,
              itemBuilder: (context, index) {
                final ride = _matchingRides[index];
                return ListTile(
                  title: Text('Driver Name: ${ride['driverName']}'),
                  subtitle: Text('Departure Time: ${ride['departureTime']}'),
                  onTap: () => _bookRide(ride), // Call booking method on tap
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _bookRide(Map<String, dynamic> ride) async {
    try {
      // Create a reference to the booked rides collection
      final CollectionReference bookedRidesCollection =
      FirebaseFirestore.instance.collection('bookedride');

      // Add the selected ride to the booked rides collection
      await bookedRidesCollection.add({
        'driverName': ride['driverName'],
        'departureTime': ride['departureTime'],
        'destination': ride['destination'],
        'passengerName': _driverNameController.text,
        // Add any additional fields as necessary
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ride booked successfully!')),
      );

      // Optionally close the dialog after booking
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book ride: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Request a Ride')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _driverNameController,
                decoration: InputDecoration(labelText: 'Passenger Name'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _startLocationNameController,
                decoration: InputDecoration(labelText: 'Start Location Name'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _destinationNameController,
                decoration: InputDecoration(labelText: 'Destination Name'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _selectDate,
                child: Text(_selectedDate == null
                    ? 'Select Date & Time'
                    : DateFormat.yMMMd().add_jm().format(_selectedDate!)),
              ),
              SizedBox(height: 20),
              Text(
                'Start Location: ${_startLocation != null ? _latLngToString(_startLocation!) : 'Not selected'}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Destination: ${_destination != null ? _latLngToString(_destination!) : 'Not selected'}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Container(
                height: 400,
                width: double.infinity,
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  onTap: _onMapTap,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 14,
                  ),
                  markers: {
                    if (_startLocation != null)
                      Marker(
                        markerId: MarkerId('start'),
                        position: _startLocation!,
                        infoWindow: InfoWindow(title: 'Start Location'),
                      ),
                    if (_destination != null)
                      Marker(
                        markerId: MarkerId('destination'),
                        position: _destination!,
                        infoWindow: InfoWindow(title: 'Destination'),
                      ),
                  },
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitRequest,
                child: Text('Find Matching Rides'),
              ),
              SizedBox(height: 20),
              // Display matching rides in a dropdown
              if (_matchingRides.isNotEmpty)
                DropdownButton<Map<String, dynamic>>(
                  hint: Text('Matching Rides'),
                  items: _matchingRides.map((ride) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: ride,
                      child: Text('${ride['driverName']} - ${ride['departureTime']}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    // Handle selected ride if necessary
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
