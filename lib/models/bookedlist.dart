class BookedList {
  final String departureTime;
  final String destination;
  final String driverName;
  final String passengerName;
  final String driverNumber;

  BookedList({
    required this.departureTime,
    required this.destination,
    required this.driverName,
    required this.passengerName,
    required this.driverNumber,
  });

  // Factory method to create a BookedList from JSON
  factory BookedList.fromJson(Map<String, dynamic> json) {
    return BookedList(
      departureTime: json['departureTime'] ?? 'Unknown Time', // Default value
      destination: json['destination'] ?? 'Unknown Destination', // Default value
      driverName: json['driverName'] ?? 'Unknown Driver', // Default value
      passengerName: json['passengerName'] ?? 'Unknown Passenger', // Default value
      driverNumber: json['driverNumber'] ?? 'Unknown Number', // Default value
    );
  }
}
