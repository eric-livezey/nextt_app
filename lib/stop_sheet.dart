import 'package:flutter/material.dart' hide Route;
import 'package:nextt_app/api.dart'
    show
        OccupancyStatus,
        Prediction,
        Route,
        Schedule,
        Stop,
        Vehicle,
        VehicleStopStatus;
import 'package:nextt_app/duration_tile.dart' show DurationTile;
import 'package:nextt_app/stream.dart'
    show ResourceFilter, ResourceStream, ResourceType;

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
    required this.predictionId,
    required this.vehicleId,
    required this.routeId,
    this.scheduleId,
    required this.directionId,
    required this.arrivalTime,
    this.departureTime,
    required this.icon,
    required this.routeBadge,
    this.label,
    this.status,
    this.delay,
  });

  final String predictionId;
  final String vehicleId;
  final String routeId;
  final String? scheduleId;
  final int directionId;
  final DateTime arrivalTime;
  final DateTime? departureTime;
  final IconData icon;
  final RouteBadge routeBadge;
  final String? label;
  final VehicleStopStatus? status;
  Duration? delay;

  factory VehiclePrediction.from(
    Prediction prediction,
    Vehicle vehicle,
    Route route,
    Schedule? schedule,
  ) {
    return VehiclePrediction(
      predictionId: prediction.id,
      vehicleId: vehicle.id,
      routeId: route.id,
      scheduleId: prediction.scheduleId,
      directionId: prediction.directionId!,
      arrivalTime: prediction.arrivalTime!,
      departureTime: prediction.departureTime,
      icon: route.iconData,
      routeBadge: RouteBadge.fromRoute(route),
      label: vehicle.label,
      status: vehicle.currentStatus,
      delay: schedule?.arrivalTime?.difference(prediction.arrivalTime!),
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
    this.name,
    this.routeBadge,
    this.occupancyStatus,
    this.stopStatus,
    this.delay,
    required this.destination
  });

  final Icon icon;
  final DateTime arrivalTime;
  final String? name;
  final RouteBadge? routeBadge;
  final OccupancyStatus? occupancyStatus;
  final VehicleStopStatus? stopStatus;
  final int? delay;
  final String destination;

  @override
  Widget build(BuildContext context) {
    final List<Widget> titleWidgets = [];
    if (routeBadge != null) {
      titleWidgets.add(routeBadge!);
    }
    if (name != null) {
      titleWidgets.add(Text(name!));
    }
    final List<Widget> statusWidgets = [];
    if (stopStatus != null) {
      statusWidgets.addAll([
        Text(_resolveStopStatusText(stopStatus!)),
        // Text(' • '),
      ]);
    }
    // if (delay == null) {
    //   statusWidgets.add(const Text('Unscheduled'));
    // } else if (delay == 0) {
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
        child: Row(children: titleWidgets),
      ),
      subtitle: Column(
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: statusWidgets,
            ),
            Row (
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [Text(destination)]
            )
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
    required this.stream,
    this.isTempStream = false,
  });

  final String stopId;
  final Set<String> routeIds;
  final ResourceStream stream;
  final bool isTempStream;

  factory StopSheet.fromStopId(String stopId, Iterable<String> routeIds) {
    final Set<String> routeIdSet = routeIds.toSet();
    final ResourceStream stream = ResourceStream(
      ResourceFilter(
        types: const {
          ResourceType.route,
          ResourceType.vehicle,
          ResourceType.stop,
          ResourceType.schedule,
          ResourceType.prediction,
          ResourceType.alert,
        },
        routeIds: routeIdSet,
        stopIds: {stopId},
      ),
    )..connect();
    return StopSheet(
      stopId: stopId,
      routeIds: routeIdSet,
      stream: stream,
      isTempStream: true,
    );
  }

  @override
  State<StatefulWidget> createState() => _StopSheetState();
}

class _StopSheetState extends State<StopSheet> {
  _StopSheetState();

  late Set<String> _stopIds;

  /// store which vehicles are being tracked to avoid duplicates
  final Set<String> _vehicleIds = {};
  final List<VehiclePrediction> _predictions = [];
  Stop get _stop => widget.stream.stops[widget.stopId]!;

  @override
  void initState() {
    super.initState();
    Set<String> stopIds =
        [
          widget.stopId,
        ].followedBy(_stop.children.map((child) => child.id)).toSet();
    widget.stream
      ..filter.stopIds.addAll(stopIds)
      ..commit();
    _stopIds = stopIds;
    // set initial resources
    _onScheduleReset(widget.stream.schedules.values);
    _onPredictionReset(widget.stream.predictions.values);
    // add listeners
    widget.stream.listen(
      onPredictionReset: _onPredictionReset,
      onPredictionAdd: _onPredictionAdd,
      onPredictionUpdate: _onPredictionUpdate,
      onPredictionRemove: _onPredictionRemove,
      onScheduleReset: _onScheduleReset,
      onScheduleAdd: _onScheduleAdd,
      onScheduleUpdate: _onScheduleUpdate,
      onScheduleRemove: _onScheduleRemove,
    );
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.isTempStream) {
      widget.stream.close();
    } else {
      widget.stream
        ..filter.stopIds.removeAll(
          [widget.stopId].followedBy(_stop.children.map((child) => child.id)),
        )
        ..removeListeners(
          types: [ResourceType.schedule, ResourceType.prediction],
        )
        ..commit();
    }
  }

  void _onScheduleReset(Iterable<Schedule> schedules) {
    _onScheduleAdd(schedules);
  }

  void _onScheduleAdd(Iterable<Schedule> schedules) {
    for (final Schedule schedule in schedules) {
      final int index = _predictions.indexWhere(
        (prediction) => prediction.scheduleId == schedule.id,
      );
      final VehiclePrediction? prediction =
          index >= 0 ? _predictions.elementAtOrNull(index) : null;
      if (prediction != null) {
        prediction.delay = schedule.arrivalTime?.difference(
          prediction.arrivalTime,
        );
      }
    }
  }

  void _onScheduleUpdate(Iterable<Schedule> schedules) {
    _onScheduleAdd(schedules);
  }

  void _onScheduleRemove(Iterable<String> scheduleIds) {
    final Set<String> scheduleIdSet = scheduleIds.toSet();
    for (final VehiclePrediction prediction in _predictions.where((prediction) => scheduleIdSet.contains(prediction.scheduleId))) {
      prediction.delay = null;
    }
  }

  void _onPredictionReset(Iterable<Prediction> predictions) {
    _predictions.clear();
    _onPredictionAdd(predictions);
  }

  void _onPredictionAdd(Iterable<Prediction> predictions) {
    setState(() {
      for (final Prediction prediction in predictions.where(
        (prediction) => _stopIds.contains(prediction.stopId),
      )) {
        _insertPredictionInOrder(prediction);
      }
    });
  }

  void _onPredictionUpdate(List<Prediction> predictions) {
    for (final Prediction prediction in predictions) {
      _onPredictionRemove([prediction.id]);
      setState(() {
        _insertPredictionInOrder(prediction);
      });
    }
  }

  void _onPredictionRemove(Iterable<String> predictionIds) {
    setState(() {
      final Set<String> predictionIdSet = predictionIds.toSet();
      final int index = _predictions.indexWhere(
        (prediction) => predictionIdSet.contains(prediction.predictionId),
      );
      if (index >= 0) {
        final VehiclePrediction prediction = _predictions[index];
        _predictions.removeAt(index);
        _vehicleIds.remove(prediction.vehicleId);
      }
    });
  }

  /// insert prediction in order
  void _insertPredictionInOrder(Prediction prediction) {
    final Vehicle? vehicle =
        prediction.vehicleId != null
            ? widget.stream.vehicles[prediction.vehicleId!]
            : null;
    final Route? route =
        _stop.routeIds.contains(prediction.routeId)
            ? widget.stream.routes[prediction.routeId]
            : null;
    final Schedule? schedule =
        prediction.scheduleId != null
            ? widget.stream.schedules[prediction.scheduleId]
            : null;
    // if the prediction is not missing important fields or related resources
    if (vehicle != null &&
        route != null &&
        prediction.arrivalTime != null &&
        prediction.directionId != null) {
      final VehiclePrediction vp = VehiclePrediction.from(
        prediction,
        vehicle,
        route,
        schedule,
      );
      final int index = _predictions.indexWhere(
        (other) => vp.compareTo(other) <= 0,
      );
      if (!_vehicleIds.contains(vp.vehicleId)) {
        _vehicleIds.add(vp.vehicleId);
        if (index >= 0) {
          _predictions.insert(index, vp);
        } else {
          _predictions.add(vp);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        color: Theme.of(context).cardColor,
        padding: const EdgeInsets.all(16),
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
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _stop.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Tabs
            DefaultTabController(
              length: 2,
              child: Column(
                children: <Widget>[
                  // Tab Bar
                  TabBar(
                    tabs:
                        const {'Inbound', 'Outbound'}
                            .map((directionName) => Tab(text: directionName))
                            .toList(),
                  ),
                  // Tab Content
                  Container(
                    height: 300,
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TabBarView(
                      children:
                          const {0, 1}
                              .map(
                                (directionId) => SizedBox(
                                  height: 150,
                                  child: ListView(
                                    children:
                                        _predictions
                                            .where(
                                              (prediction) =>
                                                  prediction.directionId ==
                                                  directionId,
                                            )
                                            .map((prediction) {
                                              return VehicleListTile(
                                                icon: Icon(prediction.icon),
                                                arrivalTime:
                                                    prediction.arrivalTime,
                                                name: prediction.label,
                                                routeBadge:
                                                    prediction.routeBadge,
                                                delay:
                                                    prediction.delay?.inMinutes,
                                                stopStatus: prediction.status,
                                                destination: widget.stream.routes[prediction.routeId]!.directionDestinations![prediction.directionId],
                                              );
                                            })
                                            .toList(),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
