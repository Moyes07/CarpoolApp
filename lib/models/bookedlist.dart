class BookedList {
  final String id; // This will store the Firestore document ID
  final String departureTime;
  final String destination;
  final String driverName;
  final String passengerName;
  final String driverNumber;
  final String destinationName;
  final bool isRideStarted;


  BookedList({
    required this.id,  // Firestore-generated document ID
    required this.departureTime,
    required this.destination,
    required this.driverName,
    required this.destinationName,
    required this.passengerName,
    required this.driverNumber,
    required this.isRideStarted,

  });

  // Factory method to create a BookedList from JSON
  factory BookedList.fromJson(Map<String, dynamic> json,String id) {
    return BookedList(
      id: id,
      departureTime: json['departureTime'] ?? 'Unknown Time', // Default value
      destination: json['destination'] ?? 'Unknown Destination', // Default value
      driverName: json['driverName'] ?? 'Unknown Driver', // Default value
      destinationName: json['destinationName']?? 'Unknown Destination',
      passengerName: json['passengerName'] ?? 'Unknown Passenger', // Default value
      driverNumber: json['passengerPhone'] ?? 'Unknown Number', // Default value
      isRideStarted: json['isRideStarted'] as bool? ?? false, // Default to false if not present
    );
  }


}
