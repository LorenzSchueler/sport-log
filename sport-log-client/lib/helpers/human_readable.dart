

String formatDuration(Duration d) {
  String result = '';
  final int days = d.inDays;
  if (days >= 1) {
    result += '${days}d';
  }
  final int hours = d.inHours % 24;
  if (hours != 0) {
    result += '${hours}h';
  }
  final int minutes = d.inMinutes % 60;
  if (minutes != 0) {
    result += '${minutes}m';
  }
  final int seconds = d.inSeconds % 60;
  if (seconds != 0) {
    result += '${seconds}s';
  }
  return result;
}