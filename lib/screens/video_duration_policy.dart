/// SRS FR-007 duration requirement; no maximum duration is specified.
class VideoDurationPolicy {
  static const minimum = Duration(seconds: 10);
  static bool isSatisfied(Duration duration) => duration >= minimum;
}

String formatVideoDuration(Duration duration) {
  final seconds = duration.isNegative ? 0 : duration.inSeconds;
  final minutes = (seconds ~/ 60) % 60;
  final remainder = seconds % 60;
  final hours = seconds ~/ 3600;
  final tail =
      '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  return hours > 0 ? '$hours:$tail' : tail;
}
