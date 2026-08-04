enum TransactionType { credit, debit }
enum TransactionStatus { pending, completed, failed }
enum TransactionReason { topUp, ridePayment, commission, refund, withdrawal, testCredit, resaleProfitFee }

class WalletModel {
  final String id;
  final String userId;
  final String userRole;
  final double balance;
  final double totalEarned;
  final double totalSpent;
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletModel({
    required this.id,
    required this.userId,
    required this.userRole,
    this.balance = 0,
    this.totalEarned = 0,
    this.totalSpent = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
    id: json['id'] as String? ?? '',
    userId: json['user_id'] as String? ?? '',
    userRole: json['user_role'] as String? ?? 'passenger',
    balance: (json['balance'] as num?)?.toDouble() ?? 0,
    totalEarned: (json['total_earned'] as num?)?.toDouble() ?? 0,
    totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
    createdAt: (json['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
    updatedAt: (json['updated_at'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'user_role': userRole,
    'balance': balance,
    'total_earned': totalEarned,
    'total_spent': totalSpent,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class TransactionModel {
  final String id;
  final String walletId;
  final String userId;
  final TransactionType type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final TransactionReason reason;
  final TransactionStatus status;
  final String? referenceId;
  final String? referenceType;
  final String? description;
  final String? paymentMethod;
  final String? paymentReference;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.reason,
    this.status = TransactionStatus.completed,
    this.referenceId,
    this.referenceType,
    this.description,
    this.paymentMethod,
    this.paymentReference,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get amountFormatted => '${type == TransactionType.credit ? '+' : '-'}﷼ ${amount.toStringAsFixed(2)}';

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
    id: json['id'] as String? ?? '',
    walletId: json['wallet_id'] as String? ?? '',
    userId: json['user_id'] as String? ?? '',
    type: (json['type'] as String? ?? 'debit') == 'credit' ? TransactionType.credit : TransactionType.debit,
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    balanceBefore: (json['balance_before'] as num?)?.toDouble() ?? 0,
    balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0,
    reason: TransactionReason.values.firstWhere(
      (r) => r.name == (json['reason'] as String? ?? ''),
      orElse: () => TransactionReason.ridePayment,
    ),
    status: TransactionStatus.values.firstWhere(
      (s) => s.name == (json['status'] as String? ?? ''),
      orElse: () => TransactionStatus.completed,
    ),
    referenceId: json['reference_id'] as String?,
    referenceType: json['reference_type'] as String?,
    description: json['description'] as String?,
    paymentMethod: json['payment_method'] as String?,
    paymentReference: json['payment_reference'] as String?,
    createdAt: (json['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'wallet_id': walletId,
    'user_id': userId,
    'type': type.name,
    'amount': amount,
    'balance_before': balanceBefore,
    'balance_after': balanceAfter,
    'reason': reason.name,
    'status': status.name,
    'reference_id': referenceId,
    'reference_type': referenceType,
    'description': description,
    'payment_method': paymentMethod,
    'payment_reference': paymentReference,
    'created_at': createdAt,
  };
}
