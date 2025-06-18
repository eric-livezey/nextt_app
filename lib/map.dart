import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nextt_app/animated_marker.dart';
import 'package:nextt_app/api.dart' as api;
import 'package:web_socket_channel/web_socket_channel.dart'
    show WebSocketChannel;

class _MapShape {
  _MapShape(this.shape, this.polyline);

  final api.Shape shape;
  Polyline polyline;
}

class _MapRoute {
  _MapRoute(this.route, this.shapes);

  final api.Route route;
  final List<_MapShape> shapes;
  bool visible = true;
}

class _MapVehicle {
  _MapVehicle(this.vehicle, this.marker);

  api.Vehicle vehicle;
  Marker marker;
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<StatefulWidget> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver {
  WebSocketChannel? _channel;
  late GoogleMapController controller;
  final Map<String, _MapShape> _shapes = {};
  final Map<String, _MapRoute> _routes = {};
  final Map<String, _MapVehicle> _vehicles = {};

  @override
  void initState() {
    super.initState();
    _connectWebsocket();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _closeWebsocket();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _closeWebsocket();
    }
    if (state == AppLifecycleState.resumed) {
      if (_channel == null) {
        _connectWebsocket();
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    controller = controller;
  }

  /// Opens a new websocket channel.
  void _connectWebsocket() {
    // TODO: replace with real URI
    _channel = WebSocketChannel.connect(Uri.parse('ws://10.220.48.189:3000'));
    _channel!.stream.listen(_onWebSocketData, onDone: _onWebsocketDone);
    // Send initial filter
    _channel!.sink.add(
      jsonEncode(api.ResourceFilter(types: {'route', 'vehicle'})),
    );
  }

  void _closeWebsocket() {
    _channel?.sink.close(0);
  }

  void _onWebsocketDone() {
    _channel = null;
  }

  void _onWebSocketData(payload) {
    final Map<String, dynamic> jsonMap =
        jsonDecode(payload as String) as Map<String, dynamic>;
    final String type = jsonMap['type'] as String;
    final Object data = jsonMap['data'] as Object;
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

  void _onRouteReset(Object json) {
    List jsonList = json as List;
    for (final Object json in jsonList) {
      final route = api.Route.fromJson(json);
      if (_routes.containsKey(route.id)) {
        _removeRoute(route.id);
      }
      _addRoute(route);
    }
  }

  void _onRouteAdd(Object json) {
    final route = api.Route.fromJson(json);
    _addRoute(route);
  }

  void _onRouteUpdate(Object json) {
    final route = api.Route.fromJson(json);
    if (_routes.containsKey(route.id)) {
      _removeRoute(route.id);
    }
    _addRoute(route);
  }

  void _onRouteRemove(Object json) {
    Map<String, dynamic> jsonMap = json as Map<String, dynamic>;
    _removeRoute(jsonMap['id']);
  }

  void _onVehicleReset(Object json) {
    List jsonList = json as List;
    for (final Object json in jsonList) {
      final vehicle = api.Vehicle.fromJson(json);
      if (_vehicles.containsKey(vehicle.id)) {
        _removeVehicle(vehicle.id);
      }
      _addVehicle(vehicle);
    }
  }

  void _onVehicleAdd(Object json) {
    final vehicle = api.Vehicle.fromJson(json);
    _addVehicle(vehicle);
  }

  void _onVehicleUpdate(Object json) {
    final vehicle = api.Vehicle.fromJson(json);
    final mapVehicle = _vehicles[vehicle.id];
    if (mapVehicle != null) {
      mapVehicle.vehicle = vehicle;
      _moveVehicle(mapVehicle, vehicle.position);
    } else {
      _addVehicle(vehicle);
    }
  }

  void _onVehicleRemove(Object json) {
    Map<String, dynamic> jsonMap = json as Map<String, dynamic>;
    _removeVehicle(jsonMap['id'] as String);
  }

  /// Snaps a point to a route
  LatLng _snapPoint(LatLng coords, _MapRoute route) {
    return snapToRoute(
          coords,
          route.shapes.map((shape) => shape.polyline.points),
        ) ??
        coords;
  }

  /// Snaps all markers associated with the route
  void _snapMarkers(String routeId) {
    setState(() {
      for (final mapVehicle in _vehicles.values) {
        final vehicle = mapVehicle.vehicle;
        if (mapVehicle.vehicle.routeId == routeId) {
          mapVehicle.marker = mapVehicle.marker.copyWith(
            positionParam: _snapPoint(
              vehicle.position,
              _routes[vehicle.routeId]!,
            ),
          );
        }
      }
    });
  }

  void _moveVehicle(_MapVehicle vehicle, LatLng target) {
    final marker = vehicle.marker;
    setState(() {
      if (marker is AnimatedMarker) {
        vehicle.marker = marker.copyWith(
          rotationParam: vehicle.vehicle.bearing?.toDouble(),
          targetParam: target,
          durationParam: Durations.medium2,
        );
      } else {
        vehicle.marker = AnimatedMarker.from(
          marker.copyWith(rotationParam: vehicle.vehicle.bearing?.toDouble()),
          target: target,
          duration: Durations.medium2,
          route: _routes[vehicle.vehicle.routeId]?.shapes.map(
            (shape) => shape.polyline.points,
          ),
        );
      }
    });
  }

  Future<void> _addVehicle(api.Vehicle vehicle) async {
    final markerId = MarkerId(vehicle.id);
    final marker = Marker(
      markerId: markerId,
      position: _snapPoint(vehicle.position, _routes[vehicle.routeId]!),
      infoWindow: InfoWindow(title: vehicle.label),
      onTap: () => _onVehicleTapped(markerId),
      icon: await BitmapDescriptor.asset(
        ImageConfiguration(size: Size(20, 20)),
        "assets/navigation.png",
      ),
      anchor: Offset(0.5, 0.5),
      rotation: vehicle.bearing?.toDouble() ?? 0.0,
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

  _onMarkerChanged(AnimatedMarker marker) {
    final vehicle = _vehicles[marker.markerId.value];
    if (vehicle != null) {
      vehicle.marker = marker;
    }
  }

  _onVehicleTapped(MarkerId markerId) {
    // TODO
  }

  void _addRoute(api.Route route) {
    final List<_MapShape> mapShapes = [];
    for (api.Shape shape in route.shapes) {
      final PolylineId polylineId = PolylineId(shape.id);
      mapShapes.add(
        _MapShape(
          shape,
          Polyline(
            polylineId: polylineId,
            color: route.color ?? Colors.black,
            points: shape.polyline,
            width: 5,
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
      }
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
    return Scaffold(
      appBar: AppBar(
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.menu))],
      ),
      body: SizedBox.expand(
        child: AnimatedMarkerMapBuilder(
          builder:
              (context, markers) => GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(42.3555, -71.0565),
                  zoom: 12.0,
                ),
                polylines: Set.of(_shapes.values.map((e) => e.polyline)),
                markers: markers,
                onMapCreated: _onMapCreated,
              ),
          markers: Set.of(_vehicles.values.map((vehicle) => vehicle.marker)),
          onMarkerChanged: _onMarkerChanged,
        ),
      ),
    );
  }
}
