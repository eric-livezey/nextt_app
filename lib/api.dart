import 'dart:math' show pow;

import 'package:flutter/material.dart' show Color;
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

enum RevenueStatus {
  /// Indicates that the associated trip is accepting passengers.
  revenue,

  /// Indicates that the associated trip is not accepting passengers.
  nonRevenue;

  factory RevenueStatus.fromJson(Object json) {
    String value = json as String;
    return switch (value) {
      'REVENUE' => revenue,
      'NON_REVENUE' => nonRevenue,
      _ => throw AssertionError('$value is not a valid revenue status.'),
    };
  }
}

enum VehicleStopStatus {
  /// The vehicle is just about to arrive at the stop (on a stop display, the vehicle symbol typically flashes).
  incomingAt,

  /// The vehicle is standing at the stop.
  stoppedAt,

  /// The vehicle has departed the previous stop and is in transit.
  inTransitTo;

  factory VehicleStopStatus.fromJson(Object json) {
    String value = json as String;
    return switch (value) {
      'INCOMING_AT' => incomingAt,
      'STOPPED_AT' => stoppedAt,
      'IN_TRANSIT_TO' => inTransitTo,
      _ => throw AssertionError('$value is not a valid vehicle stop status.'),
    };
  }
}

/// The state of passenger occupancy for the vehicle or carriage.
enum OccupancyStatus {
  /// The vehicle is considered empty by most measures, and has few or no passengers onboard, but is still accepting passengers.
  empty,

  /// The vehicle or carriage has a large number of seats available. The amount of free seats out of the total seats available to be considered large enough to fall into this category is determined at the discretion of the producer.
  manySeatsAvailable,

  /// The vehicle or carriage has a small number of seats available. The amount of free seats out of the total seats available to be considered small enough to fall into this category is determined at the discretion of the producer.
  fewSeatsAvailable,

  /// The vehicle or carriage can currently accommodate only standing passengers.
  standingRoomOnly,

  /// The vehicle or carriage can currently accommodate only standing passengers and has limited space for them.
  crushedStandingRoomOnly,

  /// The vehicle is considered full by most measures, but may still be allowing passengers to board.
  full,

  /// The vehicle or carriage is not accepting passengers. The vehicle or carriage usually accepts passengers for boarding.
  notAcceptingPassengers,

  /// The vehicle or carriage doesn't have any occupancy data available at that time.
  noDataAvailable,

  /// The vehicle or carriage is not boardable and never accepts passengers. Useful for special vehicles or carriages (engine, maintenance carriage, etc…).
  notBoardable;

  factory OccupancyStatus.fromJson(Object json) {
    String value = json as String;
    return switch (value) {
      'EMPTY' => empty,
      'MANY_SEATS_AVAILABLE' => manySeatsAvailable,
      'FEW_SEATS_AVAILABLE' => fewSeatsAvailable,
      'STANDING_ROOM_ONLY' => standingRoomOnly,
      'CRUSHED_STANDING_ROOM_ONLY' => crushedStandingRoomOnly,
      'FULL' => full,
      'NOT_ACCEPTING_PASSENGERS' => notAcceptingPassengers,
      'NO_DATA_AVAILABLE' => noDataAvailable,
      'NOT_BOARDABLE' => notBoardable,
      _ => throw AssertionError('$value is not a valid occupancy status.'),
    };
  }
}

enum RouteType {
  lightRail,
  heavyRail,
  commuterRail,
  bus,
  ferry;

  factory RouteType.fromJson(Object json) {
    int value = json as int;
    return switch (value) {
      0 => lightRail,
      1 => heavyRail,
      2 => commuterRail,
      3 => bus,
      4 => ferry,
      _ => throw AssertionError('$value is not a valid route type.'),
    };
  }
}

enum LocationType {
  /// A location where passengers board or disembark from a transit vehicle.
  stop,

  /// A physical structure or area that contains one or more stops.
  station,

  /// A location where passengers can enter or exit a station from the street. The stop entry must also specify a `parentStation` value referencing the stop ID of the parent station for the entrance.
  stationEntranceOrExit,

  /// A location within a station, not matching any other `locationType`, which can be used to link together pathways defined in pathways.txt.
  genericNode;

  factory LocationType.fromJson(Object json) {
    int value = json as int;
    return switch (value) {
      0 => stop,
      1 => station,
      2 => stationEntranceOrExit,
      3 => genericNode,
      _ => throw AssertionError('$value is not a valid location type.'),
    };
  }
}

enum WheelchairBoarding {
  noInformation,
  accessible,
  inaccessible;

  factory WheelchairBoarding.fromJson(Object json) {
    int value = json as int;
    return switch (value) {
      0 => noInformation,
      1 => accessible,
      2 => inaccessible,
      _ => throw AssertionError('$value is not a valid wheelchair boarding.'),
    };
  }
}

/// Parses a color from a 6 digit hex string.
Color _parseColor(String source) {
  int value = int.parse(source, radix: 16);
  // force alpha to 255
  return Color(0xFF000000 | value);
}

/// Decodes a polyline according to google's polyline encoding format.
List<LatLng> _decodePolyline(String source, {int? precision}) {
  int index = 0;
  double latitude = 0;
  double longitude = 0;
  final List<LatLng> coordinates = [];
  late int shift;
  late int result;
  late int? byte;
  late double latitudeChange;
  late double longitudeChange;
  final double factor = pow(10, precision ?? 5).toDouble();

  while (index < source.length) {
    byte = null;
    shift = 1;
    result = 0;

    do {
      byte = source.codeUnitAt(index++) - 63;
      result += (byte & 0x1f) * shift;
      shift *= 32;
    } while (byte >= 0x20);

    latitudeChange = (result & 1) != 0 ? ((-result - 1) / 2) : (result / 2);

    shift = 1;
    result = 0;

    do {
      byte = source.codeUnitAt(index++) - 63;
      result += (byte & 0x1f) * shift;
      shift *= 32;
    } while (byte >= 0x20);

    longitudeChange = (result & 1) != 0 ? ((-result - 1) / 2) : (result / 2);

    latitude += latitudeChange;
    longitude += longitudeChange;

    coordinates.add(LatLng(latitude / factor, longitude / factor));
  }

  return coordinates;
}

class CarriageDetails {
  const CarriageDetails({
    this.occupancyStatus,
    this.occupancyPercentage,
    this.label,
  });

  final OccupancyStatus? occupancyStatus;
  final double? occupancyPercentage;
  final String? label;

  /// Initialize a Carriage from an object.
  factory CarriageDetails.fromJson(Object json) {
    final Map<String, dynamic> jsonMap = json as Map<String, dynamic>;
    final OccupancyStatus? occupancyStatus =
        jsonMap['occupancyStatus'] != null
            ? OccupancyStatus.fromJson(jsonMap['occupancyStatus'])
            : null;
    return CarriageDetails(
      occupancyStatus: occupancyStatus,
      occupancyPercentage: (jsonMap['occupancyPercentage'] as num?)?.toDouble(),
      label: jsonMap['label'] as String?,
    );
  }
}

/// Current state of a vehicle on a trip.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.routeId,
    required this.updatedAt,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.revenueStatus,
    this.occupancyStatus,
    this.label,
    this.directionId,
    this.currentStopSequence,
    this.currentStatus,
    this.carriages,
    this.bearing,
  });

  final String id;
  final String routeId;
  final DateTime updatedAt;
  final double latitude;
  final double longitude;
  final double? speed;
  final RevenueStatus? revenueStatus;
  final OccupancyStatus? occupancyStatus;
  final String? label;
  final int? directionId;
  final int? currentStopSequence;
  final VehicleStopStatus? currentStatus;
  final List<CarriageDetails>? carriages;
  final double? bearing;
  LatLng get position => LatLng(latitude, longitude);

  /// Initialize a Vehicle from an object.
  factory Vehicle.fromJson(Object json) {
    final Map<String, dynamic> jsonMap = json as Map<String, dynamic>;
    final RevenueStatus? revenueStatus =
        jsonMap['revenueStatus'] != null
            ? RevenueStatus.fromJson(jsonMap['revenueStatus'])
            : null;
    final OccupancyStatus? occupancyStatus =
        jsonMap['occupancyStatus'] != null
            ? OccupancyStatus.fromJson(jsonMap['occupancyStatus'])
            : null;
    final VehicleStopStatus? currentStatus =
        jsonMap['currentStatus'] != null
            ? VehicleStopStatus.fromJson(jsonMap['currentStatus'])
            : null;
    final List<CarriageDetails>? carriages =
        (jsonMap['carriages'] as List?)
            ?.map((json) => CarriageDetails.fromJson(json as Object))
            .toList();
    return Vehicle(
      id: jsonMap['id'] as String,
      routeId: jsonMap['routeId'] as String,
      updatedAt: DateTime.parse((jsonMap['updatedAt'] as String)),
      latitude: (jsonMap['latitude'] as num).toDouble(),
      longitude: (jsonMap['longitude'] as num).toDouble(),
      speed: (jsonMap['speed'] as num?)?.toDouble(),
      revenueStatus: revenueStatus,
      occupancyStatus: occupancyStatus,
      label: jsonMap['label'] as String?,
      directionId: jsonMap['directionId'] as int?,
      currentStopSequence: jsonMap['currentStopSequence'] as int?,
      currentStatus: currentStatus,
      carriages: carriages,
      bearing: (jsonMap['bearing'] as num?)?.toDouble(),
    );
  }
}

class Shape {
  const Shape({required this.id, required this.polyline});

  final String id;
  final List<LatLng> polyline;

  factory Shape.fromJson(Object json) {
    final Map<String, dynamic> jsonMap = json as Map<String, dynamic>;
    return Shape(
      id: jsonMap['id'] as String,
      polyline: _decodePolyline(jsonMap['polyline'] as String),
    );
  }
}

class Route {
  const Route({
    required this.id,
    required this.shapes,
    required this.type,
    this.textColor,
    this.sortOrder,
    this.shortName,
    this.longName,
    this.fareClass,
    this.directionNames,
    this.directionDestinations,
    this.description,
    this.color,
  });

  final String id;
  final List<Shape> shapes;
  final RouteType type;
  final Color? textColor;
  final int? sortOrder;
  final String? shortName;
  final String? longName;
  final String? fareClass;
  final List<String>? directionNames;
  final List<String>? directionDestinations;
  final String? description;
  final Color? color;

  factory Route.fromJson(Object json) {
    final Map<String, dynamic> jsonMap = json as Map<String, dynamic>;
    final List<Shape> shapes =
        (jsonMap['shapes'] as List)
            .map((json) => Shape.fromJson(json as Object))
            .toList();
    final Color? textColor =
        jsonMap['textColor'] != null
            ? _parseColor(jsonMap['textColor'] as String)
            : null;
    final List<String>? directionNames =
        (jsonMap['directionNames'] as List?)
            ?.map((json) => json as String)
            .toList();
    final List<String>? directionDestinations =
        (jsonMap['directionDestinations'] as List?)
            ?.map((json) => json as String)
            .toList();
    final Color? color =
        jsonMap['color'] != null
            ? _parseColor(jsonMap['color'] as String)
            : null;
    return Route(
      id: jsonMap['id'] as String,
      shapes: shapes,
      type: RouteType.fromJson(jsonMap['type']),
      textColor: textColor,
      sortOrder: jsonMap['sortOrder'] as int?,
      shortName: jsonMap['shortName'] as String?,
      longName: jsonMap['longName'] as String?,
      fareClass: jsonMap['fareClass'] as String?,
      directionNames: directionNames,
      directionDestinations: directionDestinations,
      description: jsonMap['description'] as String?,
      color: color,
    );
  }
}

class Stop {
  const Stop({
    required this.id,
    required this.routeIds,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.wheelchairBoarding,
    this.vehicleType,
    this.platformName,
    this.platformCode,
    this.onStreet,
    this.municipality,
    this.locationType,
    this.description,
    this.atStreet,
    this.address,
  });

  final String id;
  final Set<String> routeIds;
  final String name;
  final double latitude;
  final double longitude;
  final WheelchairBoarding? wheelchairBoarding;
  final RouteType? vehicleType;
  final String? platformName;
  final String? platformCode;
  final String? onStreet;
  final String? municipality;
  final LocationType? locationType;
  final String? description;
  final String? atStreet;
  final String? address;
  LatLng get position => LatLng(latitude, longitude);

  factory Stop.fromJson(Object json) {
    final Map<String, dynamic> jsonMap = json as Map<String, dynamic>;
    final Set<String> routeIds =
        (jsonMap['routeIds'] as List).map((json) => json as String).toSet();
    final WheelchairBoarding? wheelchairBoarding =
        jsonMap['wheelchairBoarding'] != null
            ? WheelchairBoarding.fromJson(jsonMap['wheelchairBoarding'])
            : null;
    final RouteType? vehicleType =
        jsonMap['vehicleType'] != null
            ? RouteType.fromJson(jsonMap['vehicleType'])
            : null;
    final LocationType? locationType =
        jsonMap['locationType'] != null
            ? LocationType.fromJson(jsonMap['locationType'])
            : null;
    return Stop(
      id: jsonMap['id'] as String,
      routeIds: routeIds,
      name: jsonMap['name'] as String,
      latitude: (jsonMap['latitude'] as num).toDouble(),
      longitude: (jsonMap['longitude'] as num).toDouble(),
      wheelchairBoarding: wheelchairBoarding,
      vehicleType: vehicleType,
      platformName: jsonMap['platformName'] as String?,
      platformCode: jsonMap['platformCode'] as String?,
      onStreet: jsonMap['onStreet'] as String?,
      municipality: jsonMap['municipality'] as String?,
      locationType: locationType,
      description: jsonMap['description'] as String?,
      atStreet: jsonMap['atStreet'] as String?,
      address: jsonMap['address'] as String?,
    );
  }
}
