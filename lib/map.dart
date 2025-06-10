import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nextt_app/mbta.dart' as mbta;
import 'package:vector_math/vector_math.dart' as vector_math;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Returns the projection of `q` onto the line between at `a` and `b`.
///
/// https://en.wikipedia.org/wiki/Vector_projection
vector_math.Vector2 project(
  vector_math.Vector2 q,
  vector_math.Vector2 a,
  vector_math.Vector2 b,
) {
  final ab = b - a;
  final double t = ((q - a).dot(ab) / ab.dot(ab)).clamp(0, 1);
  return a + ab * t;
}

/// Converts a latitute longitude pair to a point on the mercator projection.
///
/// https://en.wikipedia.org/wiki/Mercator_projection
vector_math.Vector2 latLngToVector(LatLng latLng) {
  // earth's radius
  const double r = 6378137.0;
  final longitude = latLng.longitude * math.pi / 180.0;
  final latitude = latLng.latitude * math.pi / 180.0;
  final x = r * longitude;
  final y = r * math.log(math.tan(math.pi / 4 + latitude / 2));
  return vector_math.Vector2(x, y);
}

/// Converts a point on the mercator projection to a latitute longitute pair
///
/// https://en.wikipedia.org/wiki/Mercator_projection
LatLng vectorToLatLng(vector_math.Vector2 vector) {
  // earth's radius
  const double r = 6378137.0;
  final longitude = vector.x / r;
  final latitude = 2 * math.atan(math.exp(vector.y / r)) - math.pi / 2;
  return LatLng(latitude * 180 / math.pi, longitude * 180 / math.pi);
}

class LatLngDistance {
  const LatLngDistance(this.latLng, this.distance);
  final LatLng latLng;
  final double distance;
}

/// Snaps a latitude longitute point the point on a polyline
LatLngDistance? snapToPolyline(LatLng point, Iterable<LatLng> points) {
  if (points.isEmpty) {
    return null;
  }
  final vector = latLngToVector(point);
  double min = double.infinity;
  late vector_math.Vector2 closest;
  LatLng previous = points.first;

  for (point in points.skip(1)) {
    final a = latLngToVector(previous);
    final b = latLngToVector(point);
    final projection = project(vector, a, b);
    final dist = (projection - vector).length;

    if (dist < min) {
      min = dist;
      closest = projection;
    }
    previous = point;
  }

  return LatLngDistance(vectorToLatLng(closest), min);
}

class _MapShape {
  _MapShape(this.shape, this.polyline);

  final mbta.Shape shape;
  Polyline polyline;
}

class _MapRoute {
  _MapRoute(this.route, this.shapes);

  final mbta.Route route;
  final List<_MapShape> shapes;
  bool visible = true;
}

class _MapVehicle {
  _MapVehicle(this.vehicle, this.marker);

  final mbta.Vehicle vehicle;
  Marker marker;
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<StatefulWidget> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  _MapPageState();

  WebSocketChannel? _channel;
  GoogleMapController? controller;
  final Map<String, _MapShape> _shapes = {};
  final Map<String, _MapRoute> _routes = {};
  final Map<String, _MapVehicle> _vehicles = {};
  _MapRoute? _selectedRoute;

  @override
  void initState() {
    super.initState();
    // connect to the websocket
    // TODO: replace with real URI
    _channel = WebSocketChannel.connect(Uri.parse('ws://10.220.48.189:3000'));
    _channel!.stream.listen(_onWebSocketData);
  }

  @override
  void dispose() {
    super.dispose();
    // close the websocket
    _channel?.sink.close();
  }

  void _onMapCreated(GoogleMapController controller) {
    this.controller = controller;
  }

  void _onWebSocketData(event) {
    final payload = jsonDecode(event);
    final String type = payload['type'];
    final data = payload['data'];
    switch (type) {
      case 'ROUTE_RESET':
        _onRouteReset(data);
        break;
      case 'ROUTE_ADD':
        _onRouteAdd(data);
        break;
      case 'ROUTE_UPDATE':
        _onRouteUpdate(data);
        break;
      case 'ROUTE_REMOVE':
        _onRouteRemove(data);
        break;
      case 'VEHICLE_RESET':
        _onVehicleReset(data);
        break;
      case 'VEHICLE_ADD':
        _onVehicleAdd(data);
        break;
      case 'VEHICLE_UPDATE':
        _onVehicleUpdate(data);
        break;
      case 'VEHICLE_REMOVE':
        _onVehicleRemove(data);
        break;
    }
  }

  void _onRouteReset(List data) {
    for (final routeData in data) {
      final mbta.Route route = mbta.Route.fromJson(routeData);
      if (_routes.containsKey(route.id)) {
        _removeRoute(route.id);
      }
      _addRoute(route);
    }
  }

  void _onRouteAdd(data) {
    final mbta.Route route = mbta.Route.fromJson(data);
    _addRoute(route);
  }

  void _onRouteUpdate(data) {
    final mbta.Route route = mbta.Route.fromJson(data);
    if (_routes.containsKey(route.id)) {
      _removeRoute(route.id);
    }
    _addRoute(route);
  }

  void _onRouteRemove(data) {
    _removeRoute(data['id']);
  }

  void _onVehicleReset(List data) {
    for (final vehicleData in data) {
      final mbta.Vehicle vehicle = mbta.Vehicle.fromJson(vehicleData);
      if (_vehicles.containsKey(vehicle.id)) {
        _removeVehicle(vehicle.id);
      }
      _addVehicle(vehicle);
    }
  }

  void _onVehicleAdd(data) {
    final mbta.Vehicle vehicle = mbta.Vehicle.fromJson(data);
    _addVehicle(vehicle);
  }

  void _onVehicleUpdate(data) {
    final mbta.Vehicle vehicle = mbta.Vehicle.fromJson(data);
    if (_vehicles.containsKey(vehicle.id)) {
      _removeVehicle(vehicle.id);
    }
    _addVehicle(vehicle);
  }

  void _onVehicleRemove(data) {
    _removeVehicle(data['id']);
  }

  /// snaps a point to a route
  LatLng _snapPoint(LatLng point, _MapRoute route) {
    return route.shapes.fold(null as LatLngDistance?, (min, shape) {
          final dist = snapToPolyline(point, shape.polyline.points);
          return min == null || dist != null && dist.distance < min.distance
              ? dist
              : min;
        })?.latLng ??
        point;
  }

  /// snaps all markers associated with the route
  void _snapMarkers(String routeId) {
    setState(() {
      for (final mapVehicle in _vehicles.values) {
        final vehicle = mapVehicle.vehicle;
        if (mapVehicle.vehicle.routeId == routeId) {
          mapVehicle.marker = mapVehicle.marker.copyWith(
            positionParam: _snapPoint(
              LatLng(vehicle.latitude, vehicle.longitude),
              _routes[vehicle.routeId]!,
            ),
          );
        }
      }
    });
  }

  Future<void> _addVehicle(mbta.Vehicle vehicle) async {
    final markerId = MarkerId(vehicle.id);
    final marker = Marker(
      markerId: markerId,
      position: _snapPoint(
        LatLng(vehicle.latitude, vehicle.longitude),
        _routes[vehicle.routeId]!,
      ),
      infoWindow: InfoWindow(title: vehicle.label),
      onTap: () => _onVehicleTapped(markerId),
      icon: await BitmapDescriptor.asset(
        ImageConfiguration(size: Size(20, 20)),
        'assets/navigation.png',
      ),
      anchor: Offset(0.5, 0.5),
      rotation: vehicle.bearing.toDouble(),
    );

    final _MapVehicle mapVehicle = _MapVehicle(vehicle, marker);

    setState(() {
      _vehicles[vehicle.id] = mapVehicle;
    });
  }

  _removeVehicle(String vehicleId) {
    if (_vehicles.containsKey(vehicleId)) {
      setState(() {
        _vehicles.remove(vehicleId);
      });
    }
  }

  _onVehicleTapped(MarkerId markerId) {
    // TODO
  }

  void _addRoute(mbta.Route route) {
    final List<_MapShape> mapShapes = [];
    for (mbta.Shape shape in route.shapes) {
      final PolylineId polylineId = PolylineId(shape.id);
      mapShapes.add(
        _MapShape(
          shape,
          Polyline(
            polylineId: polylineId,
            consumeTapEvents: true,
            color: route.color ?? Colors.black,
            points: shape.points,
            width: 5,
            onTap: () {
              _onRouteTapped(polylineId);
            },
          ),
        ),
      );
    }
    setState(() {
      _routes[route.id] = _MapRoute(route, mapShapes);
      for (_MapShape shape in mapShapes) {
        _shapes[shape.shape.id] = shape;
      }
      _snapMarkers(route.id);
    });
  }

  void _removeRoute(String routeId) {
    setState(() {
      if (_routes.containsKey(routeId)) {
        final route = _routes[routeId]!;
        for (final shape in route.shapes) {
          final shapeId = shape.shape.id;
          if (_shapes.containsKey(shapeId)) {
            _shapes.remove(shapeId);
          }
        }
        _routes.remove(routeId);
        if (_selectedRoute!.route.id == routeId) {
          _selectedRoute = null;
        }
      }
    });
  }

  void _onRouteTapped(PolylineId polylineId) {
    setState(() {
      _selectedRoute = _routes[_shapes[polylineId.value]!.shape.routeId];
    });
  }

  // void _toggleRouteVisible(String routeId) {
  //   final route = _routes[routeId]!;
  //   setState(() {
  //     route.visible = false;
  //     for (final shape in route.shapes) {
  //       final polyline = shape.polyline;
  //       shape.polyline = polyline.copyWith(visibleParam: !polyline.visible);
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // TODO: implement selected route options
    // final String? selectedId = _selectedRoute?.route.id;

    return Scaffold(
      appBar: AppBar(
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.menu))],
      ),
      body: SizedBox.expand(
        child: GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(42.3555, -71.0565),
            zoom: 12.0,
          ),
          polylines: Set.of(_shapes.values.map((e) => e.polyline)),
          markers: Set.of(_vehicles.values.map((e) => e.marker)),
          onMapCreated: _onMapCreated,
        ),
      ),
    );
  }
}
