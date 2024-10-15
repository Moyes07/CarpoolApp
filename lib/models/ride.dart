class Ride {
  final String id;
  final String driverName;
  final String startLocation;
  final String destination;
  final String startLocationName;
  final String destinationName;
  final DateTime departureTime;
  final String driverNumber;

  Ride({
    required this.id,
    required this.driverName,
    required this.startLocation,
    required this.destination,
    required this.startLocationName,
    required this.destinationName,
    required this.departureTime,
    required this.driverNumber,
  });
  @override
  String toString() {
    return 'Ride(id: $id, driverName: $driverName, startLocation: $startLocation, '
        'destination: $destination, startLocationName: $startLocationName, driverNumber: $driverNumber'
        'destinationName: $destinationName, departureTime: ${departureTime.toIso8601String()})';
  }
}
