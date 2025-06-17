import 'dart:math' show Point, atan, exp, log, pi, tan;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

extension PointVectorMath on Point<double> {
  /// Take the dot product of [other] with `this`, as if both points were vectors.
  double dot(Point<double> other) => x * other.x + y * other.y;
}

/// Returns the projection of `q` onto the line between at `a` and `b`.
///
/// https://en.wikipedia.org/wiki/Vector_projection
Point<double> project(Point<double> q, Point<double> a, Point<double> b) {
  final ab = b - a;
  final t = (ab.dot(q - a) / ab.dot(ab)).clamp(0, 1).toDouble();
  return a + ab * t;
}

/// Earth's radius
const double r = 6378137.0;

/// Converts a latitude longitude pair to a point on the mercator projection.
///
/// https://en.wikipedia.org/wiki/Mercator_projection
Point<double> latLngToPoint(LatLng coords) {
  final longitude = coords.longitude * pi / 180.0;
  final latitude = coords.latitude * pi / 180.0;
  final x = r * longitude;
  final y = r * log(tan(pi / 4 + latitude / 2));
  return Point(x, y);
}

/// Converts a point on the mercator projection to a latitude longitude pair
///
/// https://en.wikipedia.org/wiki/Mercator_projection
LatLng pointToLatLng(Point point) {
  final longitude = point.x / r;
  final latitude = 2 * atan(exp(point.y / r)) - pi / 2;
  return LatLng(latitude * 180 / pi, longitude * 180 / pi);
}

/// Returns the closest point on the route represented by a group of shapes to a point.
///
/// This is implemented by finding the shortest vector which results from projecting the point onto each line.
Point? snapToRouteOfPoints(
  Point<double> point,
  Iterable<Iterable<Point<double>>> shapes,
) {
  double min = double.infinity;
  Point<double>? closest;

  // loop through non-empty shapes
  for (final shape in shapes.where((shape) => shape.isNotEmpty)) {
    Point<double> previous = shape.first;

    // loop through vertices
    for (final vertex in shape.skip(1)) {
      final a = previous;
      final b = vertex;
      // get projection of the point onto the line between a and b
      final projection = project(point, a, b);
      // calculate distance
      final dist = (projection - point).distanceTo(const Point(0, 0));

      if (dist < min) {
        min = dist;
        closest = projection;
        // return if the point is on the line
        if (min == 0) {
          return closest;
        }
      }
      previous = vertex;
    }
  }

  return closest;
}

/// Returns the closest point on the route represented by a group of polylines to a geographical point.
LatLng? snapToRoute(LatLng coords, Iterable<Iterable<LatLng>> polylines) {
  final closest = snapToRouteOfPoints(
    latLngToPoint(coords),
    polylines.map(
      (polyline) => polyline.map((coords) => latLngToPoint(coords)),
    ),
  );
  return closest != null ? pointToLatLng(closest) : null;
}

Object? _routeToJson(Iterable<Iterable<LatLng>>? route) {
  if (route == null) {
    return null;
  }
  return List.from(
    route.map((polyline) => List.from(polyline.map((point) => point.toJson()))),
  );
}

class AnimatedMarker extends Marker {
  const AnimatedMarker({
    required super.markerId,
    super.alpha = 1.0,
    super.anchor = const Offset(0.5, 1.0),
    super.consumeTapEvents = false,
    super.draggable = false,
    super.flat = false,
    super.icon = BitmapDescriptor.defaultMarker,
    super.infoWindow = InfoWindow.noText,
    super.position = const LatLng(0.0, 0.0),
    super.rotation = 0.0,
    super.visible = true,
    super.zIndex = 0.0,
    super.clusterManagerId,
    super.onTap,
    super.onDrag,
    super.onDragStart,
    super.onDragEnd,
    required this.target,
    this.duration = Duration.zero,
    this.route,
  }) : assert(0.0 <= alpha && alpha <= 1.0);

  factory AnimatedMarker.from(
    Marker marker, {
    required LatLng target,
    Duration duration = Duration.zero,
    Iterable<Iterable<LatLng>>? route,
  }) {
    return AnimatedMarker(
      markerId: marker.markerId,
      alpha: marker.alpha,
      anchor: marker.anchor,
      consumeTapEvents: marker.consumeTapEvents,
      draggable: marker.draggable,
      flat: marker.flat,
      icon: marker.icon,
      infoWindow: marker.infoWindow,
      position: marker.position,
      rotation: marker.rotation,
      visible: marker.visible,
      zIndex: marker.zIndex,
      onTap: marker.onTap,
      onDragStart: marker.onDragStart,
      onDrag: marker.onDrag,
      onDragEnd: marker.onDragEnd,
      clusterManagerId: marker.clusterManagerId,
      target: target,
      duration: duration,
      route: route,
    );
  }

  final LatLng target;
  final Duration duration;
  final Iterable<Iterable<LatLng>>? route;

  @override
  AnimatedMarker copyWith({
    double? alphaParam,
    Offset? anchorParam,
    bool? consumeTapEventsParam,
    bool? draggableParam,
    bool? flatParam,
    BitmapDescriptor? iconParam,
    InfoWindow? infoWindowParam,
    LatLng? positionParam,
    double? rotationParam,
    bool? visibleParam,
    double? zIndexParam,
    VoidCallback? onTapParam,
    ValueChanged<LatLng>? onDragStartParam,
    ValueChanged<LatLng>? onDragParam,
    ValueChanged<LatLng>? onDragEndParam,
    ClusterManagerId? clusterManagerIdParam,
    LatLng? targetParam,
    Duration? durationParam,
    Iterable<Iterable<LatLng>>? routeParam,
  }) {
    return AnimatedMarker(
      markerId: markerId,
      alpha: alphaParam ?? alpha,
      anchor: anchorParam ?? anchor,
      consumeTapEvents: consumeTapEventsParam ?? consumeTapEvents,
      draggable: draggableParam ?? draggable,
      flat: flatParam ?? flat,
      icon: iconParam ?? icon,
      infoWindow: infoWindowParam ?? infoWindow,
      position: positionParam ?? position,
      rotation: rotationParam ?? rotation,
      visible: visibleParam ?? visible,
      zIndex: zIndexParam ?? zIndex,
      onTap: onTapParam ?? onTap,
      onDragStart: onDragStartParam ?? onDragStart,
      onDrag: onDragParam ?? onDrag,
      onDragEnd: onDragEndParam ?? onDragEnd,
      clusterManagerId: clusterManagerIdParam ?? clusterManagerId,
      target: targetParam ?? target,
      duration: durationParam ?? duration,
      route: routeParam ?? route,
    );
  }

  @override
  Object toJson() {
    final json = super.toJson() as Map<String, Object>;

    void addIfPresent(String fieldName, Object? value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent('target', target.toJson());
    addIfPresent('duration', duration.inMilliseconds);
    addIfPresent('route', _routeToJson(route));
    return json;
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return super == other &&
        other is AnimatedMarker &&
        target == other.target &&
        duration == other.duration &&
        route == other.route;
  }

  @override
  String toString() {
    return 'AnimatedMarker{markerId: $markerId, alpha: $alpha, anchor: $anchor, '
        'consumeTapEvents: $consumeTapEvents, draggable: $draggable, flat: $flat, '
        'icon: $icon, infoWindow: $infoWindow, position: $position, rotation: $rotation, '
        'visible: $visible, zIndex: $zIndex, onTap: $onTap, onDragStart: $onDragStart, '
        'onDrag: $onDrag, onDragEnd: $onDragEnd, clusterManagerId: $clusterManagerId, '
        'target: $target, duration: $duration, route: $route}';
  }
}

final double _refreshRate =
    WidgetsBinding.instance.platformDispatcher.views.first.display.refreshRate;

class _MarkerAnimation {
  _MarkerAnimation({
    required this.marker,
    required this.controller,
    required this.onMarkerChanged,
    required this.onAnimationCompleted,
  }) : outgoingPosition = marker.position,
       incomingPosition = marker.target,
       initialDuration = controller.duration ?? defaultDuration,
       duration = controller.duration ?? defaultDuration {
    controller.duration = initialDuration;
    controller.addListener(_onAnimation);
    controller.addStatusListener(_onAnimationStatus);
    controller.forward(from: 0);
  }

  static const Duration defaultDuration = Durations.medium2;
  static const double fps = 30;

  final int maxIt = (_refreshRate / fps).toInt();
  int it = (_refreshRate / fps).toInt();
  final Duration initialDuration;
  AnimatedMarker marker;
  final AnimationController controller;
  LatLng outgoingPosition;
  LatLng incomingPosition;
  List<LatLng> pendingPositions = [];
  Duration duration;
  final void Function(AnimatedMarker) onMarkerChanged;
  final void Function(AnimatedMarker) onAnimationCompleted;

  void dispose() {
    controller.dispose();
  }

  void _updateMarker(AnimatedMarker newMarker) {
    final oldMarker = marker;
    marker = newMarker;
    if (newMarker != oldMarker) {
      if (controller.isAnimating) {
        pendingPositions.add(newMarker.target);
        final double percentRemaining = 1 - controller.value;
        duration =
            newMarker.duration *
            (1 / (percentRemaining + pendingPositions.length));
        controller.animateTo(1.0, duration: duration * percentRemaining);
      } else {
        _animateValueUpdate(incomingPosition, newMarker.target);
      }
    }
  }

  void _onAnimation() {
    if (it == maxIt) {
      final value = controller.value;
      final outgoing = latLngToPoint(outgoingPosition);
      final incoming = latLngToPoint(incomingPosition);
      final point = outgoing + (incoming - outgoing) * value;
      final route = marker.route;
      final position =
          route != null
              ? snapToRoute(pointToLatLng(point), route)
              : pointToLatLng(point);

      marker = marker.copyWith(
        positionParam: position,
        targetParam: incomingPosition,
        durationParam: duration * (1 - value),
      );

      onMarkerChanged(marker);

      it = 0;
    } else {
      it++;
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status.isCompleted) {
      outgoingPosition = incomingPosition;
      if (pendingPositions.isNotEmpty) {
        controller.duration = duration;
        _animateValueUpdate(incomingPosition, pendingPositions.removeAt(0));
      } else {
        controller.duration = initialDuration;
        onAnimationCompleted(
          marker.copyWith(
            positionParam: marker.target,
            durationParam: Duration.zero,
          ),
        );
      }
    }
  }

  void _animateValueUpdate(LatLng outgoing, LatLng incoming) {
    outgoingPosition = outgoing;
    incomingPosition = incoming;
    controller.forward(from: 0);
  }
}

class AnimatedMarkerMapBuilder extends StatefulWidget {
  const AnimatedMarkerMapBuilder({
    super.key,
    required this.builder,
    this.markers = const {},
    this.onMarkerChanged,
  });

  final GoogleMap Function(BuildContext, Set<AnimatedMarker>) builder;
  final Set<Marker> markers;
  final void Function(AnimatedMarker marker)? onMarkerChanged;

  @override
  State<StatefulWidget> createState() => _AnimatedMarkerMapBuilderState();
}

class _AnimatedMarkerMapBuilderState extends State<AnimatedMarkerMapBuilder>
    with TickerProviderStateMixin {
  final Map<MarkerId, _MarkerAnimation> _animations = {};
  final Map<MarkerId, AnimatedMarker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Convert all markers to AnimatedMarkers
    _markers.addEntries(
      widget.markers
          .map(
            (marker) =>
                marker is AnimatedMarker
                    ? marker
                    : AnimatedMarker.from(
                      marker,
                      target: marker.position,
                      duration: Duration.zero,
                    ),
          )
          .map((marker) => MapEntry(marker.markerId, marker)),
    );
    // Create animations for all animating markers
    _animations.addEntries(
      _markers.values
          .where((marker) => marker.duration != Duration.zero)
          .map(
            (marker) => MapEntry(
              marker.markerId,
              _MarkerAnimation(
                marker: marker,
                controller: AnimationController(
                  duration: marker.duration,
                  vsync: this,
                ),
                onMarkerChanged: _onMarkerChanged,
                onAnimationCompleted: _onAnimationCompleted,
              ),
            ),
          ),
    );
  }

  @override
  void dispose() {
    for (final animation in _animations.values) {
      animation.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedMarkerMapBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    final widgetMarkers = widget.markers;
    setState(() {
      // remove markers which are no longer present
      _markers.removeWhere(
        (markerId, marker) => !widgetMarkers.contains(marker),
      );
      // create or update new markers/animations
      for (final marker in widgetMarkers) {
        if (!_markers.containsKey(marker.markerId) ||
            _markers[marker.markerId] != marker) {
          _markers[marker.markerId] =
              marker is AnimatedMarker
                  ? marker
                  : AnimatedMarker.from(
                    marker,
                    target: marker.position,
                    duration: Duration.zero,
                  );
        }
        if (marker is AnimatedMarker && marker.duration != Duration.zero) {
          final animation = _animations[marker.markerId];
          if (animation == null) {
            _animations[marker.markerId] = _MarkerAnimation(
              marker: marker,
              controller: AnimationController(
                duration: marker.duration,
                vsync: this,
              ),
              onMarkerChanged: _onMarkerChanged,
              onAnimationCompleted: _onAnimationCompleted,
            );
          } else if (marker != animation.marker) {
            animation._updateMarker(marker);
          }
        }
      }
    });
  }

  void _onMarkerChanged(AnimatedMarker marker) {
    setState(() {
      _markers[marker.markerId] = marker;
      widget.onMarkerChanged?.call(marker);
    });
  }

  void _onAnimationCompleted(AnimatedMarker marker) {
    _animations.remove(marker.markerId)?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
        _animations.values.map(
          (a) => a.controller.drive(Tween(begin: 0.0, end: 1.0)),
        ),
      ),
      builder: (context, _) => widget.builder(context, Set.of(_markers.values)),
    );
  }
}
