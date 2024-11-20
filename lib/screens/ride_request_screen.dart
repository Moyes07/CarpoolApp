import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RideRequestScreen extends StatefulWidget {
  @override
  _RideRequestScreenState createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _startLocationNameController = TextEditingController();
  final TextEditingController _destinationNameController = TextEditingController();
  DateTime? _selectedDate;

  LatLng? _startLocation;
  LatLng? _destination;
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _loading = true;
  List<Map<String, dynamic>> _matchingRides = [];
  String? _userEmail;  // Added to store email

  final CollectionReference _ridesCollection = FirebaseFirestore.instance.collection('enlistedrides');

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchPassengerInfo(); // Fetch the current passenger info
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

  Future<void> _fetchPassengerInfo() async {
    // Get the current user
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      String userEmail = currentUser.email!;
      _userEmail = userEmail;  // Store the email for later use
      print('Fetching data for email: $userEmail');

      // Query the users collection to find the document with the user's email
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = userSnapshot.docs.first;

        // Print the document data for debugging
        print('Passenger found: ${userDoc.data()}');

        // Assuming the user document contains fields 'name' and 'phone'
        setState(() {
          _driverNameController.text = userDoc['name']; // Set the passenger's name
          _phoneNumberController.text = userDoc['phone']; // Set the passenger's phone number
        });
      } else {
        print('Passenger not found in Firestore');
      }
    }
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

  // Function to convert LatLng to a human-readable address
  Future<String> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks[0];
      return "${place.street}, ${place.locality}, ${place.country}";
    } catch (e) {
      print(e);
      return "Unknown Location";
    }
  }

  // Function to convert LatLng to string format
  String _latLngToString(LatLng latLng) {
    return 'LatLng(${latLng.latitude}, ${latLng.longitude})';
  }

  bool _compareLatLng(String latLng1, String latLng2) {
    const double latitudeThreshold = 0.045;  // Set a threshold for latitude comparison
    const double longitudeThreshold = 0.064;  // Set a threshold for longitude comparison

    final parts1 = latLng1.replaceAll('LatLng(', '').replaceAll(')', '').split(',');
    final parts2 = latLng2.replaceAll('LatLng(', '').replaceAll(')', '').split(',');

    if (parts1.length == 2 && parts2.length == 2) {
      double latitude1 = double.parse(parts1[0].trim());
      double longitude1 = double.parse(parts1[1].trim());
      double latitude2 = double.parse(parts2[0].trim());
      double longitude2 = double.parse(parts2[1].trim());

      // Compare latitudes and longitudes separately with their respective thresholds
      bool latitudeComparison = (latitude1 - latitude2).abs() <= latitudeThreshold;
      bool longitudeComparison = (longitude1 - longitude2).abs() <= longitudeThreshold;

      return latitudeComparison && longitudeComparison;
    }

    throw FormatException('Invalid LatLng format');
  }


  Future<void> _submitRequest() async {
    if (_startLocation != null &&
        _destination != null &&
        _selectedDate != null &&
        _startLocationNameController.text.isNotEmpty &&
        _destinationNameController.text.isNotEmpty) {

      QuerySnapshot querySnapshot = await _ridesCollection.get();
      List<Map<String, dynamic>> existingRides = querySnapshot.docs
          .map((doc) => Map<String, dynamic>.from(doc.data() as Map))
          .toList();

      print('Existing Rides from Database:');
      for (var ride in existingRides) {
        print('Driver Name: ${ride['driverName']}, Departure Time: ${ride['departureTime']}, Destination: ${ride['destination']}');
      }

      String userDestination = 'LatLng(${_destination!.latitude}, ${_destination!.longitude})';

      _matchingRides = existingRides.where((ride) {
        try {
          DateTime rideDateTime = DateTime.parse(ride['departureTime']);
          Duration timeDifference = rideDateTime.difference(_selectedDate!).abs();

          if (timeDifference.inMinutes <= 60) {
            String destinationString = ride['destination'];
            return _compareLatLng(destinationString, userDestination);
          }
        } catch (e) {
          print('Error parsing date or coordinates: $e');
          return false;
        }

        return false;
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

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng location) async {
    if (_startLocation == null) {
      String startAddress = await _getAddressFromLatLng(location); // Get address for start location
      setState(() {
        _startLocation = location; // Store LatLng
        _startLocationNameController.text = startAddress; // Update the start location name field
      });
    } else {
      String destinationAddress = await _getAddressFromLatLng(location); // Get address for destination
      setState(() {
        _destination = location; // Store LatLng
        _destinationNameController.text = destinationAddress; // Update the destination name field
      });
    }
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
                  subtitle: Text('Departure Time: ${ride['departureTime']},'),
                  onTap: () => _bookRide(ride),
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
      final CollectionReference bookedRidesCollection = FirebaseFirestore.instance.collection('bookedride');

      await bookedRidesCollection.add({
        'driverName': ride['driverName'],
        'departureTime': ride['departureTime'],
        'destination': ride['destination'],
        'destinationName': _destinationNameController.text,
        'passengerName': _driverNameController.text,
        'passengerPhone': _phoneNumberController.text, // Add passenger's phone number
        'passengerEmail': _userEmail, // Add passenger's email
        'isRideStarted': false, // Add the new bool field to indicate if the ride has started
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ride booked successfully!')),
      );

      //Navigator.of(context).pop();
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
                readOnly: true, // Passenger name is fetched, not editable
              ),
              SizedBox(height: 10),
              TextField(
                controller: _phoneNumberController, // Display fetched phone number
                decoration: InputDecoration(labelText: 'Passenger Phone Number'),
                readOnly: true, // Passenger phone number is fetched, not editable
              ),
              SizedBox(height: 10),
              TextField(
                controller: _startLocationNameController,
                decoration: InputDecoration(labelText: 'Start Location Name'),
                readOnly: true, // Populated via reverse geocoding, not editable
              ),
              SizedBox(height: 10),
              TextField(
                controller: _destinationNameController,
                decoration: InputDecoration(labelText: 'Destination Name'),
                readOnly: true, // Populated via reverse geocoding, not editable
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
            ],
          ),
        ),
      ),
    );
  }
}
