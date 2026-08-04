class TripTransferModel {
  final String id;
  final String rideRequestId;
  final String tripId;
  final String sellerId;
  final String? buyerId;
  final double originalAmount;
  final double sellAmount;
  final double profitAmount;
  final double platformFeeOnProfit;
  final String status;
  final String? reason;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  TripTransferModel({
    required this.id,
    required this.rideRequestId,
    required this.tripId,
    required this.sellerId,
    this.buyerId,
    required this.originalAmount,
    required this.sellAmount,
    double? platformFeeOnProfit,
    this.status = 'open',
    this.reason,
    DateTime? createdAt,
    this.acceptedAt,
  }) : profitAmount = sellAmount > originalAmount ? sellAmount - originalAmount : 0,
       platformFeeOnProfit = platformFeeOnProfit ?? ((sellAmount > originalAmount ? sellAmount - originalAmount : 0) * 0.05),
       createdAt = createdAt ?? DateTime.now();

  factory TripTransferModel.fromJson(Map<String, dynamic> json) => TripTransferModel(
    id: json['id'] as String? ?? '',
    rideRequestId: json['ride_request_id'] as String? ?? '',
    tripId: json['trip_id'] as String? ?? '',
    sellerId: json['seller_id'] as String? ?? '',
    buyerId: json['buyer_id'] as String?,
    originalAmount: (json['original_amount'] as num?)?.toDouble() ?? 0,
    sellAmount: (json['sell_amount'] as num?)?.toDouble() ?? 0,
    platformFeeOnProfit: (json['platform_fee_on_profit'] as num?)?.toDouble(),
    status: json['status'] as String? ?? 'open',
    reason: json['reason'] as String?,
    createdAt: (json['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
    acceptedAt: (json['accepted_at'] as dynamic)?.toDate(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ride_request_id': rideRequestId,
    'trip_id': tripId,
    'seller_id': sellerId,
    'buyer_id': buyerId,
    'original_amount': originalAmount,
    'sell_amount': sellAmount,
    'profit_amount': profitAmount,
    'platform_fee_on_profit': platformFeeOnProfit,
    'status': status,
    'reason': reason,
    'created_at': createdAt,
    'accepted_at': acceptedAt,
  };
}
