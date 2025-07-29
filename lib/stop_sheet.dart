import 'package:flutter/material.dart' hide Route;
import 'package:nextt_app/api.dart'
    show
        Alert,
        OccupancyStatus,
        Prediction,
        Route,
        Schedule,
        Stop,
        Vehicle,
        VehicleStopStatus;
import 'package:nextt_app/device-storage-services.dart';
import 'package:nextt_app/duration_tile.dart' show DurationTile;
import 'package:nextt_app/stream.dart'
    show ResourceFilter, ResourceStream, ResourceType;

/// IDs of routes which are able to have favorited stops.
const Set<String> favoritableRoutes = {
  'Green-B',
  'Green C',
  'Green D',
  'Green E',
  'Orange',
  'Blue',
  'Red Line - Braintree/Ashmont',
  'Mattapan',
};

String _resolveStopStatusText(VehicleStopStatus status) {
  return switch (status) {
    VehicleStopStatus.incomingAt => 'Incoming',
    VehicleStopStatus.stoppedAt => 'Stopped',
    VehicleStopStatus.inTransitTo => 'In transit',
  };
}

/// Represents a vehicle prediction on a route towards a stop.
class VehiclePrediction implements Comparable<VehiclePrediction> {
  VehiclePrediction({
    this.predictionId,
    this.scheduleId,
    this.vehicleId,
    required this.directionId,
    this.direction,
    this.destination,
    required this.arrivalTime,
    this.departureTime,
    required this.icon,
    required this.routeBadge,
    this.label,
    this.status,
    this.delay,
  });

  final String? predictionId;
  final String? scheduleId;
  final String? vehicleId;
  final int directionId;
  final String? direction;
  final String? destination;
  final DateTime arrivalTime;
  final DateTime? departureTime;
  final IconData icon;
  final RouteBadge routeBadge;
  final String? label;
  final String? status;
  Duration? delay;

  factory VehiclePrediction.fromPrediction({
    required Prediction prediction,
    required Route route,
    required Vehicle vehicle,
    Schedule? schedule,
  }) {
    final int directionId = prediction.directionId!;
    return VehiclePrediction(
      predictionId: prediction.id,
      vehicleId: vehicle.id,
      directionId: prediction.directionId!,
      direction: route.directionNames?[directionId],
      destination: route.directionDestinations?[directionId],
      arrivalTime: prediction.arrivalTime!,
      departureTime: prediction.departureTime,
      icon: route.iconData,
      routeBadge: RouteBadge.fromRoute(route),
      label: vehicle.label,
      status:
          vehicle.currentStatus != null
              ? _resolveStopStatusText(vehicle.currentStatus!)
              : null,
      delay: schedule?.arrivalTime?.difference(prediction.arrivalTime!),
    );
  }

  factory VehiclePrediction.fromSchedule({
    required Schedule schedule,
    required Route route,
  }) {
    final int directionId = schedule.directionId!;
    return VehiclePrediction(
      scheduleId: schedule.id,
      directionId: schedule.directionId!,
      direction: route.directionNames?[directionId],
      destination: route.directionDestinations?[directionId],
      arrivalTime: schedule.arrivalTime!,
      departureTime: schedule.departureTime,
      status: 'Scheduled',
      icon: route.iconData,
      routeBadge: RouteBadge.fromRoute(route),
    );
  }

  @override
  int compareTo(VehiclePrediction other) {
    int value = arrivalTime.compareTo(other.arrivalTime);
    if (value != 0) {
      return value;
    }
    return departureTime == null || other.departureTime == null
        ? 0
        : departureTime!.compareTo(other.departureTime!);
  }
}

class AlertBox extends StatelessWidget {
  const AlertBox({
    super.key,
    required this.shortText,
    this.longText,
    this.onCaretTap,
  });

  final String shortText;
  final String? longText;
  final VoidCallback? onCaretTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          longText != null
              ? () {
                showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text('Details'),
                        content: Text(longText!),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                        scrollable: true,
                      ),
                );
              }
              : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 32,
              ),
            ),
            Expanded(
              child: Text(
                shortText,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
            if (onCaretTap != null)
              GestureDetector(
                onTap: onCaretTap,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.chevron_right,
                    size: 24,
                    color: Colors.orange,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A badge which represents a route.
class RouteBadge extends StatelessWidget {
  const RouteBadge({
    super.key,
    required this.title,
    required this.backgroundColor,
    required this.textColor,
  });

  final String title;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 4.0, right: 4.0),
      margin: const EdgeInsets.only(right: 10.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Text(title, style: TextStyle(color: textColor)),
    );
  }

  factory RouteBadge.fromRoute(Route route) {
    return RouteBadge(
      title: route.shortName.isNotEmpty ? route.shortName : route.longName,
      backgroundColor: route.color,
      textColor: route.textColor,
    );
  }
}

/// A list tile which represents a vehicle on route to a stop.
class VehicleListTile extends StatelessWidget {
  const VehicleListTile({
    super.key,
    required this.icon,
    required this.arrivalTime,
    this.routeBadge,
    this.occupancyStatus,
    this.vehicleStatus,
    this.delay,
    this.direction,
    this.destination,
  });

  final Icon icon;
  final DateTime arrivalTime;
  final RouteBadge? routeBadge;
  final OccupancyStatus? occupancyStatus;
  final String? vehicleStatus;
  final int? delay;
  final String? direction;
  final String? destination;

  @override
  Widget build(BuildContext context) {
    // if (delay == null || delay == 0) {
    //   statusWidgets.add(const Text('Scheduled'));
    // } else if (delay! > 0) {
    //   statusWidgets.add(
    //     Text(
    //       '${delay!} min delay',
    //       style: TextStyle(color: delay! < 5 ? Colors.orange : Colors.red),
    //     ),
    //   );
    // } else if (delay! < 0) {
    //   statusWidgets.add(
    //     Text(
    //       '${delay!.abs()} min early',
    //       style: const TextStyle(color: Colors.green),
    //     ),
    //   );
    // }
    return ListTile(
      leading: icon,
      title: Align(
        alignment: Alignment.centerLeft,
        child: Row(children: [if (routeBadge != null) routeBadge!]),
      ),
      subtitle: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [if (vehicleStatus != null) Text(vehicleStatus!)],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '${direction ?? ''}${direction != null && destination != null ? ' • ' : ' '}${destination ?? ''}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: DurationTile(arrivalTime),
    );
  }
}

class StopSheet extends StatefulWidget {
  const StopSheet({
    super.key,
    required this.stopId,
    required this.routeIds,
    this.stream,
    this.onFavoritedChange,
  });

  final String stopId;
  final Set<String> routeIds;
  final ResourceStream? stream;
  final void Function(bool)? onFavoritedChange;

  static fromStopId({
    required String stopId,
    required Set<String> routeIds,
    void Function(bool)? onFavoritedChange,
  }) {
    return StopSheet(
      stopId: stopId,
      routeIds: routeIds,
      onFavoritedChange: onFavoritedChange,
    );
  }

  @override
  State<StatefulWidget> createState() => _StopSheetState();
}

class _StopSheetState extends State<StopSheet> {
  _StopSheetState();

  late ResourceStream _stream;
  late bool _isTempStream = false;
  Set<String> _stopIds = {};

  /// store which vehicles are being tracked to avoid duplicates
  final Set<String> _vehicleIds = {};
  final List<VehiclePrediction> _predictions = [];
  final Map<String, Alert> _alerts = {};
  int _selectedAlertIndex = 0;
  Stop? _stop;
  bool? _isFavorited;

  @override
  void initState() {
    super.initState();
    if (widget.stream != null) {
      _stream = widget.stream!;
    } else {
      _stream = ResourceStream(
        ResourceFilter(
          types: const {
            ResourceType.route,
            ResourceType.vehicle,
            ResourceType.stop,
            ResourceType.schedule,
            ResourceType.prediction,
            ResourceType.alert,
          },
          routeIds: widget.routeIds,
          stopIds: {widget.stopId},
        ),
      )..connect();
      _isTempStream = true;
    }
    // set _isFavorited if applicable
    if (widget.routeIds.length == 1) {
      FavoritesService.containsFavorite(
        widget.stopId,
        widget.routeIds.first,
      ).then((value) {
        _isFavorited = value;
      });
    }
    // set initial resources
    _onStopReset(_stream.stops.values);
    _onScheduleReset(_stream.schedules.values);
    _onPredictionReset(_stream.predictions.values);
    // add listeners
    _stream.listen(
      onStopReset: _onStopReset,
      onStopAdd: _onStopAdd,
      onStopUpdate: _onStopUpdate,
      onStopRemove: _onStopRemove,
      onPredictionReset: _onPredictionReset,
      onPredictionAdd: _onPredictionAdd,
      onPredictionUpdate: _onPredictionUpdate,
      onPredictionRemove: _onPredictionRemove,
      onScheduleReset: _onScheduleReset,
      onScheduleAdd: _onScheduleAdd,
      onScheduleUpdate: _onScheduleUpdate,
      onScheduleRemove: _onScheduleRemove,
      onAlertReset: _onAlertReset,
      onAlertAdd: _onAlertAdd,
      onAlertUpdate: _onAlertUpdate,
      onAlertRemove: _onAlertRemove,
    );
  }

  @override
  void dispose() {
    super.dispose();
    if (_isTempStream) {
      // close stream
      _stream.close();
    } else {
      // stop listening and remove filters
      _stream
        ..removeListeners(
          types: [ResourceType.schedule, ResourceType.prediction],
        )
        ..filter.stopIds.removeAll(_stopIds)
        ..commit();
    }
  }

  void _onStopReset(Iterable<Stop> stops) {
    _onStopAdd(stops);
  }

  void _onStopAdd(Iterable<Stop> stops) {
    _onStopUpdate(stops);
  }

  void _onStopUpdate(Iterable<Stop> stops) {
    if (mounted) {
      final Stop? stop =
          (() {
            for (var stop in stops) {
              if (stop.id == widget.stopId) return stop;
            }
            return null;
          })();
      if (stop != null) {
        setState(() {
          _stop = stop;
          final Set<String> stopIds =
              [
                widget.stopId,
              ].followedBy(stop.children.map((child) => child.id)).toSet();
          _stream
            ..filter.stopIds.addAll(stopIds)
            ..commit();
          _stopIds = stopIds;
        });
      }
    }
  }

  void _onStopRemove(Iterable<String> stopIds) {
    if (mounted) {
      if (stopIds.any((stopId) => stopId == widget.stopId)) {
        setState(() {
          _stop = null;
          _stopIds = const {};
        });
      }
    }
  }

  _onAlertReset(Iterable<Alert> alerts) {
    _selectedAlertIndex = 0;
    _alerts.clear();
    _onAlertAdd(alerts);
  }

  _onAlertAdd(Iterable<Alert> alerts) {
    setState(() {
      for (final Alert alert in alerts.where(
        (alert) => alert.informedEntity.any(
          (entity) =>
              _stopIds.contains(entity.stop) &&
              (entity.route == null || widget.routeIds.contains(entity.route)),
        ),
      )) {
        _alerts[alert.id] = alert;
      }
    });
  }

  _onAlertUpdate(Iterable<Alert> alerts) {
    _onAlertAdd(alerts);
  }

  _onAlertRemove(Iterable<String> alertIds) {
    setState(() {
      for (final String alertId in alertIds) {
        if (_alerts.containsKey(alertId)) {
          _alerts.remove(alertId);
        }
      }
      _selectedAlertIndex = 0;
    });
  }

  void _onScheduleReset(Iterable<Schedule> schedules) {
    _onScheduleAdd(schedules);
  }

  void _onScheduleAdd(Iterable<Schedule> schedules) {
    setState(() {
      for (final Schedule schedule in schedules.where(
        (schedule) =>
            _stopIds.contains(schedule.stopId) &&
            widget.routeIds.contains(schedule.routeId),
      )) {
        _insertScheduleInOrder(schedule);
      }
    });
  }

  void _onScheduleUpdate(Iterable<Schedule> schedules) {
    _onScheduleAdd(schedules);
  }

  void _onScheduleRemove(Iterable<String> scheduleIds) {
    setState(() {
      final Set<String> scheduleIdSet = scheduleIds.toSet();
      _predictions.removeWhere(
        (prediction) => scheduleIdSet.contains(prediction.scheduleId),
      );
    });
  }

  void _onPredictionReset(Iterable<Prediction> predictions) {
    _predictions.clear();
    _onPredictionAdd(predictions);
  }

  void _onPredictionAdd(Iterable<Prediction> predictions) {
    setState(() {
      for (final Prediction prediction in predictions.where(
        (prediction) =>
            _stopIds.contains(prediction.stopId) &&
            widget.routeIds.contains(prediction.routeId),
      )) {
        _insertPredictionInOrder(prediction);
      }
    });
  }

  void _onPredictionUpdate(List<Prediction> predictions) {
    setState(() {
      for (final Prediction prediction in predictions) {
        _onPredictionRemove([prediction.id]);
        _insertPredictionInOrder(prediction);
      }
    });
  }

  void _onPredictionRemove(Iterable<String> predictionIds) {
    setState(() {
      final Set<String> predictionIdSet = predictionIds.toSet();
      int index = 0;
      while (index >= 0) {
        index = _predictions.indexWhere(
          (prediction) => predictionIdSet.contains(prediction.predictionId),
          index,
        );
        if (index >= 0) {
          final VehiclePrediction prediction = _predictions[index];
          _predictions.removeAt(index);
          _vehicleIds.remove(prediction.vehicleId);
        }
      }
    });
  }

  /// insert prediction in order
  void _insertPredictionInOrder(Prediction prediction) {
    final Vehicle? vehicle =
        prediction.vehicleId != null
            ? _stream.vehicles[prediction.vehicleId!]
            : null;
    final Route? route =
        _stop?.routeIds.contains(prediction.routeId) ?? false
            ? _stream.routes[prediction.routeId]
            : null;
    final Schedule? schedule =
        prediction.scheduleId != null
            ? _stream.schedules[prediction.scheduleId]
            : null;
    // if the prediction is not missing important fields or related resources
    if (vehicle != null &&
        route != null &&
        prediction.arrivalTime != null &&
        prediction.directionId != null) {
      final VehiclePrediction vp = VehiclePrediction.fromPrediction(
        prediction: prediction,
        route: route,
        vehicle: vehicle,
        schedule: schedule,
      );
      final int index = _predictions.indexWhere(
        (other) => vp.compareTo(other) <= 0,
      );
      if (_vehicleIds.contains(vehicle.id)) {
        _onPredictionRemove([prediction.id]);
      }
      _vehicleIds.add(vehicle.id);
      if (index >= 0) {
        _predictions.insert(index, vp);
      } else {
        _predictions.add(vp);
      }
    }
  }

  /// insert schedule in order
  void _insertScheduleInOrder(Schedule schedule) {
    final Route? route =
        _stop?.routeIds.contains(schedule.routeId) ?? false
            ? _stream.routes[schedule.routeId]
            : null;
    // if the prediction is not missing important fields or related resources
    if (route != null &&
        schedule.arrivalTime != null &&
        schedule.directionId != null) {
      final VehiclePrediction vp = VehiclePrediction.fromSchedule(
        schedule: schedule,
        route: route,
      );
      final int index = _predictions.indexWhere(
        (other) => vp.compareTo(other) <= 0,
      );
      if (index >= 0) {
        _predictions.insert(index, vp);
      } else {
        _predictions.add(vp);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorited = _isFavorited;
    final List<Alert> alerts = _alerts.values.toList();
    final ThemeData theme = Theme.of(context);
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: const Border(top: BorderSide(width: 0.1)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Stop Name
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  _stop?.name ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 40),
                      child: Text(
                        _stop?.name ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                    if (isFavorited != null)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isFavorited = !isFavorited;
                            if (isFavorited) {
                              FavoritesService.removeFavoriteFromMap(
                                widget.stopId,
                                widget.routeIds.first,
                              ).then((_) {
                                if (widget.onFavoritedChange != null) {
                                  widget.onFavoritedChange!(!isFavorited);
                                }
                              });
                            } else {
                              FavoritesService.addFavoriteFromMap(
                                widget.stopId,
                                widget.routeIds.first,
                              ).then((_) {
                                if (widget.onFavoritedChange != null) {
                                  widget.onFavoritedChange!(!isFavorited);
                                }
                              });
                            }
                          });
                        },
                        icon: Icon(
                          isFavorited ? Icons.favorite : Icons.favorite_outline,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            // Alert Box
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child:
                  alerts.isNotEmpty
                      ? AlertBox(
                        shortText: alerts[_selectedAlertIndex].header!,
                        longText: alerts[_selectedAlertIndex].description,
                        onCaretTap:
                            alerts.length > 1
                                ? () {
                                  int index = _selectedAlertIndex + 1;
                                  if (index >= _alerts.length) {
                                    index = 0;
                                  }
                                  setState(() {
                                    _selectedAlertIndex = index;
                                  });
                                }
                                : null,
                      )
                      : null,
            ),
            // Tabs
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(width: 0.1)),
                ),
                child: ListView(
                  children:
                      _predictions
                          .map(
                            (prediction) => Container(
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(width: 0.1)),
                              ),
                              child: VehicleListTile(
                                icon: Icon(prediction.icon),
                                arrivalTime: prediction.arrivalTime,
                                routeBadge: prediction.routeBadge,
                                delay: prediction.delay?.inMinutes,
                                vehicleStatus: prediction.status,
                                direction: prediction.direction,
                                destination: prediction.destination,
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
