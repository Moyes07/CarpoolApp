import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ride.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  LatLng? _startLocation;
  LatLng? _destination;
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _loading = true;

  // Firebase database reference
  //final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref().child('enlistedrides');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


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

  void _submitRequest() {
    if (_startLocation != null &&
        _destination != null &&
        _selectedDate != null &&
        _driverNumberController.text.isNotEmpty &&
        _startLocationNameController.text.isNotEmpty &&
        _destinationNameController.text.isNotEmpty) {
      Ride newRide = Ride(
        id: DateTime.now().toString(),
        driverName: _driverNameController.text,
        startLocation: _startLocation.toString(),
        destination: _destination.toString(),
        startLocationName: _startLocationNameController.text,
        destinationName: _destinationNameController.text,
        departureTime: _selectedDate!,
        driverNumber: _driverNumberController.text,
      );

      // Storing ride data in Firestore
      _firestore.collection('enlistedrides').add({
        'id': newRide.id,
        'driverName': newRide.driverName,
        'startLocation': newRide.startLocation,
        'destination': newRide.destination,
        'startLocationName': newRide.startLocationName,
        'destinationName': newRide.destinationName,
        'departureTime': newRide.departureTime.toIso8601String(),
      }).then((_) {
        print("Ride submitted successfully.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ride requested: ${newRide.driverName}')),
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

  void _onMapTap(LatLng location) {
    setState(() {
      if (_startLocation == null) {
        _startLocation = location;
      } else {
        _destination = location;
      }
    });
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
              ),
              SizedBox(height: 10),
              TextField(
                controller: _startLocationNameController,
                decoration: InputDecoration(labelText: 'Driver Number'),
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
                'Start Location: ${_startLocation != null ? _startLocation.toString() : 'Not selected'}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Destination: ${_destination != null ? _destination.toString() : 'Not selected'}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Container(
                height: 400, // Height of the map
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
                child: Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
