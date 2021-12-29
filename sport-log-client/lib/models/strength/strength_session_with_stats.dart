import 'package:fixnum/fixnum.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/strength_session_stats.dart';

import 'strength_session.dart';

class StrengthSessionWithStats {
  StrengthSessionWithStats({
    required this.session,
    required this.movement,
    required this.stats,
  });

  final StrengthSession session;
  final Movement movement;
  final StrengthSessionStats stats;

  Int64 get id => session.id;
}
