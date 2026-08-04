import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../core/errors.dart';
import '../models/wallet_model.dart';
import '../models/commission_model.dart';
import 'firestore_service.dart';

class WalletService {
  final FirestoreService _firestore;
  final Uuid _uuid = const Uuid();

  WalletService(this._firestore);

  Future<WalletModel> getOrCreateWallet(String userId, String userRole) async {
    final existing = await _firestore.getWallet(userId);
    if (existing != null) return existing;
    final wallet = WalletModel(
      id: _uuid.v4(), userId: userId, userRole: userRole,
      balance: AppConstants.testCreditAmount,
    );
    await _firestore.setWallet(wallet);
    await _firestore.addTransaction(TransactionModel(
      id: _uuid.v4(), walletId: wallet.id, userId: userId,
      type: TransactionType.credit, amount: AppConstants.testCreditAmount,
      balanceBefore: 0, balanceAfter: AppConstants.testCreditAmount,
      reason: TransactionReason.testCredit,
      description: 'Testing credit for using RideKSA',
    ));
    return wallet;
  }

  Future<TransactionModel> reserveForBooking(String userId, double amount, String rideRequestId) async {
    if (amount <= 0) throw const WalletException('Booking amount must be positive');
    final wallet = await getOrCreateWallet(userId, 'passenger');
    if (wallet.balance < amount) throw const WalletException('Insufficient credits. Top up before booking.');
    final balanceAfter = wallet.balance - amount;
    final tx = TransactionModel(
      id: _uuid.v4(), walletId: wallet.id, userId: userId,
      type: TransactionType.debit, amount: amount,
      balanceBefore: wallet.balance, balanceAfter: balanceAfter,
      reason: TransactionReason.ridePayment,
      referenceId: rideRequestId, referenceType: 'ride_request',
      description: 'Booking payment reserved ﷼ ${amount.toStringAsFixed(2)}',
    );
    await _firestore.addTransaction(tx);
    await _firestore.setWallet(WalletModel(
      id: wallet.id, userId: userId, userRole: wallet.userRole,
      balance: balanceAfter, totalEarned: wallet.totalEarned,
      totalSpent: wallet.totalSpent + amount,
      createdAt: wallet.createdAt,
    ));
    return tx;
  }

  Future<TransactionModel> topUp(String userId, double amount, {String? paymentMethod, String? paymentRef}) async {
    if (amount <= 0) throw const WalletException('Amount must be positive');
    final wallet = await getOrCreateWallet(userId, 'passenger');
    final pending = paymentMethod == 'bank_transfer';
    final pendingTx = TransactionModel(
      id: _uuid.v4(), walletId: wallet.id, userId: userId,
      type: TransactionType.credit, amount: amount,
      balanceBefore: wallet.balance, balanceAfter: pending ? wallet.balance : wallet.balance + amount,
      reason: TransactionReason.topUp, paymentMethod: paymentMethod,
      paymentReference: paymentRef,
      status: pending ? TransactionStatus.pending : TransactionStatus.completed,
      description: 'Wallet top-up of ﷼ ${amount.toStringAsFixed(2)}',
    );
    await _firestore.addTransaction(pendingTx);
    if (pending) {
      return pendingTx;
    }
    final balanceAfter = wallet.balance + amount;
    await _firestore.setWallet(WalletModel(
      id: wallet.id, userId: userId, userRole: wallet.userRole,
      balance: balanceAfter, totalEarned: wallet.totalEarned,
      totalSpent: wallet.totalSpent,
    ));
    return pendingTx;
  }

  Future<TransactionModel> deductForRide(String userId, double amount, String tripId) async {
    if (amount <= 0) throw const WalletException('Amount must be positive');
    final wallet = await getOrCreateWallet(userId, 'passenger');
    if (wallet.balance < amount) {
      throw const WalletException('Insufficient wallet balance');
    }
    final balanceAfter = wallet.balance - amount;
    final tx = TransactionModel(
      id: _uuid.v4(), walletId: wallet.id, userId: userId,
      type: TransactionType.debit, amount: amount,
      balanceBefore: wallet.balance, balanceAfter: balanceAfter,
      reason: TransactionReason.ridePayment,
      referenceId: tripId, referenceType: 'trip',
      description: 'Ride payment of ﷼ ${amount.toStringAsFixed(2)}',
    );
    await _firestore.addTransaction(tx);
    await _firestore.setWallet(WalletModel(
      id: wallet.id, userId: userId, userRole: wallet.userRole,
      balance: balanceAfter, totalEarned: wallet.totalEarned,
      totalSpent: wallet.totalSpent + amount,
    ));
    return tx;
  }

  Future<TransactionModel> creditEarnings(String userId, double amount, String tripId, String companyId) async {
    final wallet = await getOrCreateWallet(userId, 'driver');
    final commission = CommissionModel.calculate(
      id: _uuid.v4(), tripId: tripId, companyId: companyId,
      driverId: userId, fare: amount, rate: AppConstants.commissionRate,
    );
    final driverAmount = commission.driverEarnings;
    final balanceAfter = wallet.balance + driverAmount;

    await _firestore.setCommission(commission);

    final tx = TransactionModel(
      id: _uuid.v4(), walletId: wallet.id, userId: userId,
      type: TransactionType.credit, amount: driverAmount,
      balanceBefore: wallet.balance, balanceAfter: balanceAfter,
      reason: TransactionReason.ridePayment,
      referenceId: tripId, referenceType: 'trip',
      description: 'Ride earnings ﷼ ${driverAmount.toStringAsFixed(2)} (5% commission: ﷼ ${commission.commissionAmount.toStringAsFixed(2)})',
    );
    await _firestore.addTransaction(tx);
    await _firestore.setWallet(WalletModel(
      id: wallet.id, userId: userId, userRole: wallet.userRole,
      balance: balanceAfter,
      totalEarned: wallet.totalEarned + driverAmount,
      totalSpent: wallet.totalSpent,
    ));
    return tx;
  }
}
