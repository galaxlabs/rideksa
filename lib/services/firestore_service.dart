import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../models/driver_model.dart';
import '../models/ride_request_model.dart';
import '../models/ride_offer_model.dart';
import '../models/trip_model.dart';
import '../models/wallet_model.dart';
import '../models/company_model.dart';
import '../models/chat_message_model.dart';
import '../models/contract_model.dart';
import '../models/group_invite_model.dart';
import '../models/route_model.dart';
import '../models/commission_model.dart';
import '../models/subscription_model.dart';
import '../models/trip_transfer_model.dart';
import '../models/vehicle_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Users ───
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection(AppConstants.firestoreUsers).doc(uid).get();
    return doc.exists ? UserModel.fromJson(doc.data()!) : null;
  }

  Future<void> setUser(UserModel user) =>
      _db.collection(AppConstants.firestoreUsers).doc(user.uid).set(user.toJson());

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _db.collection(AppConstants.firestoreUsers).doc(uid).update(data);

  Stream<UserModel?> streamUser(String uid) =>
      _db.collection(AppConstants.firestoreUsers).doc(uid).snapshots().map(
        (s) => s.exists ? UserModel.fromJson(s.data()!) : null,
      );

  // ─── Drivers ───
  Future<DriverModel?> getDriver(String id) async {
    final doc = await _db.collection(AppConstants.firestoreDrivers).doc(id).get();
    return doc.exists ? DriverModel.fromJson(doc.data()!) : null;
  }

  Future<void> setDriver(DriverModel driver) =>
      _db.collection(AppConstants.firestoreDrivers).doc(driver.id).set(driver.toJson());

  Stream<DriverModel?> streamDriver(String id) =>
      _db.collection(AppConstants.firestoreDrivers).doc(id).snapshots().map(
        (s) => s.exists ? DriverModel.fromJson(s.data()!) : null,
      );

  Stream<List<DriverModel>> streamAvailableDrivers(String companyId) =>
      _db.collection(AppConstants.firestoreDrivers)
          .where('company_id', isEqualTo: companyId)
          .where('is_available', isEqualTo: true)
          .snapshots()
          .map((s) => s.docs.map((d) => DriverModel.fromJson(d.data())).toList());

  Future<List<DriverModel>> getDriversByCompany(String companyId) async {
    final snap = await _db.collection(AppConstants.firestoreDrivers)
        .where('company_id', isEqualTo: companyId).get();
    return snap.docs.map((d) => DriverModel.fromJson(d.data())).toList();
  }

  // ─── Active Rides ───
  Future<void> setActiveRide(RideRequestModel ride) =>
      _db.collection(AppConstants.firestoreActiveRides).doc(ride.id).set(ride.toJson());

  Future<void> updateActiveRide(String id, Map<String, dynamic> data) =>
      _db.collection(AppConstants.firestoreActiveRides).doc(id).update(data);

  Stream<RideRequestModel?> streamActiveRide(String id) =>
      _db.collection(AppConstants.firestoreActiveRides).doc(id).snapshots().map(
        (s) => s.exists ? RideRequestModel.fromJson(s.data()!) : null,
      );

  Stream<List<RideRequestModel>> streamActiveRides({String? companyId}) {
    Query q = _db.collection(AppConstants.firestoreActiveRides)
        .where('status', whereIn: ['pending', 'offered']);
    if (companyId != null) q = q.where('company_id', isEqualTo: companyId);
    return q.snapshots().map(
      (s) => s.docs.map((d) => RideRequestModel.fromJson(d.data() as Map<String, dynamic>)).toList(),
    );
  }

  Future<void> deleteActiveRide(String id) =>
      _db.collection(AppConstants.firestoreActiveRides).doc(id).delete();

  Future<bool> hasOpenTaskForUser(String userId) async {
    final rides = await _db.collection(AppConstants.firestoreActiveRides)
        .where('passenger_id', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'offered', 'accepted'])
        .limit(1).get();
    if (rides.docs.isNotEmpty) return true;
    final trips = await _db.collection(AppConstants.firestoreActiveTrips)
        .where('passenger_id', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'checkedIn', 'boarded', 'inProgress'])
        .limit(1).get();
    return trips.docs.isNotEmpty;
  }

  Future<bool> hasOpenTaskForProvider(String providerId) async {
    final rides = await _db.collection(AppConstants.firestoreActiveRides)
        .where('assigned_driver_id', isEqualTo: providerId)
        .where('status', isEqualTo: 'accepted')
        .limit(1).get();
    if (rides.docs.isNotEmpty) return true;
    final trips = await _db.collection(AppConstants.firestoreActiveTrips)
        .where('driver_id', isEqualTo: providerId)
        .where('status', whereIn: ['pending', 'checkedIn', 'boarded', 'inProgress'])
        .limit(1).get();
    return trips.docs.isNotEmpty;
  }

  // ─── Active Offers ───
  Future<void> setOffer(RideOfferModel offer) =>
      _db.collection(AppConstants.firestoreActiveOffers).doc(offer.id).set(offer.toJson());

  Future<void> updateOffer(String id, Map<String, dynamic> data) =>
      _db.collection(AppConstants.firestoreActiveOffers).doc(id).update(data);

  Stream<List<RideOfferModel>> streamOffersForRide(String rideRequestId) =>
      _db.collection(AppConstants.firestoreActiveOffers)
          .where('ride_request_id', isEqualTo: rideRequestId)
          .snapshots()
          .map((s) => s.docs.map((d) => RideOfferModel.fromJson(d.data())).toList());

  Stream<List<RideOfferModel>> streamDriverOffers(String driverId) =>
      _db.collection(AppConstants.firestoreActiveOffers)
          .where('driver_id', isEqualTo: driverId)
          .snapshots()
          .map((s) => s.docs.map((d) => RideOfferModel.fromJson(d.data())).toList());

  // ─── Active Trips ───
  Future<void> setActiveTrip(TripModel trip) =>
      _db.collection(AppConstants.firestoreActiveTrips).doc(trip.id).set(trip.toJson());

  Future<void> updateActiveTrip(String id, Map<String, dynamic> data) =>
      _db.collection(AppConstants.firestoreActiveTrips).doc(id).update(data);

  Stream<TripModel?> streamActiveTrip(String id) =>
      _db.collection(AppConstants.firestoreActiveTrips).doc(id)      .snapshots().map(
        (s) => s.exists ? TripModel.fromJson(s.data() as Map<String, dynamic>) : null,
      );

  Future<void> deleteActiveTrip(String id) =>
      _db.collection(AppConstants.firestoreActiveTrips).doc(id).delete();

  // ─── Wallet & Transactions ───
  Future<WalletModel?> getWallet(String userId) async {
    final snap = await _db.collection(AppConstants.firestoreWallets)
        .where('user_id', isEqualTo: userId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return WalletModel.fromJson(snap.docs.first.data());
  }

  Future<void> setWallet(WalletModel wallet) =>
      _db.collection(AppConstants.firestoreWallets).doc(wallet.id).set(wallet.toJson());

  Future<void> addTransaction(TransactionModel tx) =>
      _db.collection(AppConstants.firestoreTransactions).doc(tx.id).set(tx.toJson());

  Future<void> updateTransactionStatus(String txId, TransactionStatus status) =>
      _db.collection(AppConstants.firestoreTransactions).doc(txId).update({'status': status.name});

  Future<List<TransactionModel>> getPendingTopUps() async {
    final snap = await _db.collection(AppConstants.firestoreTransactions)
        .where('reason', isEqualTo: 'topUp')
        .where('status', isEqualTo: 'pending')
        .limit(50)
        .get();
    return snap.docs.map((d) => TransactionModel.fromJson(d.data())).toList();
  }

  Future<void> completePendingTopUp(TransactionModel tx) async {
    final wallet = await getWallet(tx.userId);
    if (wallet == null) return;
    final balanceAfter = wallet.balance + tx.amount;
    await _db.collection(AppConstants.firestoreWallets).doc(wallet.id).update({
      'balance': balanceAfter,
      'total_spent': wallet.totalSpent,
    });
    final completed = TransactionModel(
      id: tx.id,
      walletId: tx.walletId,
      userId: tx.userId,
      type: tx.type,
      amount: tx.amount,
      balanceBefore: tx.balanceBefore,
      balanceAfter: balanceAfter,
      reason: tx.reason,
      status: TransactionStatus.completed,
      referenceId: tx.referenceId,
      referenceType: tx.referenceType,
      description: tx.description,
      paymentMethod: tx.paymentMethod,
      paymentReference: tx.paymentReference,
      createdAt: tx.createdAt,
    );
    await _db.collection(AppConstants.firestoreTransactions).doc(tx.id).set(completed.toJson());
  }

  Stream<List<TransactionModel>> streamTransactions(String userId) =>
      _db.collection(AppConstants.firestoreTransactions)
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => TransactionModel.fromJson(d.data())).toList());

  // ─── Commissions ───
  Future<void> setCommission(CommissionModel commission) =>
      _db.collection(AppConstants.firestoreCommissions).doc(commission.id).set(commission.toJson());

  Stream<List<CommissionModel>> streamCommissions(String companyId) =>
      _db.collection(AppConstants.firestoreCommissions)
          .where('company_id', isEqualTo: companyId)
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => CommissionModel.fromJson(d.data())).toList());

  // ─── Companies (cached) ───
  Future<CompanyModel?> getCompany(String id) async {
    final doc = await _db.collection(AppConstants.firestoreCompanies).doc(id).get();
    return doc.exists ? CompanyModel.fromJson(doc.data()!) : null;
  }

  Future<void> setCompany(CompanyModel company) =>
      _db.collection(AppConstants.firestoreCompanies).doc(company.id).set(company.toJson());

  Stream<List<CompanyModel>> streamCompanies() =>
      _db.collection(AppConstants.firestoreCompanies).snapshots().map(
        (s) => s.docs.map((d) => CompanyModel.fromJson(d.data())).toList(),
      );

  // ─── Vehicles ───
  Future<void> setVehicle(VehicleModel vehicle) =>
      _db.collection(AppConstants.firestoreVehicles).doc(vehicle.id).set(vehicle.toJson());

  Stream<List<VehicleModel>> streamVehicles(String companyId) =>
      _db.collection(AppConstants.firestoreVehicles)
          .where('company_id', isEqualTo: companyId)
          .snapshots()
          .map((s) => s.docs.map((d) => VehicleModel.fromJson(d.data())).toList());

  // ─── Travel Agent / Company Contracts ───
  Future<void> setContract(ContractModel contract) =>
      _db.collection(AppConstants.firestoreContracts).doc(contract.id).set(contract.toJson());

  Stream<List<ContractModel>> streamContracts(String ownerId) =>
      _db.collection(AppConstants.firestoreContracts)
          .where('owner_id', isEqualTo: ownerId)
          .snapshots()
          .map((s) => s.docs.map((d) => ContractModel.fromJson(d.data())).toList());

  // ─── Chat ───
  Future<void> sendChatMessage(ChatMessageModel message) =>
      _db.collection(AppConstants.firestoreChatMessages).doc(message.id).set(message.toJson());

  Stream<List<ChatMessageModel>> streamChatMessages(String rideRequestId) =>
      _db.collection(AppConstants.firestoreChatMessages)
          .where('ride_request_id', isEqualTo: rideRequestId)
          .orderBy('created_at')
          .snapshots()
          .map((s) => s.docs.map((d) => ChatMessageModel.fromJson(d.data())).toList());

  // ─── Group Invites & Members ───
  Future<void> setGroupInvite(GroupInviteModel invite) =>
      _db.collection(AppConstants.firestoreGroupInvites).doc(invite.id).set(invite.toJson());

  Future<GroupInviteModel?> getGroupInvite(String id) async {
    final doc = await _db.collection(AppConstants.firestoreGroupInvites).doc(id).get();
    return doc.exists ? GroupInviteModel.fromJson(doc.data()!) : null;
  }

  Future<void> setGroupMember(GroupMemberModel member) =>
      _db.collection(AppConstants.firestoreGroupMembers).doc(member.id).set(member.toJson());

  Stream<List<GroupMemberModel>> streamGroupMembers(String rideRequestId) =>
      _db.collection(AppConstants.firestoreGroupMembers)
          .where('ride_request_id', isEqualTo: rideRequestId)
          .snapshots()
          .map((s) => s.docs.map((d) => GroupMemberModel.fromJson(d.data())).toList());

  // ─── Routes (cached) ───
  Future<List<RouteModel>> getRoutes() async {
    final snap = await _db.collection(AppConstants.firestoreRoutes).get();
    return snap.docs.map((d) => RouteModel.fromJson(d.data())).toList();
  }

  Future<void> setRoutes(List<RouteModel> routes) async {
    final batch = _db.batch();
    for (final r in routes) {
      batch.set(_db.collection(AppConstants.firestoreRoutes).doc(r.id), r.toJson());
    }
    await batch.commit();
  }

  // ─── Subscriptions ───
  Future<SubscriptionModel?> getSubscription(String companyId) async {
    final snap = await _db.collection(AppConstants.firestoreSubscriptions)
        .where('company_id', isEqualTo: companyId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return SubscriptionModel.fromJson(snap.docs.first.data());
  }

  Future<void> setSubscription(SubscriptionModel sub) =>
      _db.collection(AppConstants.firestoreSubscriptions).doc(sub.id).set(sub.toJson());

  // ─── Trip Transfers / Resale ───
  Future<void> setTripTransfer(TripTransferModel transfer) =>
      _db.collection(AppConstants.firestoreTripTransfers).doc(transfer.id).set(transfer.toJson());

  Stream<List<TripTransferModel>> streamOpenTripTransfers() =>
      _db.collection(AppConstants.firestoreTripTransfers)
          .where('status', isEqualTo: 'open')
          .snapshots()
          .map((s) => s.docs.map((d) => TripTransferModel.fromJson(d.data())).toList());
}
