class ChatMessageModel {
  final String id;
  final String rideRequestId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.rideRequestId,
    required this.senderId,
    required this.senderName,
    required this.message,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) => ChatMessageModel(
    id: json['id'] as String? ?? '',
    rideRequestId: json['ride_request_id'] as String? ?? '',
    senderId: json['sender_id'] as String? ?? '',
    senderName: json['sender_name'] as String? ?? 'User',
    message: json['message'] as String? ?? '',
    createdAt: (json['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ride_request_id': rideRequestId,
    'sender_id': senderId,
    'sender_name': senderName,
    'message': message,
    'created_at': createdAt,
  };
}
