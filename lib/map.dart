import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:nextt_app/animated_marker.dart';
import 'package:nextt_app/api.dart' as api;
import 'package:nextt_app/stop_sheet.dart';
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
  _MapVehicle(this.vehicle, this.marker);

  api.Vehicle vehicle;
  Marker marker;
}

class _MapStop {
  _MapStop(this.stop, this.marker);

  final api.Stop stop;
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
      onStopAdd: _onStopAdd,
      onStopUpdate: _onStopUpdate,
      onStopRemove: _onStopRemove,
    );
    _stream.connect();
  }

  final ResourceStream _stream = ResourceStream(
    ResourceFilter(
      types: {
        ResourceType.route,
        ResourceType.stop,
        ResourceType.vehicle,
        ResourceType.alert,
        ResourceType.schedule,
        ResourceType.prediction,
      },
      routeTypes: {api.RouteType.lightRail, api.RouteType.heavyRail},
      stopIds: {},
    ),
  );
  final List<_MapRoute> _routeList = [];
  final Map<String, _MapRoute> _routes = {};
  final Map<String, _MapVehicle> _vehicles = {};
  final Map<String, _MapStop> _stops = {};
  // ignore: unused_field
  late GoogleMapController _controller;
  PersistentBottomSheetController? _stopSheetController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stream.close();
    _stopSheetController?.close();
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
    _routeList.clear();
    _routes.clear();
    _onRouteAdd(routes);
  }

  void _onRouteAdd(List<api.Route> routes) {
    for (final api.Route route in routes) {
      _addRoute(route);
    }
  }

  void _onRouteUpdate(List<api.Route> routes) {
    for (final api.Route route in routes) {
      if (_routes.containsKey(route.id)) {
        _removeRoute(route.id);
      }
      _addRoute(route);
    }
  }

  void _onRouteRemove(List<String> routeIds) {
    for (final String routeId in routeIds) {
      _removeRoute(routeId);
    }
  }

  void _onVehicleReset(List<api.Vehicle> vehicles) {
    _vehicles.clear();
    _onVehicleAdd(vehicles);
  }

  void _onVehicleAdd(List<api.Vehicle> vehicles) {
    for (final api.Vehicle vehicle in vehicles) {
      _addVehicle(vehicle);
    }
  }

  void _onVehicleUpdate(List<api.Vehicle> vehicles) {
    for (final api.Vehicle vehicle in vehicles) {
      final mapVehicle = _vehicles[vehicle.id];
      if (mapVehicle != null) {
        mapVehicle.vehicle = vehicle;
        _moveVehicle(mapVehicle, vehicle.position);
      } else {
        _addVehicle(vehicle);
      }
    }
  }

  void _onVehicleRemove(List<String> vehicleIds) {
    for (final String vehicleId in vehicleIds) {
      _removeVehicle(vehicleId);
    }
  }

  void _onStopReset(List<api.Stop> stops) {
    _stops.clear();
    _onStopAdd(stops);
  }

  void _onStopAdd(List<api.Stop> stops) {
    for (final api.Stop stop in stops.where(
      (stop) =>
          stop.locationType == api.LocationType.station ||
          stop.locationType == api.LocationType.stop,
    )) {
      _addStop(stop);
    }
  }

  void _onStopUpdate(List<api.Stop> stops) {
    for (final api.Stop stop in stops) {
      if (_stops.containsKey(stop.id)) {
        _removeStop(stop.id);
      }
      _addStop(stop);
    }
  }

  void _onStopRemove(List<String> stopIds) {
    for (final String stopId in stopIds) {
      _removeStop(stopId);
    }
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
    final _MapStop mapStop = _MapStop(
      stop,
      Marker(
        markerId: markerId,
        position: stop.position,
        infoWindow: InfoWindow(title: stop.name, snippet: stop.description),
        icon: _stopMarkerIconBytes,
        anchor: Offset(0.5, 0.5),
        onTap: () {
          _stopSheetController = showBottomSheet(
            context: context,
            constraints: BoxConstraints.loose(
              Size(
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height / 2.0,
              ),
            ),
            builder:
                (context) => StopSheet.fromStopId(
                  stopId: markerId.value,
                  routeIds: stop.routeIds.intersection(
                    _stream.filter.routeIds ??
                        _routes.values
                            .where(
                              (route) => _stream.filter.routeTypes!.contains(
                                route.route.type,
                              ),
                            )
                            .map((route) => route.route.id)
                            .toSet(),
                  ),
                ),
          );
          _controller.animateCamera(
            CameraUpdateNewLatLngZoom(LatLng(stop.latitude - 0.015, stop.longitude), 14.0),
          );
        },
        consumeTapEvents: false
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
    final MarkerId markerId = MarkerId(vehicle.id);
    final Marker marker = Marker(
      markerId: markerId,
      position:
          _routes.containsKey(vehicle.routeId)
              ? _snapPoint(vehicle.position, _routes[vehicle.routeId]!)
              : vehicle.position,
      icon: _vehicleMarkerIconBytes,
      anchor: Offset(0.5, 0.5),
      rotation: vehicle.bearing?.toDouble() ?? 0.0,
      consumeTapEvents: true,
    );

    final _MapVehicle mapVehicle = _MapVehicle(vehicle, marker);

    setState(() {
      _vehicles[vehicle.id] = mapVehicle;
    });
  }

  void _removeVehicle(String vehicleId) {
    if (_vehicles.containsKey(vehicleId)) {
      setState(() {
        _vehicles.remove(vehicleId);
      });
    }
  }

  void _onMarkerChanged(AnimatedMarker marker) {
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
      // if the route is not already in the list
      if (index <= 0 || _routeList[index - 1].route.id != route.route.id) {
        if (index >= 0) {
          _routeList.insert(index, route);
        } else {
          _routeList.add(route);
        }
      }
    }
  }

  void _addRoute(api.Route route) {
    final List<_MapShape> mapShapes = [];
    for (api.Shape shape in route.shapes) {
      mapShapes.add(
        _MapShape(
          shape,
          Polyline(
            polylineId: PolylineId(shape.id),
            color: route.color,
            points: shape.polyline,
            width: route.width,
          ),
        ),
      );
    }
    final bool visible =
        _stream.filter.routeTypes?.contains(route.type) == true &&
            _stream.filter.routeIds == null ||
        _stream.filter.routeIds?.contains(route.id) == true;
    setState(() {
      _MapRoute mapRoute = _MapRoute(route, mapShapes, visible);
      _routes[route.id] = mapRoute;
      _insertRouteInOrder(mapRoute);
      _snapMarkers(route.id);
    });
  }

  void _removeRoute(String routeId) {
    final _MapRoute? route = _routes[routeId];
    if (route != null) {
      setState(() {
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
    final _MapRoute? route = _routes[routeId];
    if (route != null) {
      _setRoutesVisibility(false, [route]);
      _stream.filter.routeIds ??=
          _routes.values
              .where((route) => route.visible)
              .map((route) => route.route.id)
              .toSet();
      _stream.filter.routeIds?.remove(routeId);
      _stream.commit();
    }
  }

  void _showRoute(String routeId) {
    final _MapRoute? route = _routes[routeId];
    if (route != null) {
      if (!_stream.filter.routeTypes!.contains(route.route.type)) {
        _stream.filter.routeTypes!.add(route.route.type);
      }
      _setRoutesVisibility(true, [route]);
      _stream.filter.routeIds ??=
          _routes.values
              .where((route) => route.visible)
              .map((route) => route.route.id)
              .toSet();
      _stream.filter.routeIds!.add(routeId);
      _stream.commit();
    }
  }

  void _hideRouteType(api.RouteType routeType) {
    // every route with the route type
    final Iterable<_MapRoute> routes = _routes.values.where(
      (route) => route.visible && route.route.type == route.route.type,
    );
    _setRoutesVisibility(false, routes);
    _stream.filter.routeTypes!.remove(routeType);
    _stream.commit();
  }

  void _showRouteType(api.RouteType routeType) {
    // every route with the route type
    final Iterable<_MapRoute> routes = _routes.values.where(
      (route) => !route.visible && route.route.type == route.route.type,
    );
    _setRoutesVisibility(true, routes);
    _stream.filter.routeTypes!.add(routeType);
    _stream.commit();
  }

  _setRoutesVisibility(bool visible, Iterable<_MapRoute> routes) {
    setState(() {
      for (final _MapRoute route in routes) {
        route.visible = visible;
      }
    });
  }

  // ignore: unused_element
  void _toggleRouteTypeVisible(api.RouteType routeType) {
    final bool visible = _stream.filter.routeTypes!.contains(routeType);
    if (visible) {
      _showRouteType(routeType);
    } else {
      _hideRouteType(routeType);
    }
  }

  void _setRouteVisible(String routeId, bool visible) {
    final _MapRoute? route = _routes[routeId];
    if (route != null) {
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
        title: Text(
          'Map View',
          style: TextStyle(fontWeight: FontWeight.bold),
          textScaler: TextScaler.linear(1.25),
        ),
        actions: [
          Builder(
            builder:
                (context) => IconButton(
                  onPressed: () {
                    _stopSheetController?.close();
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
                polylines: Set.of(
                  _routes.values
                      .where((route) => route.visible)
                      .expand(
                        (route) => route.shapes.map((shape) => shape.polyline),
                      ),
                ),
                markers: markers,
                cloudMapId: '430807d65e79d65b3e56ad5e',
                myLocationEnabled: true,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  _controller = controller;
                },
              ),
          markers: Set.of(
            (_stream.filter.types.contains(ResourceType.vehicle)
                    ? _vehicles.values
                        .where(
                          (vehicle) =>
                              _routes[vehicle.vehicle.routeId]?.visible == true,
                        )
                        .map((vehicle) => vehicle.marker)
                    : <Marker>[])
                .followedBy(
                  _stream.filter.types.contains(ResourceType.stop)
                      ? _stops.values
                          .where(
                            (stop) => stop.stop.routeIds
                                .map((id) => _routes[id])
                                .any((route) => route?.visible == true),
                          )
                          .map((stop) => stop.marker)
                      : <Marker>[],
                )
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
                      'Filter By Route',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                ]
                .followedBy([
                  CheckboxListTile(
                    title: Text('Stops'),
                    value: _stream.filter.types.contains(ResourceType.stop),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _stream.filter.types.add(ResourceType.stop);
                        } else {
                          _stream.filter.types.remove(ResourceType.stop);
                        }
                      });
                      _stream.commit();
                    },
                  ),
                  CheckboxListTile(
                    title: Text('Vehicles'),
                    value: _stream.filter.types.contains(ResourceType.vehicle),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _stream.filter.types.add(ResourceType.vehicle);
                        } else {
                          _stream.filter.types.remove(ResourceType.vehicle);
                        }
                      });
                      _stream.commit();
                    },
                  ),
                ])
                .followedBy(
                  _routeList.map(
                    (route) => CheckboxListTile(
                      title: Text(route.route.longName),
                      value: route.visible,
                      onChanged: (bool? value) {
                        _setRouteVisible(route.route.id, value == true);
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
