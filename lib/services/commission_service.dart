import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../models/commission_model.dart';
import '../models/trip_model.dart';
import 'firestore_service.dart';

class CommissionService {
  final FirestoreService _firestore;
  final Uuid _uuid = const Uuid();

  CommissionService(this._firestore);

  CommissionModel calculateCommission(TripModel trip) {
    return CommissionModel.calculate(
      id: _uuid.v4(),
      tripId: trip.id,
      companyId: trip.companyId ?? '',
      driverId: trip.driverId,
      fare: trip.fare,
      rate: AppConstants.commissionRate,
    );
  }

  Future<void> recordCommission(TripModel trip) async {
    final commission = calculateCommission(trip);
    await _firestore.setCommission(commission);

    await _firestore.updateActiveTrip(trip.id, {
      'commission_amount': commission.commissionAmount,
      'driver_earnings': commission.driverEarnings,
    });
  }

  double calculateCompanyRevenue(List<CommissionModel> commissions) {
    return commissions.fold(0.0, (sum, c) => sum + c.commissionAmount);
  }

  double calculateDriverTotalEarnings(List<CommissionModel> commissions) {
    return commissions.fold(0.0, (sum, c) => sum + c.driverEarnings);
  }
}
