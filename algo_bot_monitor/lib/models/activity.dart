class Activity {
  final int? id;
  final String type; // buy, sell, entry, exit, error, warning
  final DateTime timestamp;
  final String message;
  final String details;

  Activity({
    this.id,
    required this.type,
    required this.timestamp,
    required this.message,
    required this.details,
  });

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as int?,
      type: map['type']?.toString() ?? 'info',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp'].toString()) 
          : DateTime.now(),
      message: map['message']?.toString() ?? '',
      details: map['details']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'message': message,
      'details': details,
    };
  }
}
