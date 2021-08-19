
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:intl/intl.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/strength/all.dart';

class StrengthPage extends StatelessWidget {
  const StrengthPage({Key? key}) : super(key: key);

  Future<void> _reloadStrengthSessions() async {
    throw UnimplementedError();
  }

  bool _areTheSame(
      StrengthSessionDescription ssd1,
      StrengthSessionDescription ssd2
  ) => ssd1.strengthSession.id == ssd2.strengthSession.id;

  @override
  Widget build(BuildContext context) {
    return _buildStrengthSessionList(context, [
      StrengthSessionDescription(
        strengthSession: StrengthSession(id: Int64(1), userId: Int64(1), datetime: DateTime.now(), movementId: Int64(1), movementUnit: MovementUnit.reps, interval: 234, comments: "nada", deleted: false),
        strengthSets: [
          StrengthSet(id: Int64(1), strengthSessionId: Int64(1), setNumber: 1, count: 12, weight: 5.6, deleted: false),
          StrengthSet(id: Int64(2), strengthSessionId: Int64(1), setNumber: 2, count: 11, weight: 5.2, deleted: false),
          StrengthSet(id: Int64(3), strengthSessionId: Int64(1), setNumber: 3, count: 11, weight: 4.9, deleted: false),
        ],
        movement: Movement(id: Int64(1), userId: Int64(1), name: "Squats", description: "bla", category: MovementCategory.strength, deleted: false),
      ),
    ]);
  }

  Widget _buildStrengthSessionList(BuildContext context, List<StrengthSessionDescription> ssds) {
    return RefreshIndicator(
      child: ImplicitlyAnimatedList(
        items: ssds,
        itemBuilder: _buildStrengthSession,
        areItemsTheSame: _areTheSame,
      ),
      onRefresh: _reloadStrengthSessions,
    );
  }

  Widget _buildStrengthSession(
      BuildContext context,
      Animation<double> animation,
      StrengthSessionDescription ssd,
      int i
  ) {
    assert(ssd.isValid());

    final String date = DateFormat('dd.MM.yyyy').format(ssd.strengthSession.datetime);
    final String time = DateFormat('HH:mm').format(ssd.strengthSession.datetime);
    final String sets = '${ssd.strengthSets.length} sets';
    final String title = ssd.movement.name;
    final String text = ssd.strengthSets.map((ss) =>
        ss.toDisplayName(ssd.strengthSession.movementUnit)
    ).join(', ');

    return SizeFadeTransition(
      key: ValueKey(ssd.strengthSession.id),
      animation: animation,
      curve: Curves.easeInOut,
      child: ExpansionTileCard(
        title: Text(title),
        subtitle: Text([date, time, sets].join(' · ')),
        children: [
          const Divider(),
          Text(text),
          const Divider(),
          // TODO: interval + comments
          ButtonBar(
            alignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                  onPressed: () {}, // TODO
                  icon: const Icon(Icons.delete),
              ),
              IconButton(
                onPressed: () {}, // TODO
                icon: const Icon(Icons.edit),
              ),
            ],
          ),
        ],
      ),
    );
  }
}