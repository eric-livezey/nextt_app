import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:nextt_app/api.dart'
    show Prediction, Resource, Route, RouteType, Schedule, Stop, Vehicle;
import 'package:web_socket_channel/web_socket_channel.dart'
    show WebSocketChannel;

// Temporary URI
final Uri websocketUri = Uri(scheme: 'ws', host: '10.220.48.56', port: 3000);

/// JSON constructors for each resource
const Map<ResourceType, Resource Function(Object)?> jsonConstructors = {
  ResourceType.route: Route.fromJson,
  ResourceType.vehicle: Vehicle.fromJson,
  ResourceType.stop: Stop.fromJson,
  ResourceType.schedule: Schedule.fromJson,
  ResourceType.prediction: Prediction.fromJson,
  ResourceType.alert: null,
};

enum EventType {
  reset,
  add,
  update,
  remove;

  factory EventType.fromJson(Object json) {
    String value = json as String;
    return switch (value) {
      'reset' => reset,
      'add' => add,
      'update' => update,
      'remove' => remove,
      _ => throw AssertionError('$value is not a valid event type.'),
    };
  }
}

enum ResourceType {
  route,
  vehicle,
  stop,
  schedule,
  prediction,
  alert;

  factory ResourceType.fromJson(Object json) {
    String value = json as String;
    return switch (value) {
      'route' => route,
      'vehicle' => vehicle,
      'stop' => stop,
      'schedule' => schedule,
      'prediction' => prediction,
      'alert' => alert,
      _ => throw AssertionError('$value is not a valid resource type.'),
    };
  }
}

Object _routeTypeToJson(RouteType value) {
  return switch (value) {
    RouteType.lightRail => 0,
    RouteType.heavyRail => 1,
    RouteType.commuterRail => 2,
    RouteType.bus => 3,
    RouteType.ferry => 4,
  };
}

Object _resourceTypeToJson(ResourceType value) {
  return switch (value) {
    ResourceType.route => 'route',
    ResourceType.vehicle => 'vehicle',
    ResourceType.stop => 'stop',
    ResourceType.schedule => 'schedule',
    ResourceType.prediction => 'prediction',
    ResourceType.alert => 'alert',
  };
}

List<T> _fromJsonList<T>(Object json, T Function(Object) fromJson) {
  final List jsonList = json as List;
  return jsonList.map((json) => fromJson(json)).toList();
}

void _applyIfPresent(Function? func, List args) {
  if (func != null) {
    Function.apply(func, args);
  }
}

String _idFromJson(Object json) {
  Map<String, dynamic> jsonMap = json as Map<String, dynamic>;
  return jsonMap['id'] as String;
}

Object? _payloadFromJson(ResourceType type, EventType event, Object json) {
  Resource Function(Object)? fromJson = jsonConstructors[type];
  if (fromJson != null) {
    switch (event) {
      case EventType.reset:
      case EventType.add:
      case EventType.update:
        return _fromJsonList(json, fromJson);
      case EventType.remove:
        return _fromJsonList(json, _idFromJson);
    }
  }
  return null;
}

class ResourceFilter {
  ResourceFilter({
    required this.types,
    this.routeIds,
    this.routeTypes,
    this.stopIds = const {},
  });

  /// Resource types to be tracked.
  final Set<ResourceType> types;

  /// Route IDs which should be tracked.
  Set<String>? routeIds;

  /// Route types which should be tracked.
  Set<RouteType>? routeTypes;

  /// Stop IDs which should have predicitions and schedules tracked.
  final Set<String> stopIds;

  Object toJson() {
    final Map<String, Object> json = <String, Object>{};

    void addIfPresent(String fieldName, Object? value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    json['types'] = types.map((type) => _resourceTypeToJson(type)).toList();
    addIfPresent('routeIds', routeIds?.toList());
    addIfPresent(
      'routeTypes',
      routeTypes?.map((type) => _routeTypeToJson(type)).toList(),
    );
    json['stopIds'] = stopIds.toList();
    return json;
  }
}

class ResourceStream {
  ResourceStream(this.filter);

  WebSocketChannel? _channel;
  ResourceFilter filter;
  final Map<ResourceType, Map<String, Resource>> _cache = {};
  final Map<ResourceType, Map<EventType, void Function(Object)>> _listeners =
      {};
  void Function(ResourceType, EventType, Object)? _onData;
  Function? _onError;
  void Function()? _onDone;
  bool get isOpen => _channel != null;
  Map<String, Route> get routes =>
      _cache[ResourceType.route]?.cast<String, Route>() ?? <String, Route>{};
  Map<String, Vehicle> get vehicles =>
      _cache[ResourceType.vehicle]?.cast<String, Vehicle>() ??
      <String, Vehicle>{};
  Map<String, Stop> get stops =>
      _cache[ResourceType.stop]?.cast<String, Stop>() ?? <String, Stop>{};
  Map<String, Schedule> get schedules =>
      _cache[ResourceType.schedule]?.cast<String, Schedule>() ??
      <String, Schedule>{};
  Map<String, Prediction> get predictions =>
      _cache[ResourceType.prediction]?.cast<String, Prediction>() ??
      <String, Prediction>{};

  /// Creates a new websocket connection.
  ///
  /// If the connection is already open, it will be closed and reopened.
  Future<void> connect() async {
    if (isOpen) {
      await close();
    }
    _channel = WebSocketChannel.connect(websocketUri);
    _channel?.stream.listen(
      _onWebSocketData,
      onError: _onError,
      onDone: _onWebSocketDone,
    );
    await _channel?.ready;
    commit();
  }

  /// Closes the websocket connection if it is open.
  Future<void> close([int closeCode = 1000, String? closeReason]) async {
    await _channel?.sink.close(closeCode, closeReason);
  }

  /// Commit the resource filter if the stream is open.
  void commit() {
    WebSocketChannel? channel = _channel;
    if (channel != null) {
      channel.sink.add(jsonEncode(filter));
    }
  }

  /// Add listeners.
  void listen({
    void Function(ResourceType, EventType, Object)? onData,
    Function? onError,
    void Function()? onDone,
    void Function(List<Route>)? onRouteReset,
    void Function(List<Route>)? onRouteAdd,
    void Function(List<Route>)? onRouteUpdate,
    void Function(List<String>)? onRouteRemove,
    void Function(List<Vehicle>)? onVehicleReset,
    void Function(List<Vehicle>)? onVehicleAdd,
    void Function(List<Vehicle>)? onVehicleUpdate,
    void Function(List<String>)? onVehicleRemove,
    void Function(List<Stop>)? onStopReset,
    void Function(List<Stop>)? onStopAdd,
    void Function(List<Stop>)? onStopUpdate,
    void Function(List<String>)? onStopRemove,
    void Function(List<Schedule>)? onScheduleReset,
    void Function(List<Schedule>)? onScheduleAdd,
    void Function(List<Schedule>)? onScheduleUpdate,
    void Function(List<String>)? onScheduleRemove,
    void Function(List<Prediction>)? onPredictionReset,
    void Function(List<Prediction>)? onPredictionAdd,
    void Function(List<Prediction>)? onPredictionUpdate,
    void Function(List<String>)? onPredictionRemove,
  }) {
    if (onData != null) {
      _onData = onData;
    }
    if (onError != null) {
      _onError = onError;
    }
    if (onDone != null) {
      _onDone = onDone;
    }

    _setEventListener(ResourceType.route, EventType.reset, onRouteReset);
    _setEventListener(ResourceType.route, EventType.add, onRouteAdd);
    _setEventListener(ResourceType.route, EventType.update, onRouteUpdate);
    _setEventListener(ResourceType.route, EventType.remove, onRouteRemove);

    _setEventListener(ResourceType.vehicle, EventType.reset, onVehicleReset);
    _setEventListener(ResourceType.vehicle, EventType.add, onVehicleAdd);
    _setEventListener(ResourceType.vehicle, EventType.update, onVehicleUpdate);
    _setEventListener(ResourceType.vehicle, EventType.remove, onVehicleRemove);

    _setEventListener(ResourceType.stop, EventType.reset, onStopReset);
    _setEventListener(ResourceType.stop, EventType.add, onStopAdd);
    _setEventListener(ResourceType.stop, EventType.update, onStopUpdate);
    _setEventListener(ResourceType.stop, EventType.remove, onStopRemove);

    _setEventListener(
      ResourceType.schedule,
      EventType.reset,
      onScheduleReset,
    );
    _setEventListener(ResourceType.schedule, EventType.add, onScheduleAdd);
    _setEventListener(
      ResourceType.schedule,
      EventType.update,
      onScheduleUpdate,
    );
    _setEventListener(
      ResourceType.schedule,
      EventType.remove,
      onScheduleRemove,
    );

    _setEventListener(
      ResourceType.prediction,
      EventType.reset,
      onPredictionReset,
    );
    _setEventListener(ResourceType.prediction, EventType.add, onPredictionAdd);
    _setEventListener(
      ResourceType.prediction,
      EventType.update,
      onPredictionUpdate,
    );
    _setEventListener(
      ResourceType.prediction,
      EventType.remove,
      onPredictionRemove,
    );
  }

  /// Remove listeners
  void removeListeners({
    required Iterable<ResourceType> types,
    Iterable<EventType>? events,
  }) {
    events ??= EventType.values;
    for (final ResourceType type in types) {
      for (final event in events) {
        _setEventListener(type, event, null, true);
      }
    }
  }

  void _setEventListener<T>(
    ResourceType type,
    EventType event,
    void Function(List<T>)? listener, [
    bool? eject,
  ]) {
    if (listener != null) {
      final Map<EventType, void Function(Object)> map =
          _listeners[type] ?? (_listeners[type] = {});
      map[event] = (Object data) {
        if (data is List) {
          listener(data.cast<T>());
        }
      };
    } else if (eject == true) {
      _listeners[type]?.remove(event);
    }
  }

  void _updateCache(ResourceType type, EventType event, Object payload) {
    final Map<String, Resource> cache = _cache[type] ??= {};
    switch (event) {
      case EventType.reset:
        cache.clear();
        continue add;
      add:
      case EventType.add:
      case EventType.update:
        final List<Resource> resources = payload as List<Resource>;
        for (final Resource resource in resources) {
          cache[resource.id] = resource;
        }
      case EventType.remove:
        final List<String> ids = payload as List<String>;
        for (final String id in ids) {
          cache.remove(id);
        }
    }
  }

  void _onWebSocketData(json) {
    final Map<String, dynamic> jsonMap =
        jsonDecode(json) as Map<String, dynamic>;
    final ResourceType type = ResourceType.fromJson(jsonMap['type']);
    final EventType event = EventType.fromJson(jsonMap['event']);
    final Object data = jsonMap['data'];

    Object? payload = _payloadFromJson(type, event, data);
    if (payload != null) {
      _updateCache(type, event, payload);
      _applyIfPresent(_onData, [event, type, payload]);
      _applyIfPresent(_listeners[type]?[event], [payload]);
    }
  }

  void _onWebSocketDone() {
    _channel = null;
    _applyIfPresent(_onDone, []);
  }
}
