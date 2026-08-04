import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme.dart';

class SimpleMapWidget extends StatefulWidget {
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final double? currentLat;
  final double? currentLng;
  final double height;

  const SimpleMapWidget({
    super.key,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.currentLat,
    this.currentLng,
    this.height = 200,
  });

  @override
  State<SimpleMapWidget> createState() => _SimpleMapWidgetState();
}

class _SimpleMapWidgetState extends State<SimpleMapWidget> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  @override
  Widget build(BuildContext context) {
    final markers = _markers();
    if (markers.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 48,
                color: AppColors.textSecondary.withAlpha(80),
              ),
              const SizedBox(height: 8),
              Text(
                'Map Preview',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final initial = markers.first.position;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initial,
            zoom: markers.length == 1 ? 14 : 10,
          ),
          markers: markers,
          polylines: _polylines(),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (controller) async {
            if (!_controller.isCompleted) _controller.complete(controller);
            if (markers.length > 1) {
              await Future.delayed(const Duration(milliseconds: 250));
              await controller.animateCamera(
                CameraUpdate.newLatLngBounds(_bounds(markers), 48),
              );
            }
          },
        ),
      ),
    );
  }

  Set<Marker> _markers() {
    final markers = <Marker>{};
    if (_has(widget.pickupLat, widget.pickupLng)) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(widget.pickupLat!, widget.pickupLng!),
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }
    if (_has(widget.dropoffLat, widget.dropoffLng)) {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(widget.dropoffLat!, widget.dropoffLng!),
          infoWindow: const InfoWindow(title: 'Dropoff'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    if (_has(widget.currentLat, widget.currentLng)) {
      markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: LatLng(widget.currentLat!, widget.currentLng!),
          infoWindow: const InfoWindow(title: 'Current Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _polylines() {
    if (!_has(widget.pickupLat, widget.pickupLng) ||
        !_has(widget.dropoffLat, widget.dropoffLng)) {
      return {};
    }
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        width: 4,
        color: AppColors.primary,
        points: [
          LatLng(widget.pickupLat!, widget.pickupLng!),
          LatLng(widget.dropoffLat!, widget.dropoffLng!),
        ],
      ),
    };
  }

  LatLngBounds _bounds(Set<Marker> markers) {
    final lats = markers.map((m) => m.position.latitude);
    final lngs = markers.map((m) => m.position.longitude);
    final south = lats.reduce(math.min);
    final north = lats.reduce(math.max);
    final west = lngs.reduce(math.min);
    final east = lngs.reduce(math.max);
    return LatLngBounds(
      southwest: LatLng(
        south == north ? south - 0.01 : south,
        west == east ? west - 0.01 : west,
      ),
      northeast: LatLng(
        south == north ? north + 0.01 : north,
        west == east ? east + 0.01 : east,
      ),
    );
  }

  bool _has(double? lat, double? lng) => lat != null && lng != null;
}
