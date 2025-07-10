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

  final api.Shape shape;
  Polyline polyline;
}

class _MapRoute {
  _MapRoute(this.route, this.shapes, this.visible);

  final api.Route route;
  List<_MapShape> shapes;
  bool visible;
}

class _MapVehicle {
  _MapVehicle(this.vehicle, this.marker, this.visible);

  api.Vehicle vehicle;
  Marker marker;
  bool visible;
}

class _MapStop {
  _MapStop(this.stop, this.marker, this.visible);

  final api.Stop stop;
  Marker marker;
  bool visible;
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
      onStopAdd: _onStopAdd,
      onStopUpdate: _onStopUpdate,
      onStopRemove: _onStopRemove,
    );
    _stream.connect();
  }

  final ResourceStream _stream = ResourceStream(
    ResourceFilter(
      types: {ResourceType.route, ResourceType.stop, ResourceType.vehicle},
      routeTypes: {api.RouteType.lightRail, api.RouteType.heavyRail},
    ),
  );
  final List<_MapRoute> _routeList = [];
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
    final MarkerId markerId = MarkerId(stop.id);
    final bool visible = stop.routeIds.any(
      (id) => _routes[id]?.visible == true,
    );
    final _MapStop mapStop = _MapStop(
      stop,
      Marker(
        markerId: markerId,
        position: stop.position,
        infoWindow: InfoWindow(title: stop.name, snippet: stop.description),
        icon: _stopMarkerIconBytes,
        anchor: Offset(0.5, 0.5),
        visible: visible,
      ),
      stop.routeIds.any((id) => _routes[id]?.visible == true),
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
    final bool visible = _routes[vehicle.vehicle.routeId]?.visible == true;
    setState(() {
      if (marker is AnimatedMarker) {
        vehicle.marker = marker.copyWith(
          rotationParam: vehicle.vehicle.bearing?.toDouble(),
          targetParam: target,
          durationParam: Durations.medium2,
          visibleParam: visible,
        );
      } else {
        vehicle.marker = AnimatedMarker.from(
          marker.copyWith(
            rotationParam: vehicle.vehicle.bearing?.toDouble(),
            visibleParam: visible,
          ),
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
    final MarkerId markerId = MarkerId(vehicle.id);
    final bool visible = _routes[vehicle.routeId]?.visible == true;
    final Marker marker = Marker(
      markerId: markerId,
      position:
          _routes.containsKey(vehicle.routeId)
              ? _snapPoint(vehicle.position, _routes[vehicle.routeId]!)
              : vehicle.position,
      infoWindow: InfoWindow(title: vehicle.label),
      icon: _vehicleMarkerIconBytes,
      anchor: Offset(0.5, 0.5),
      rotation: vehicle.bearing?.toDouble() ?? 0.0,
      visible: visible,
    );

    final _MapVehicle mapVehicle = _MapVehicle(vehicle, marker, visible);

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

  void _insertRouteInOrder(_MapRoute route) {
    int? sortOrder = route.route.sortOrder;
    if (sortOrder == null) {
      _routeList.add(route);
    } else {
      int index = _routeList.indexWhere(
        (r) => r.route.sortOrder == null || r.route.sortOrder! > sortOrder,
      );
      if (index >= 0) {
        _routeList.insert(index, route);
      } else {
        _routeList.add(route);
      }
    }
  }

  void _addRoute(api.Route route) {
    final List<_MapShape> mapShapes = [];
    final bool visible =
        _stream.filter.routeTypes?.contains(route.type) == true &&
            _stream.filter.routeIds == null ||
        _stream.filter.routeIds?.contains(route.id) == true;
    for (api.Shape shape in route.shapes) {
      mapShapes.add(
        _MapShape(
          shape,
          Polyline(
            polylineId: PolylineId(shape.id),
            color: route.color,
            points: shape.polyline,
            width: route.width,
            visible: visible,
          ),
        ),
      );
    }
    setState(() {
      _MapRoute mapRoute = _MapRoute(route, mapShapes, visible);
      _routes[route.id] = mapRoute;
      _insertRouteInOrder(mapRoute);
      for (_MapShape shape in mapShapes) {
        _shapes[shape.shape.id] = shape;
      }
      _snapMarkers(route.id);
    });
  }

  void _removeRoute(String routeId) {
    final _MapRoute? route = _routes[routeId];
    if (route != null) {
      setState(() {
        for (final shape in route.shapes) {
          final shapeId = shape.shape.id;
          if (_shapes.containsKey(shapeId)) {
            _shapes.remove(shapeId);
          }
        }
        _routes.remove(routeId);
        _routeList.removeWhere((route) => route.route.id == routeId);
      });
    }
  }

  /*
   * --------------
   * | Visibility |
   * --------------
   */

  void _hideRoute(String routeId) {
    _stream.filter.routeIds ??=
        _routes.values
            .where((route) => route.visible)
            .map((route) => route.route.id)
            .toSet();
    _stream.filter.routeIds?.remove(routeId);
    _stream.commit();
    final _MapRoute? route = _routes[routeId];
    if (route != null) {
      // every stop where every related route is hidden or relates to the route ID
      final Iterable<_MapStop> stops = _stops.values.where(
        (stop) =>
            stop.visible &&
            stop.stop.routeIds.every(
              (id) => id == routeId || _routes[id]?.visible != true,
            ),
      );
      // every vehicle related to the route ID
      final Iterable<_MapVehicle> vehicles = _vehicles.values.where(
        (vehicle) => vehicle.visible && vehicle.vehicle.routeId == routeId,
      );
      _setElementVisibility(
        false,
        routes: [route],
        stops: stops,
        vehicles: vehicles,
      );
    }
  }

  void _showRoute(String routeId) {
    _stream.filter.routeIds ??=
        _routes.values
            .where((route) => route.visible)
            .map((route) => route.route.id)
            .toSet();
    _stream.filter.routeIds!.add(routeId);
    _stream.commit();
    final _MapRoute? route = _routes[routeId];
    if (route != null) {
      // every stop where any related route is not hidden or relates to the route ID
      final Iterable<_MapStop> stops = _stops.values.where(
        (stop) =>
            !stop.visible &&
            stop.stop.routeIds.any(
              (id) => id == routeId || _routes[id]?.visible == true,
            ),
      );
      // every vehicle related to the route ID
      final Iterable<_MapVehicle> vehicles = _vehicles.values.where(
        (vehicle) => !vehicle.visible && vehicle.vehicle.routeId == routeId,
      );
      _setElementVisibility(
        true,
        routes: [route],
        stops: stops,
        vehicles: vehicles,
      );
    }
  }

  void _hideRouteType(api.RouteType routeType) {
    _stream.filter.routeTypes!.remove(routeType);
    _stream.commit();
    // every route with the route type
    final Iterable<_MapRoute> routes = _routes.values.where(
      (route) => route.visible && route.route.type == route.route.type,
    );
    // every stop where every related route is hidden or has the route type
    final Iterable<_MapStop> stops = _stops.values.where(
      (stop) =>
          stop.visible &&
          stop.stop.routeIds
              .map((id) => _routes[id])
              .every(
                (route) =>
                    route == null ||
                    route.visible != true ||
                    route.route.type == routeType,
              ),
    );
    // every vehicle related to a route with the route type
    final Iterable<_MapVehicle> vehicles = _vehicles.values.where(
      (vehicle) =>
          vehicle.visible &&
          _routes[vehicle.vehicle.routeId]?.route.type == routeType,
    );
    _setElementVisibility(
      false,
      routes: routes,
      stops: stops,
      vehicles: vehicles,
    );
  }

  void _showRouteType(api.RouteType routeType) {
    _stream.filter.routeTypes!.add(routeType);
    _stream.commit();
    // every route with the route type
    final Iterable<_MapRoute> routes = _routes.values.where(
      (route) => route.visible && route.route.type == route.route.type,
    );
    // every stop where every related route is hidden or has the route type
    final Iterable<_MapStop> stops = _stops.values.where(
      (stop) =>
          stop.visible &&
          stop.stop.routeIds
              .map((id) => _routes[id])
              .any(
                (route) =>
                    route?.visible == true || route?.route.type == routeType,
              ),
    );
    // every vehicle related to a route with the route type
    final Iterable<_MapVehicle> vehicles = _vehicles.values.where(
      (vehicle) =>
          vehicle.visible &&
          _routes[vehicle.vehicle.routeId]?.route.type == routeType,
    );
    _setElementVisibility(
      true,
      routes: routes,
      stops: stops,
      vehicles: vehicles,
    );
  }

  _setElementVisibility(
    bool visible, {
    Iterable<_MapRoute> routes = const [],
    Iterable<_MapStop> stops = const [],
    Iterable<_MapVehicle> vehicles = const [],
  }) {
    setState(() {
      for (final _MapRoute route in routes) {
        for (_MapShape shape in route.shapes) {
          shape.polyline = shape.polyline.copyWith(visibleParam: visible);
        }
        route.visible = visible;
      }
      for (final _MapStop stop in stops) {
        stop.marker = stop.marker.copyWith(visibleParam: visible);
        stop.visible = visible;
      }
      for (final _MapVehicle vehicle in vehicles) {
        vehicle.marker = vehicle.marker.copyWith(visibleParam: visible);
        vehicle.visible = visible;
      }
    });
  }

  void _toggleRouteTypeVisible(api.RouteType routeType) {
    final bool visible = _stream.filter.routeTypes!.contains(routeType);
    if (visible) {
      _showRouteType(routeType);
    } else {
      _hideRouteType(routeType);
    }
  }

  void _toggleRouteVisible(String routeId) {
    final _MapRoute? route = _routes[routeId];
    if (route != null) {
      final bool visible = !route.visible;
      if (visible) {
        _showRoute(routeId);
      } else {
        _hideRoute(routeId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Builder(
            builder:
                (context) => IconButton(
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                  icon: Icon(Icons.filter_list),
                ),
          ),
        ],
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
                .followedBy(_stops.values.map((stop) => stop.marker))
                .toSet(),
          ),
          onMarkerChanged: _onMarkerChanged,
        ),
      ),
      endDrawer: Drawer(
        child: ListView(
          children: List.of(
            <Widget>[
              DrawerHeader(
                child: Text(
                  'Filter Routes',
                  textAlign: TextAlign.center,
                  textScaler: TextScaler.linear(2),
                ),
              ),
            ].followedBy(
              _routeList.map(
                (route) => CheckboxListTile(
                  title: Text(route.route.longName ?? 'Unknown'),
                  value: route.visible,
                  onChanged: (bool? value) {
                    _toggleRouteVisible(route.route.id);
                  },
                  secondary: Icon(
                    route.route.iconData,
                    color: route.route.color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
