
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:intl/intl.dart';
import 'package:sport_log/helpers/human_readable.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:faker/faker.dart';

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
    return RefreshIndicator(
      onRefresh: () async {
        // TODO
        return Future.delayed(const Duration(milliseconds: 1000));
      },
      child: _buildStrengthSessionList(context, [
        StrengthSessionDescription(
          strengthSession: StrengthSession(id: Int64(1), userId: Int64(1), datetime: DateTime.now(), movementId: Int64(1), movementUnit: MovementUnit.reps, interval: 234, comments: null, deleted: false),
          strengthSets: [
            StrengthSet(id: Int64(1), strengthSessionId: Int64(1), setNumber: 1, count: 12, weight: 5.6, deleted: false),
            StrengthSet(id: Int64(2), strengthSessionId: Int64(1), setNumber: 2, count: 11, weight: 5.2, deleted: false),
            StrengthSet(id: Int64(3), strengthSessionId: Int64(1), setNumber: 3, count: 11, weight: 4.9, deleted: false),
          ],
          movement: Movement(id: Int64(1), userId: Int64(1), name: "Squats", description: "bla", category: MovementCategory.strength, deleted: false),
        ),
        StrengthSessionDescription(
          strengthSession: StrengthSession(id: Int64(1), userId: Int64(1), datetime: DateTime.now(), movementId: Int64(1), movementUnit: MovementUnit.reps, interval: 234, comments: faker.lorem.sentences(8).join(' '), deleted: false),
          strengthSets: [
            StrengthSet(id: Int64(1), strengthSessionId: Int64(1), setNumber: 1, count: 12, weight: 5.6, deleted: false),
            StrengthSet(id: Int64(2), strengthSessionId: Int64(1), setNumber: 2, count: 11, weight: 5.2, deleted: false),
            StrengthSet(id: Int64(3), strengthSessionId: Int64(1), setNumber: 3, count: 11, weight: 4.9, deleted: false),
          ],
          movement: Movement(id: Int64(1), userId: Int64(1), name: "Squats", description: "bla", category: MovementCategory.strength, deleted: false),
        ),
      ]),
    );
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
    final String? duration = ssd.strengthSession.interval == null
      ? null : formatDuration(Duration(seconds: ssd.strengthSession.interval!));
    final String subtitle = [date, time, sets, if (duration != null) duration]
      .join(' · ');

    final String title = ssd.movement.name;
    final String text = ssd.strengthSets
        .map((ss) => ss.toDisplayName()).join(', ');

    return SizeFadeTransition(
      key: ValueKey(ssd.strengthSession.id),
      animation: animation,
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        child: ExpansionTileCard(
          leading: CircleAvatar(
            child: Text(ssd.movement.name[0])
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          children: [
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(text),
            ),
            const Divider(),
            if (ssd.strengthSession.comments != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(ssd.strengthSession.comments!),
              ),
            if (ssd.strengthSession.comments != null)
              const Divider(),
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
      ),
    );
  }
}