import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/movement/movement.dart';

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
}
