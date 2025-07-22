import 'dart:async' show Timer;

import 'package:flutter/material.dart';

const Duration _oneSecond = Duration(seconds: 1);
const Duration _oneMinute = Duration(minutes: 1);

/// Represents a tile which displays a duration in real time.
class DurationTile extends StatefulWidget {
  const DurationTile(this.endTime, {super.key, this.includeSeconds = false});

  final DateTime endTime;
  final bool includeSeconds;

  @override
  State<StatefulWidget> createState() => _DurationTileState();
}

class _DurationTileState extends State<DurationTile> {
  late final TimeOfDay _endTime;
  Timer? _timer;
  late Duration _tickDuration;
  late Duration _duration;

  @override
  void initState() {
    super.initState();
    _endTime = TimeOfDay.fromDateTime(widget.endTime.toLocal());
    // set timer
    final Duration duration = _duration = _getDuration();
    if (duration != Duration.zero) {
      late final int delayMilliseconds;
      late final Duration tickDuration;
      if (!widget.includeSeconds ||
          duration.inSeconds > Duration.secondsPerMinute) {
        // tick every minute
        delayMilliseconds =
            duration.inMilliseconds % Duration.millisecondsPerMinute;
        tickDuration = _oneMinute;
      } else {
        // tick every second
        delayMilliseconds =
            duration.inMilliseconds % Duration.millisecondsPerSecond;
        tickDuration = _oneSecond;
      }
      _setTimer(Duration(milliseconds: delayMilliseconds), tickDuration);
    }
  }

  @override
  void dispose() {
    super.dispose();
    // cancel timer if active
    if (_timer?.isActive == true) {
      _timer?.cancel();
    }
  }

  Future<void> _setTimer(Duration delay, Duration tickDuration) {
    _tickDuration = tickDuration;
    // create timer after delay
    return Future.delayed(delay, () {
      if (mounted) {
        _handleTick(_timer = Timer.periodic(tickDuration, _handleTick));
      }
    });
  }

  Duration _getDuration() {
    final int milliseconds =
        widget.endTime.millisecondsSinceEpoch -
        DateTime.now().millisecondsSinceEpoch;
    return milliseconds > 0
        ? Duration(milliseconds: milliseconds)
        : Duration.zero;
  }

  void _handleTick(Timer timer) {
    Duration duration = _getDuration();
    if (duration == Duration.zero) {
      // stop timer
      timer.cancel();
    } else if (widget.includeSeconds &&
        _tickDuration == _oneMinute &&
        duration.inSeconds <= Duration.secondsPerMinute) {
      // lower tick duration to one second
      timer.cancel();
      _setTimer(
        Duration(
          milliseconds:
              duration.inMilliseconds % Duration.millisecondsPerSecond,
        ),
        _oneSecond,
      );
    }
    setState(() {
      _duration = duration;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Duration duration = _duration;
    final int seconds = duration.inSeconds;
    final int minutes = duration.inMinutes;
    final bool isNow = duration == Duration.zero;
    final bool isInSeconds = widget.includeSeconds && seconds < Duration.secondsPerMinute;
    final bool isInMinutes = minutes < Duration.minutesPerHour;
    final Text title = Text(
      isNow
          ? 'Now'
          : isInMinutes
          ? (isInSeconds ? seconds : minutes < 1 ? '<1' : minutes).toString()
          : _endTime.format(context),
      style: const TextStyle(color: Colors.black, fontSize: 16.0),
    );
    return isNow || !isInMinutes
        ? title
        : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            title,
            Text(
              isInSeconds ? 'sec' : 'min',
              style: const TextStyle(color: Colors.black87, fontSize: 14.0),
            ),
          ],
        );
  }
}
