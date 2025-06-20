import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:nextt_app/api.dart' show Route, RouteType, Stop, Vehicle;
import 'package:web_socket_channel/web_socket_channel.dart'
    show WebSocketChannel;

// TODO: replace with production URI
final Uri websocketUri = Uri(scheme: 'ws', host: '10.220.48.189', port: 3000);

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
  stop;

  factory ResourceType.fromJson(Object json) {
    String value = json as String;
    return switch (value) {
      'route' => route,
      'vehicle' => vehicle,
      'stop' => stop,
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
  };
}

List<T> Function(Object) _fromJsonList<T>(T Function(Object) fromJson) {
  return (Object json) {
    List jsonList = json as List;
    return jsonList.map((json) => fromJson(json)).toList();
  };
}

void _applyIfPresent(Function? func, List args) {
  if (func != null) {
    Function.apply(func, args);
  }
}

void _applyFromJson<T>(
  void Function(T) func,
  Object json, [
  T Function(Object)? fromJson,
]) {
  final T arg = fromJson != null ? fromJson(json) : json as T;
  func(arg);
}

void Function(Object)? _createListenerIfPresent<T>(
  void Function(T)? func,
  void Function(void Function(T), Object json, [T Function(Object)? fromJson])
  apply, [
  T Function(Object)? fromJson,
]) {
  if (func != null) {
    return (Object json) => apply(func, json, fromJson);
  }
  return null;
}

String _idFromJson(Object json) {
  Map<String, dynamic> jsonMap = json as Map<String, dynamic>;
  return jsonMap['id'] as String;
}

class ResourceFilter {
  const ResourceFilter({required this.types, this.routeIds, this.routeTypes});

  final Set<ResourceType> types;
  final Set<String>? routeIds;
  final Set<RouteType>? routeTypes;

  Object toJson() {
    final Map<String, Object> json = <String, Object>{};

    void addIfPresent(String fieldName, Object? value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent(
      'types',
      types.map((type) => _resourceTypeToJson(type)).toList(),
    );
    addIfPresent('routeIds', routeIds?.toList());
    addIfPresent(
      'routeTypes',
      routeTypes?.map((type) => _routeTypeToJson(type)).toList(),
    );
    return json;
  }
}

class ResourceStream {
  ResourceStream(this.filter);

  WebSocketChannel? _channel;
  ResourceFilter filter;
  void Function(EventType, ResourceType, Object)? _onData;
  Function? _onError;
  void Function()? _onDone;
  void Function(Object)? _onRouteReset;
  void Function(Object)? _onRouteAdd;
  void Function(Object)? _onRouteUpdate;
  void Function(Object)? _onRouteRemove;
  void Function(Object)? _onVehicleReset;
  void Function(Object)? _onVehicleAdd;
  void Function(Object)? _onVehicleUpdate;
  void Function(Object)? _onVehicleRemove;
  void Function(Object)? _onStopReset;
  void Function(Object)? _onStopAdd;
  void Function(Object)? _onStopUpdate;
  void Function(Object)? _onStopRemove;
  bool get isOpen => _channel != null;

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
    await commit();
  }

  /// Closes the websocket connection if it is open.
  Future<void> close([int closeCode = 1000, String? closeReason]) async {
    await _channel?.sink.close(closeCode);
  }

  /// Commit the resource filter if the stream is open.
  Future<void> commit() async {
    _channel?.sink.add(jsonEncode(filter));
  }

  /// Set listeners.
  void listen({
    void Function(EventType, ResourceType, Object)? onData,
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
    _onRouteReset = _createListenerIfPresent(
      onRouteReset,
      _applyFromJson<List<Route>>,
      _fromJsonList(Route.fromJson),
    );
    _onRouteAdd = _createListenerIfPresent(
      onRouteAdd,
      _applyFromJson<Route>,
      Route.fromJson,
    );
    _onRouteUpdate = _createListenerIfPresent(
      onRouteUpdate,
      _applyFromJson<Route>,
      Route.fromJson,
    );
    _onRouteRemove = _createListenerIfPresent(
      onRouteRemove,
      _applyFromJson<String>,
      _idFromJson,
    );
    _onVehicleReset = _createListenerIfPresent(
      onVehicleReset,
      _applyFromJson<List<Vehicle>>,
      _fromJsonList(Vehicle.fromJson),
    );
    _onVehicleAdd = _createListenerIfPresent(
      onVehicleAdd,
      _applyFromJson<Vehicle>,
      Vehicle.fromJson,
    );
    _onVehicleUpdate = _createListenerIfPresent(
      onVehicleUpdate,
      _applyFromJson<Vehicle>,
      Vehicle.fromJson,
    );
    _onVehicleRemove = _createListenerIfPresent(
      onVehicleRemove,
      _applyFromJson<String>,
      _idFromJson,
    );
    _onStopReset = _createListenerIfPresent(
      onStopReset,
      _applyFromJson<List<Stop>>,
      _fromJsonList(Stop.fromJson),
    );
    _onStopAdd = _createListenerIfPresent(
      onStopAdd,
      _applyFromJson<Stop>,
      Stop.fromJson,
    );
    _onStopUpdate = _createListenerIfPresent(
      onStopUpdate,
      _applyFromJson<Stop>,
      Stop.fromJson,
    );
    _onStopRemove = _createListenerIfPresent(
      onStopRemove,
      _applyFromJson<String>,
      _idFromJson,
    );
  }

  void _onWebSocketData(json) {
    final Map<String, dynamic> jsonMap =
        jsonDecode(json) as Map<String, dynamic>;
    final EventType event = EventType.fromJson(jsonMap['event']);
    final ResourceType type = ResourceType.fromJson(jsonMap['type']);
    final Object data = jsonMap['data'];

    _applyIfPresent(_onData, [event, type, data]);
    Function? func = switch (type) {
      ResourceType.route => switch (event) {
        EventType.reset => _onRouteReset,
        EventType.add => _onRouteAdd,
        EventType.update => _onRouteUpdate,
        EventType.remove => _onRouteRemove,
      },
      ResourceType.vehicle => switch (event) {
        EventType.reset => _onVehicleReset,
        EventType.add => _onVehicleAdd,
        EventType.update => _onVehicleUpdate,
        EventType.remove => _onVehicleRemove,
      },
      ResourceType.stop => switch (event) {
        EventType.reset => _onStopReset,
        EventType.add => _onStopAdd,
        EventType.update => _onStopUpdate,
        EventType.remove => _onStopRemove,
      },
    };
    _applyIfPresent(func, [data]);
  }

  void _onWebSocketDone() {
    _channel = null;
    if (_onDone != null) {
      _onDone!();
    }
  }
}
