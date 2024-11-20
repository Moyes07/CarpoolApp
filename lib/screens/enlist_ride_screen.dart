import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // Import the geocoding package
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride.dart';
import 'package:intl/intl.dart';

class EnlistRideScreen extends StatefulWidget {
  @override
  _EnlistRideScreenState createState() => _EnlistRideScreenState();
}

class _EnlistRideScreenState extends State<EnlistRideScreen> {
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _driverNumberController = TextEditingController();
  final TextEditingController _startLocationNameController = TextEditingController();
  final TextEditingController _destinationNameController = TextEditingController();
  DateTime? _selectedDate;
  String? _startLocationAddress; // Human-readable address for start location
  String? _destinationAddress; // Human-readable address for destination
  LatLng? _startLatLng; // Store the actual LatLng coordinates for start location
  LatLng? _destinationLatLng; // Store the actual LatLng coordinates for destination
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _loading = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchDriverInfo(); // Fetch the current user's driver info
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

  Future<void> _fetchDriverInfo() async {
    // Get the current user
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      String userEmail = currentUser.email!;
      print('Fetching data for email: $userEmail');

      // Query the users collection to find the document with the user's email
      QuerySnapshot userSnapshot = await _firestore.collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1) // Limit to 1 to ensure you only get one user document
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = userSnapshot.docs.first;

        // Print the document data for debugging
        print('User found: ${userDoc.data()}');

        // Assuming the user document contains fields 'name' and 'phone'
        setState(() {
          _driverNameController.text = userDoc['name']; // Set the driver's name
          _driverNumberController.text = userDoc['phone']; // Set the driver's phone number
        });
      } else {
        print('User not found in Firestore');
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

  // Reverse geocoding function to convert LatLng to address
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

  Future<void> _submitRequest() async {
    if (_startLatLng != null &&
        _destinationLatLng != null &&
        _selectedDate != null &&
        _startLocationNameController.text.isNotEmpty &&
        _destinationNameController.text.isNotEmpty) {

      Ride newRide = Ride(
        id: DateTime.now().toString(),
        driverName: _driverNameController.text,
        startLocation: _startLatLng.toString(), // Saving LatLng for start location
        destination: _destinationLatLng.toString(), // Saving LatLng for destination
        startLocationName: _startLocationNameController.text, // Address of the start location
        destinationName: _destinationNameController.text, // Address of the destination
        departureTime: _selectedDate!,
        driverNumber: _driverNumberController.text,
      );

      // Storing ride data in Firestore
      _firestore.collection('enlistedrides').add({
        'id': newRide.id,
        'driverName': newRide.driverName,
        'startLocation': newRide.startLocation, // Original LatLng value
        'destination': newRide.destination, // Original LatLng value
        'startLocationName': newRide.startLocationName, // Human-readable address
        'destinationName': newRide.destinationName, // Human-readable address
        'departureTime': newRide.departureTime.toIso8601String(),
        'driverNumber': newRide.driverNumber,
      }).then((_) {
        print("Ride submitted successfully.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ride enlisted: ${newRide.driverName}')),
        );
      }).catchError((error) {
        print("Failed to submit ride: $error");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit ride: $error')),
        );
      });
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
    if (_startLatLng == null) {
      String startAddress = await _getAddressFromLatLng(location); // Get the address for start location
      setState(() {
        _startLatLng = location; // Store the actual coordinates
        _startLocationAddress = startAddress; // Save and display the address
        _startLocationNameController.text = startAddress; // Store in the text field
      });
    } else {
      String destinationAddress = await _getAddressFromLatLng(location); // Get the address for destination
      setState(() {
        _destinationLatLng = location; // Store the actual coordinates
        _destinationAddress = destinationAddress; // Save and display the address
        _destinationNameController.text = destinationAddress; // Store in the text field
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enlist a Ride')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _driverNameController,
                decoration: InputDecoration(labelText: 'Driver Name'),
                readOnly: true, // Make the field read-only since we fetch the data
              ),
              SizedBox(height: 10),
              TextField(
                controller: _driverNumberController,
                decoration: InputDecoration(labelText: 'Driver Number'),
                readOnly: true, // Make the field read-only since we fetch the data
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
                'Start Location: ${_startLatLng != null ? _startLatLng : 'Not selected'}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Destination: ${_destinationLatLng != null ? _destinationLatLng : 'Not selected'}',
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
                    if (_startLatLng != null)
                      Marker(
                        markerId: MarkerId('start'),
                        position: _startLatLng!,
                        infoWindow: InfoWindow(title: 'Start Location'),
                      ),
                    if (_destinationLatLng != null)
                      Marker(
                        markerId: MarkerId('destination'),
                        position: _destinationLatLng!,
                        infoWindow: InfoWindow(title: 'Destination'),
                      ),
                  },
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitRequest,
                child: Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
