// lib/core/utils/geohash_util.dart
// Geohash encoding for Firestore proximity queries +
// Haversine formula for accurate distance filtering.
//
// WHY TWO STEPS?
//   Firestore can't do radius queries natively. We use geohash
//   prefix search as a fast pre-filter (~4.9km box), then
//   Haversine to accurately discard results outside the true radius.

import 'dart:math';

class GeohashUtil {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encode lat/lng to geohash string of given precision.
  /// Precision 5 ≈ 4.9km × 4.9km box — good for nearby SOS queries.
  /// Precision 7 ≈ 153m × 153m — good for precise location storage.
  static String encode(double lat, double lng, {int precision = 7}) {
    double minLat = -90, maxLat = 90;
    double minLng = -180, maxLng = 180;

    final buffer = StringBuffer();
    int bits = 0, bitsTotal = 0, hashValue = 0;
    bool isEven = true;

    while (buffer.length < precision) {
      double mid;
      if (isEven) {
        mid = (minLng + maxLng) / 2;
        if (lng >= mid) {
          hashValue = (hashValue << 1) + 1;
          minLng = mid;
        } else {
          hashValue = hashValue << 1;
          maxLng = mid;
        }
      } else {
        mid = (minLat + maxLat) / 2;
        if (lat >= mid) {
          hashValue = (hashValue << 1) + 1;
          minLat = mid;
        } else {
          hashValue = hashValue << 1;
          maxLat = mid;
        }
      }
      isEven = !isEven;

      if (++bits == 5) {
        buffer.write(_base32[hashValue]);
        bits = 0;
        bitsTotal += 5;
        hashValue = 0;
      }
    }
    return buffer.toString();
  }

  /// Haversine distance in kilometres between two lat/lng pairs.
  static double distanceKm(
      double lat1, double lng1,
      double lat2, double lng2,
      ) {
    const r = 6371.0; // Earth radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  /// Distance in metres
  static double distanceMetres(
      double lat1, double lng1,
      double lat2, double lng2,
      ) =>
      distanceKm(lat1, lng1, lat2, lng2) * 1000;

  static double _toRad(double deg) => deg * pi / 180;
}