import 'dart:math' show pow;

import 'package:flutter/material.dart' show Color;
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

enum RevenueStatus {
  /// Indicates that the associated trip is accepting passengers.
  revenue,

  /// Indicates that the associated trip is not accepting passengers.
  nonRevenue,
}

enum VehicleStopStatus {
  /// The vehicle is just about to arrive at the stop (on a stop display, the vehicle symbol typically flashes).
  incomingAt,

  /// The vehicle is standing at the stop.
  stoppedAt,

  /// The vehicle has departed the previous stop and is in transit.
  inTransitTo,
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
  notBoardable,
}

enum RouteType { lightRail, heavyRail, commuterRail, bus, ferry }

enum LocationType {
  /// A location where passengers board or disembark from a transit vehicle.
  stop,

  /// A physical structure or area that contains one or more stops.
  station,

  /// A location where passengers can enter or exit a station from the street. The stop entry must also specify a `parentStation` value referencing the stop ID of the parent station for the entrance.
  stationEntranceOrExit,

  /// A location within a station, not matching any other `locationType`, which can be used to link together pathways defined in pathways.txt.
  genericNode,
}

enum WheelchairBoarding { noInformation, accessible, inaccessible }

RevenueStatus _revenueStatusFromString(String value) {
  return switch (value) {
    'REVENUE' => RevenueStatus.revenue,
    'NON_REVENUE' => RevenueStatus.nonRevenue,
    _ => throw AssertionError('$value is not a valid revenue status.'),
  };
}

VehicleStopStatus _vehicleStatusFromString(String value) {
  return switch (value) {
    'INCOMING_AT' => VehicleStopStatus.incomingAt,
    'STOPPED_AT' => VehicleStopStatus.stoppedAt,
    'IN_TRANSIT_TO' => VehicleStopStatus.inTransitTo,
    _ => throw AssertionError('$value is not a valid vehicle status.'),
  };
}

OccupancyStatus _occupancyStatusFromString(String value) {
  return switch (value) {
    'EMPTY' => OccupancyStatus.empty,
    'MANY_SEATS_AVAILABLE' => OccupancyStatus.manySeatsAvailable,
    'FEW_SEATS_AVAILABLE' => OccupancyStatus.fewSeatsAvailable,
    'STANDING_ROOM_ONLY' => OccupancyStatus.standingRoomOnly,
    'CRUSHED_STANDING_ROOM_ONLY' => OccupancyStatus.crushedStandingRoomOnly,
    'FULL' => OccupancyStatus.full,
    'NOT_ACCEPTING_PASSENGERS' => OccupancyStatus.notAcceptingPassengers,
    'NO_DATA_AVAILABLE' => OccupancyStatus.noDataAvailable,
    'NOT_BOARDABLE' => OccupancyStatus.notBoardable,
    _ => throw AssertionError('$value is not a valid occupancy status.'),
  };
}

RouteType _routeTypeFromInt(int value) {
  return switch (value) {
    0 => RouteType.lightRail,
    1 => RouteType.heavyRail,
    2 => RouteType.commuterRail,
    3 => RouteType.bus,
    4 => RouteType.ferry,
    _ => throw AssertionError('$value is not a valid route type.'),
  };
}

LocationType _locationTypeFromInt(int value) {
  return switch (value) {
    0 => LocationType.stop,
    1 => LocationType.station,
    2 => LocationType.stationEntranceOrExit,
    3 => LocationType.genericNode,
    _ => throw AssertionError('$value is not a valid location type.'),
  };
}

WheelchairBoarding _wheelchairBoardingFromInt(int value) {
  return switch (value) {
    0 => WheelchairBoarding.noInformation,
    1 => WheelchairBoarding.accessible,
    2 => WheelchairBoarding.inaccessible,
    _ => throw AssertionError('$value is not a valid wheelchair boarding.'),
  };
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
            ? _occupancyStatusFromString(jsonMap['occupancyStatus'] as String)
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
            ? _revenueStatusFromString(jsonMap['revenueStatus'] as String)
            : null;
    final OccupancyStatus? occupancyStatus =
        jsonMap['occupancyStatus'] != null
            ? _occupancyStatusFromString(jsonMap['occupancyStatus'] as String)
            : null;
    final VehicleStopStatus? currentStatus =
        jsonMap['currentStatus'] != null
            ? _vehicleStatusFromString(jsonMap['currentStatus'] as String)
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
      type: _routeTypeFromInt(jsonMap['type'] as int),
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
  final List<String> routeIds;
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
    final List<String> routeIds =
        (jsonMap['routeIds'] as List).map((json) => json as String).toList();
    final WheelchairBoarding? wheelchairBoarding =
        jsonMap['wheelchairBoarding'] != null
            ? _wheelchairBoardingFromInt(jsonMap['type'] as int)
            : null;
    final RouteType? vehicleType =
        jsonMap['vehicleType'] != null
            ? _routeTypeFromInt(jsonMap['type'] as int)
            : null;
    final LocationType? locationType =
        jsonMap['locationType'] != null
            ? _locationTypeFromInt(jsonMap['type'] as int)
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

class ResourceFilter {
  const ResourceFilter({required this.types, this.routeIds, this.routeTypes});

  final Set<String> types;
  final Set<String>? routeIds;
  final Set<RouteType>? routeTypes;

  Object toJson() {
    final Map<String, Object> json = <String, Object>{};

    void addIfPresent(String fieldName, Object? value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent('types', types.toList());
    addIfPresent('routeIds', routeIds?.toList());
    addIfPresent('routeTypes', routeTypes?.toList());
    return json;
  }
}
