import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nextt_app/mbta.dart' as mbta;
import 'package:web_socket_channel/web_socket_channel.dart';

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

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<StatefulWidget> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  _MapPageState();

  WebSocketChannel? _channel;
  GoogleMapController? controller;
  final Map<PolylineId, _MapShape> _shapes = {};
  final Map<String, _MapRoute> _routes = {};
  _MapRoute? _selectedRoute;

  @override
  void initState() {
    super.initState();
    // TODO: replace with real URI
    _channel = WebSocketChannel.connect(Uri.parse('ws://10.220.48.124:3000'));
    _channel!.stream.listen(_onWebSocketData);
  }

  @override
  void dispose() {
    super.dispose();
    _channel?.sink.close();
    _channel = null;
  }

  void _onWebSocketData(event) {
    final data = jsonDecode(event);
    final String type = data['type'];
    switch (type) {
      case 'ROUTE_RESET':
        _onRoutesRefresh(data['data']);
    }
  }

  void _onRoutesRefresh(List data) {
    for (final routeData in data) {
      final route = mbta.Route.fromJson(routeData);
      if (_routes.containsKey(route.id)) {
        _removeRoute(route.id);
      }
      _addRoute(route);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    this.controller = controller;
  }

  void _onPolylineTapped(PolylineId polylineId) {
    setState(() {
      _selectedRoute = _routes[_shapes[polylineId]!.shape.routeId];
    });
  }

  void _removeRoute(String routeId) {
    setState(() {
      if (_routes.containsKey(routeId)) {
        final route = _routes[routeId]!;
        for (final shape in route.shapes) {
          final polylineId = shape.polyline.polylineId;
          if (_shapes.containsKey(polylineId)) {
            _shapes.remove(polylineId);
          }
        }
        _routes.remove(routeId);
        if (_selectedRoute!.route.id == routeId) {
          _selectedRoute = null;
        }
      }
    });
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
              _onPolylineTapped(polylineId);
            },
          ),
        ),
      );
    }
    setState(() {
      _routes[route.id] = _MapRoute(route, mapShapes);
      for (_MapShape shape in mapShapes) {
        _shapes[shape.polyline.polylineId] = shape;
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
          onMapCreated: _onMapCreated,
        ),
      ),
    );
  }
}
