import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:nextt_app/api.dart'
    show Route, RouteType, Stop, Vehicle, Resource;
import 'package:web_socket_channel/web_socket_channel.dart'
    show WebSocketChannel;

// Temporary URI
final Uri websocketUri = Uri(scheme: 'ws', host: '10.220.48.182', port: 3000);

/// JSON constructors for each resource
const Map<ResourceType, Resource Function(Object)?> jsonConstructors = {
  ResourceType.route: Route.fromJson,
  ResourceType.vehicle: Vehicle.fromJson,
  ResourceType.stop: Stop.fromJson,
  ResourceType.schedule: null,
  ResourceType.prediction: null,
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
        return _fromJsonList(json, fromJson);
      case EventType.add:
      case EventType.update:
        return fromJson(json);
      case EventType.remove:
        return _idFromJson(json);
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
  List<Route> get routes =>
      _cache[ResourceType.route]?.values.toList() as List<Route>? ?? [];
  List<Vehicle> get vehicles =>
      _cache[ResourceType.vehicle]?.values.toList() as List<Vehicle>? ?? [];
  List<Stop> get stops =>
      _cache[ResourceType.stop]?.values.toList() as List<Stop>? ?? [];

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
    await _channel?.sink.close(closeCode);
  }

  /// Commit the resource filter if the stream is open.
  void commit() {
    WebSocketChannel? channel = _channel;
    if (channel != null) {
      channel.sink.add(jsonEncode(filter));
    }
  }

  /// Set listeners.
  void listen({
    void Function(ResourceType, EventType, Object)? onData,
    Function? onError,
    void Function()? onDone,
    void Function(List<Route>)? onRouteReset,
    void Function(Route)? onRouteAdd,
    void Function(Route)? onRouteUpdate,
    void Function(String)? onRouteRemove,
    void Function(List<Vehicle>)? onVehicleReset,
    void Function(Vehicle)? onVehicleAdd,
    void Function(Vehicle)? onVehicleUpdate,
    void Function(String)? onVehicleRemove,
    void Function(List<Stop>)? onStopReset,
    void Function(Stop)? onStopAdd,
    void Function(Stop)? onStopUpdate,
    void Function(String)? onStopRemove,
  }) {
    _onData = onData;
    _onError = onError;
    _onDone = onDone;
    _setResetListener(ResourceType.route, onRouteReset);
    _setListener(ResourceType.route, EventType.add, onRouteAdd);
    _setListener(ResourceType.route, EventType.update, onRouteUpdate);
    _setListener(ResourceType.route, EventType.remove, onRouteRemove);
    _setResetListener(ResourceType.vehicle, onVehicleReset);
    _setListener(ResourceType.vehicle, EventType.add, onVehicleAdd);
    _setListener(ResourceType.vehicle, EventType.update, onVehicleUpdate);
    _setListener(ResourceType.vehicle, EventType.remove, onVehicleRemove);
    _setResetListener(ResourceType.stop, onStopReset);
    _setListener(ResourceType.stop, EventType.add, onStopAdd);
    _setListener(ResourceType.stop, EventType.update, onStopUpdate);
    _setListener(ResourceType.stop, EventType.remove, onStopRemove);
  }

  void _setListener<T extends Object>(
    ResourceType type,
    EventType event,
    void Function(T)? listener,
  ) {
    if (listener != null) {
      final Map<EventType, void Function(Object)> map =
          _listeners[type] ?? (_listeners[type] = {});
      map[event] = (Object data) {
        listener(data as T);
      };
    } else {
      _listeners[type]?.remove(event);
    }
  }

  void _setResetListener<T extends Resource>(
    ResourceType type,
    void Function(List<T>)? listener,
  ) {
    EventType event = EventType.reset;
    if (listener != null) {
      final Map<EventType, void Function(Object)> map =
          _listeners[type] ?? (_listeners[type] = {});
      map[event] = (Object data) {
        if (data is List) {
          listener(data.cast<T>());
        }
      };
    } else {
      _listeners[type]?.remove(event);
    }
  }

  void _updateCache(ResourceType type, EventType event, Object payload) {
    final Map<String, Resource> cache = _cache[type] ?? (_cache[type] = {});
    switch (event) {
      case EventType.reset:
        cache.clear();
        List<Resource> resources = payload as List<Resource>;
        for (Resource resource in resources) {
          cache[resource.id] = resource;
        }
        break;
      case EventType.add:
      case EventType.update:
        Resource resource = payload as Resource;
        cache[resource.id] = resource;
        break;
      case EventType.remove:
        cache.remove(payload as String);
        break;
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
