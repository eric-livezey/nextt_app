import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nextt_app/animated_marker.dart';
import 'package:nextt_app/api.dart' as api;
import 'package:nextt_app/stream.dart';

const LatLng _mapCenter = LatLng(42.3555, -71.0565);
final AssetMapBitmap _vehicleMarkerIconBytes = AssetMapBitmap(
  'assets/navigation.png',
  width: 20,
  height: 20,
);
final AssetMapBitmap _stopMarkerIconBytes = AssetMapBitmap(
  'assets/mbta.png',
  width: 12,
  height: 12,
);

class _MapShape {
  _MapShape(this.shape, this.polyline);

  api.Shape shape;
  Polyline polyline;
}

class _MapRoute {
  _MapRoute(this.route, this.shapes);

  api.Route route;
  List<_MapShape> shapes;
  bool visible = true;
}

class _MapVehicle {
  _MapVehicle(this.vehicle, this.marker);

  api.Vehicle vehicle;
  Marker marker;
}

class _MapStop {
  _MapStop(this.stop, this.marker);

  api.Stop stop;
  Marker marker;
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<StatefulWidget> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver {
  _MapPageState() {
    _stream.listen(
      onRouteReset: _onRouteReset,
      onRouteAdd: _onRouteAdd,
      onRouteUpdate: _onRouteUpdate,
      onRouteRemove: _onRouteRemove,
      onVehicleReset: _onVehicleReset,
      onVehicleAdd: _onVehicleAdd,
      onVehicleUpdate: _onVehicleUpdate,
      onVehicleRemove: _onVehicleRemove,
      onStopReset: _onStopReset,
    );
    _stream.connect();
  }

  final ResourceStream _stream = ResourceStream(
    ResourceFilter(types: ResourceType.values.toSet()),
  );
  final Map<String, _MapShape> _shapes = {};
  final Map<String, _MapRoute> _routes = {};
  final Map<String, _MapVehicle> _vehicles = {};
  final Map<String, _MapStop> _stops = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stream.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stream.close();
    }
    if (state == AppLifecycleState.resumed) {
      if (!_stream.isOpen) {
        _stream.connect();
      }
    }
  }

  void _onRouteReset(List<api.Route> routes) {
    for (final api.Route route in routes) {
      if (_routes.containsKey(route.id)) {
        _removeRoute(route.id);
      }
      _addRoute(route);
    }
  }

  void _onRouteAdd(api.Route route) {
    _addRoute(route);
  }

  void _onRouteUpdate(api.Route route) {
    if (_routes.containsKey(route.id)) {
      _removeRoute(route.id);
    }
    _addRoute(route);
  }

  void _onRouteRemove(String routeId) {
    _removeRoute(routeId);
  }

  void _onVehicleReset(List<api.Vehicle> vehicles) {
    for (final api.Vehicle vehicle in vehicles) {
      if (_vehicles.containsKey(vehicle.id)) {
        _removeVehicle(vehicle.id);
      }
      _addVehicle(vehicle);
    }
  }

  void _onVehicleAdd(api.Vehicle vehicle) {
    _addVehicle(vehicle);
  }

  void _onVehicleUpdate(api.Vehicle vehicle) {
    final mapVehicle = _vehicles[vehicle.id];
    if (mapVehicle != null) {
      mapVehicle.vehicle = vehicle;
      _moveVehicle(mapVehicle, vehicle.position);
    } else {
      _addVehicle(vehicle);
    }
  }

  void _onVehicleRemove(String vehicleId) {
    _removeVehicle(vehicleId);
  }

  void _onStopReset(List<api.Stop> stops) {
    for (final api.Stop stop in stops.where(
      (stop) => stop.locationType == api.LocationType.stop,
    )) {
      if (_stops.containsKey(stop.id)) {
        _removeStop(stop.id);
      }
      _addStop(stop);
    }
  }

  void _onStopAdd(api.Stop stop) {
    _addStop(stop);
  }

  void _onStopUpdate(api.Stop stop) {
    if (_stops.containsKey(stop.id)) {
      _removeStop(stop.id);
    }
    _addStop(stop);
  }

  void _onStopRemove(String stopId) {
    _removeStop(stopId);
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
      for (final _MapVehicle mapVehicle in _vehicles.values) {
        final api.Vehicle vehicle = mapVehicle.vehicle;
        if (vehicle.routeId == routeId) {
          mapVehicle.marker = mapVehicle.marker.copyWith(
            positionParam: _snapPoint(vehicle.position, _routes[routeId]!),
          );
        }
      }
      for (final _MapStop mapStop in _stops.values) {
        final api.Stop stop = mapStop.stop;
        if (stop.routeIds.contains(routeId)) {
          mapStop.marker = mapStop.marker.copyWith(
            positionParam: _snapPoint(stop.position, _routes[routeId]!),
          );
        }
      }
    });
  }

  void _addStop(api.Stop stop) {
    MarkerId markerId = MarkerId(stop.id);
    _MapStop mapStop = _MapStop(
      stop,
      Marker(
        markerId: markerId,
        position: stop.position,
        infoWindow: InfoWindow(title: stop.name, snippet: stop.description),
        icon: _stopMarkerIconBytes,
        anchor: Offset(0.5, 0.5),
      ),
    );
    setState(() {
      _stops[stop.id] = mapStop;
    });
  }

  _removeStop(String stopId) {
    if (_stops.containsKey(stopId)) {
      setState(() {
        _stops.remove(stopId);
      });
    }
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

  void _addVehicle(api.Vehicle vehicle) {
    final markerId = MarkerId(vehicle.id);
    final marker = Marker(
      markerId: markerId,
      position: _snapPoint(vehicle.position, _routes[vehicle.routeId]!),
      infoWindow: InfoWindow(title: vehicle.label),
      onTap: () => _onVehicleTapped(markerId),
      icon: _vehicleMarkerIconBytes,
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
                  target: _mapCenter,
                  zoom: 12.0,
                ),
                polylines: Set.of(_shapes.values.map((e) => e.polyline)),
                markers: markers,
                cloudMapId: '430807d65e79d65b3e56ad5e',
                myLocationEnabled: true,
                mapToolbarEnabled: false,
              ),
          markers: Set.of(
            _vehicles.values
                .map((vehicle) => vehicle.marker)
                .followedBy(_stops.values.map((stop) => stop.marker)),
          ),
          onMarkerChanged: _onMarkerChanged,
        ),
      ),
    );
  }
}
