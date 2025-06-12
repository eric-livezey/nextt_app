import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Shape {
  final String routeId;
  final String id;
  final List<LatLng> points;

  factory Shape.fromJson(data, String routeId) {
    final String id = data['id'];
    final List<LatLng> points =
        data['polyline'] != null ? decodePolyline(data['polyline']) : [];
    return Shape._internal(routeId: routeId, id: id, points: points);
  }

  const Shape._internal({
    required this.routeId,
    required this.id,
    this.points = const [],
  });
}

enum RouteType { lightRail, heavyRail, commuterRail, bus, ferry }

class Route {
  final String id;
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
  final List<Shape> shapes;

  factory Route.fromJson(data) {
    final String id = data['id'];
    final RouteType type = switch (data['type']) {
      0 => RouteType.lightRail,
      1 => RouteType.heavyRail,
      2 => RouteType.commuterRail,
      3 => RouteType.bus,
      4 => RouteType.ferry,
      _ => throw TypeError,
    };
    final Color? textColor =
        data['textColor'] != null ? tryParseColor(data['textColor']) : null;
    final int? sortOrder = data['sortOrder'];
    final String? shortName = data['shortName'];
    final String? longName = data['longName'];
    final String? fareClass = data['fareClass'];
    final List<String>? directionNames = data['directionNames'];
    final List<String>? directionDestinations = data['directionDestinations'];
    final String? description = data['description'];
    final Color? color =
        data['color'] != null ? tryParseColor(data['color']) : null;
    final List shapeData = data['shapes'] ?? [];
    final List<Shape> shapes =
        shapeData.map((data) => Shape.fromJson(data, id)).toList();
    return Route._internal(
      id: id,
      type: type,
      textColor: textColor,
      sortOrder: sortOrder,
      shortName: shortName,
      longName: longName,
      fareClass: fareClass,
      directionNames: directionNames,
      directionDestinations: directionDestinations,
      description: description,
      color: color,
      shapes: shapes,
    );
  }

  const Route._internal({
    required this.id,
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
    this.shapes = const [],
  });
}

class Vehicle {
  final String routeId;
  final String id;
  final DateTime? updatedAt;
  final double? speed;
  final String? revenueStatus;
  final String? occupancyStatus;
  final double longitude;
  final double latitude;
  final String? label;
  final int? directionId;
  final int? currentStopSequence;
  final String? currentStatus;
  final List carriages;
  final int bearing;

  LatLng get position => LatLng(latitude, longitude);

  factory Vehicle.fromJson(data) {
    final String routeId = data['routeId'];
    final String id = data['id'];
    final DateTime? updatedAt = DateTime.tryParse(data['updatedAt'] ?? '');
    final double? speed = data['speed']?.toDouble();
    final String? revenueStatus = data['revenueStatus'];
    final String? occupancyStatus = data['occupancyStatus'];
    final double longitude = data['longitude']?.toDouble();
    final double latitude = data['latitude']?.toDouble();
    final String? label = data['label'];
    final int? directionId = data['directionId'];
    final int? currentStopSequence = data['currentStopSequence'];
    final String? currentStatus = data['currentStatus'];
    final List carriages = data['carriages'] ?? const [];
    final int bearing = data['bearing'];
    return Vehicle._internal(
      routeId: routeId,
      id: id,
      updatedAt: updatedAt,
      speed: speed,
      revenueStatus: revenueStatus,
      occupancyStatus: occupancyStatus,
      longitude: longitude,
      latitude: latitude,
      label: label,
      directionId: directionId,
      currentStopSequence: currentStopSequence,
      currentStatus: currentStatus,
      carriages: carriages,
      bearing: bearing,
    );
  }

  const Vehicle._internal({
    required this.routeId,
    required this.id,
    this.updatedAt,
    this.speed,
    this.revenueStatus,
    this.occupancyStatus,
    required this.longitude,
    required this.latitude,
    this.label,
    this.directionId,
    this.currentStopSequence,
    this.currentStatus,
    this.carriages = const [],
    required this.bearing,
  });
}

/// Decodes a polyline according to google's polyline encoding format.
List<LatLng> decodePolyline(String source, {int? precision}) {
  int index = 0;
  double latitude = 0;
  double longitude = 0;
  List<LatLng> coordinates = [];
  int shift = 0;
  int result = 0;
  late int? byte;
  late double latitudeChange;
  late double longitudeChange;
  num factor = pow(10, precision ?? 5);

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

/// Parses a color from a 6 digit hex string
Color? tryParseColor(String source) {
  int? value = int.tryParse(source, radix: 16);
  if (value != null) {
    // force alpha to 255
    return Color(0xFF000000 | value);
  }
  return null;
}
