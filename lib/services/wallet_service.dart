import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../core/errors.dart';
import '../models/wallet_model.dart';
import '../models/commission_model.dart';
import '../models/ride_request_model.dart';
import 'firestore_service.dart';

class WalletService {
  final FirestoreService _firestore;
  final Uuid _uuid = const Uuid();

  WalletService(this._firestore);

  Future<WalletModel> getOrCreateWallet(String userId, String userRole) async {
    final existing = await _firestore.getWallet(userId);
    if (existing != null) return existing;
    final wallet = WalletModel(
      id: _uuid.v4(),
      userId: userId,
      userRole: userRole,
      balance: AppConstants.testCreditAmount,
    );
    await _firestore.setWallet(wallet);
    await _firestore.addTransaction(
      TransactionModel(
        id: _uuid.v4(),
        walletId: wallet.id,
        userId: userId,
        type: TransactionType.credit,
        amount: AppConstants.testCreditAmount,
        balanceBefore: 0,
        balanceAfter: AppConstants.testCreditAmount,
        reason: TransactionReason.testCredit,
        description: 'Testing credit for using RideKSA',
      ),
    );
    return wallet;
  }

  Future<TransactionModel> reserveAndCreateBooking({
    required String userId,
    required double amount,
    required RideRequestModel ride,
    required String frappeBookingId,
  }) async {
    if (amount <= 0) {
      throw const WalletException('Booking amount must be positive');
    }
    final wallet = await getOrCreateWallet(userId, 'passenger');
    final db = FirebaseFirestore.instance;
    final walletRef = db
        .collection(AppConstants.firestoreWallets)
        .doc(wallet.id);
    final transactionRef = db
        .collection(AppConstants.firestoreTransactions)
        .doc('booking-reservation-${ride.id}');
    final rideRef = db
        .collection(AppConstants.firestoreActiveRides)
        .doc(ride.id);

    return db.runTransaction((transaction) async {
      final existing = await transaction.get(transactionRef);
      if (existing.exists) {
        return TransactionModel.fromJson(existing.data()!);
      }
      final walletSnapshot = await transaction.get(walletRef);
      if (!walletSnapshot.exists) {
        throw const WalletException('Wallet is not available');
      }
      final current = WalletModel.fromJson(walletSnapshot.data()!);
      if (current.balance < amount) {
        throw const WalletException(
          'Insufficient credits. Top up before booking.',
        );
      }
      final balanceAfter = current.balance - amount;
      final bookingTransaction = TransactionModel(
        id: transactionRef.id,
        walletId: current.id,
        userId: userId,
        type: TransactionType.debit,
        amount: amount,
        balanceBefore: current.balance,
        balanceAfter: balanceAfter,
        reason: TransactionReason.ridePayment,
        referenceId: ride.id,
        referenceType: 'ride_request',
        description: 'Booking payment reserved',
      );
      transaction.set(transactionRef, bookingTransaction.toJson());
      transaction.set(
        walletRef,
        WalletModel(
          id: current.id,
          userId: userId,
          userRole: current.userRole,
          balance: balanceAfter,
          totalEarned: current.totalEarned,
          totalSpent: current.totalSpent + amount,
          createdAt: current.createdAt,
        ).toJson(),
      );
      transaction.set(rideRef, {
        ...ride.toJson(),
        'frappe_booking_id': frappeBookingId,
      });
      return bookingTransaction;
    });
  }

  Future<TransactionModel> topUp(
    String userId,
    double amount, {
    String? paymentMethod,
    String? paymentRef,
  }) async {
    if (amount <= 0) throw const WalletException('Amount must be positive');
    final wallet = await getOrCreateWallet(userId, 'passenger');
    final pending = paymentMethod == 'bank_transfer';
    final pendingTx = TransactionModel(
      id: _uuid.v4(),
      walletId: wallet.id,
      userId: userId,
      type: TransactionType.credit,
      amount: amount,
      balanceBefore: wallet.balance,
      balanceAfter: pending ? wallet.balance : wallet.balance + amount,
      reason: TransactionReason.topUp,
      paymentMethod: paymentMethod,
      paymentReference: paymentRef,
      status: pending ? TransactionStatus.pending : TransactionStatus.completed,
      description: 'Wallet top-up of ﷼ ${amount.toStringAsFixed(2)}',
    );
    await _firestore.addTransaction(pendingTx);
    if (pending) {
      return pendingTx;
    }
    final balanceAfter = wallet.balance + amount;
    await _firestore.setWallet(
      WalletModel(
        id: wallet.id,
        userId: userId,
        userRole: wallet.userRole,
        balance: balanceAfter,
        totalEarned: wallet.totalEarned,
        totalSpent: wallet.totalSpent,
      ),
    );
    return pendingTx;
  }

  Future<TransactionModel> deductForRide(
    String userId,
    double amount,
    String tripId,
  ) async {
    if (amount <= 0) throw const WalletException('Amount must be positive');
    final wallet = await getOrCreateWallet(userId, 'passenger');
    if (wallet.balance < amount) {
      throw const WalletException('Insufficient wallet balance');
    }
    final balanceAfter = wallet.balance - amount;
    final tx = TransactionModel(
      id: _uuid.v4(),
      walletId: wallet.id,
      userId: userId,
      type: TransactionType.debit,
      amount: amount,
      balanceBefore: wallet.balance,
      balanceAfter: balanceAfter,
      reason: TransactionReason.ridePayment,
      referenceId: tripId,
      referenceType: 'trip',
      description: 'Ride payment of ﷼ ${amount.toStringAsFixed(2)}',
    );
    await _firestore.addTransaction(tx);
    await _firestore.setWallet(
      WalletModel(
        id: wallet.id,
        userId: userId,
        userRole: wallet.userRole,
        balance: balanceAfter,
        totalEarned: wallet.totalEarned,
        totalSpent: wallet.totalSpent + amount,
      ),
    );
    return tx;
  }

  Future<TransactionModel> creditEarnings(
    String userId,
    double amount,
    String tripId,
    String companyId,
  ) async {
    final wallet = await getOrCreateWallet(userId, 'driver');
    final commission = CommissionModel.calculate(
      id: _uuid.v4(),
      tripId: tripId,
      companyId: companyId,
      driverId: userId,
      fare: amount,
      rate: AppConstants.commissionRate,
    );
    final driverAmount = commission.driverEarnings;
    final balanceAfter = wallet.balance + driverAmount;

    await _firestore.setCommission(commission);

    final tx = TransactionModel(
      id: _uuid.v4(),
      walletId: wallet.id,
      userId: userId,
      type: TransactionType.credit,
      amount: driverAmount,
      balanceBefore: wallet.balance,
      balanceAfter: balanceAfter,
      reason: TransactionReason.ridePayment,
      referenceId: tripId,
      referenceType: 'trip',
      description:
          'Ride earnings ﷼ ${driverAmount.toStringAsFixed(2)} (5% commission: ﷼ ${commission.commissionAmount.toStringAsFixed(2)})',
    );
    await _firestore.addTransaction(tx);
    await _firestore.setWallet(
      WalletModel(
        id: wallet.id,
        userId: userId,
        userRole: wallet.userRole,
        balance: balanceAfter,
        totalEarned: wallet.totalEarned + driverAmount,
        totalSpent: wallet.totalSpent,
      ),
    );
    return tx;
  }
}
