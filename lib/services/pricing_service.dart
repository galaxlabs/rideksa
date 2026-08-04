import '../core/constants.dart';

class PricingService {
  static const Map<String, double> _vehicleBase = {
    'Sedan': 35,
    'SUV': 55,
    'Van': 90,
    'Coaster': 180,
    'Bus': 300,
    'Luxury': 120,
  };

  double estimate({
    required String vehicleType,
    required int passengers,
    double distanceKm = 25,
    double routeMultiplier = 1,
    double demandSupplyMultiplier = 1,
  }) {
    final base = _vehicleBase[vehicleType] ?? 50;
    final passengerFactor = passengers <= 4 ? 1 : 1 + ((passengers - 4) * 0.04);
    final raw = (base + distanceKm * 2.2) * passengerFactor * routeMultiplier * demandSupplyMultiplier;
    return raw.clamp(AppConstants.minRidePrice, AppConstants.maxRidePrice).toDouble();
  }

  double clampOffer(double value) => value.clamp(AppConstants.minRidePrice, AppConstants.maxRidePrice).toDouble();
}
