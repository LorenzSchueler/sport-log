import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/routes.dart';

class StrengthSessionDetailsPage extends StatefulWidget {
  const StrengthSessionDetailsPage({
    Key? key,
    required this.id,
  }) : super(key: key);

  final Int64 id;

  @override
  _StrengthSessionDetailsPageState createState() =>
      _StrengthSessionDetailsPageState();
}

class _StrengthSessionDetailsPageState
    extends State<StrengthSessionDetailsPage> {
  late final Future<StrengthSessionWithSets?> _sessionFuture;

  final _dataProvider = StrengthDataProvider.instance;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _dataProvider.getSessionWithSets(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _sessionFuture,
      builder: (context, AsyncSnapshot<StrengthSessionWithSets?> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            if (!snapshot.hasData || snapshot.data == null) {
              return const Scaffold(
                  body: Center(child: Text('Something went wrong.')));
            }
            return _page(snapshot.data!);
          default:
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
        }
      },
    );
  }

  Widget _page(StrengthSessionWithSets session) {
    return Scaffold(
      appBar: AppBar(
        title: Text(session.movement.name),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context)
                  .pushNamed(Routes.strength.edit, arguments: session);
            },
            icon: const Icon(Icons.edit_sharp),
          ),
        ],
      ),
      body: Scrollbar(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _mainInfo(session),
              if (session.session.comments != null) _comments(session),
              _setsInfo(session),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mainInfo(StrengthSessionWithSets session) {
    final subtitle = [
      '${session.sets.length} sets',
      if (session.session.interval != null)
        formatDuration(session.session.interval!),
    ].join(' • ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            ListTile(
              title: Text(session.session.datetime.toHumanWithTime()),
              subtitle: Text(subtitle),
            ),
            const Divider(height: 1),
            ..._bestValuesInfo(session),
          ],
        ),
      ),
    );
  }

  List<Widget> _bestValuesInfo(StrengthSessionWithSets session) {
    final stats = session.calculateStats();
    if (stats == null) {
      return [];
    }
    switch (session.movement.dimension) {
      case MovementDimension.reps:
        final maxEorm = stats.maxEorm;
        final maxWeight = stats.maxWeight;
        final sumVolume = stats.sumVolume;
        return [
          if (maxEorm != null)
            ListTile(
              title: Text(roundedWeight(maxEorm)),
              subtitle: const Text('Max Eorm'),
            ),
          if (sumVolume != null)
            ListTile(
              title: Text(roundedWeight(sumVolume)),
              subtitle: const Text('Sum Volume'),
            ),
          if (maxWeight != null)
            ListTile(
              title: Text(roundedWeight(maxWeight)),
              subtitle: const Text('Max Weight'),
            ),
          ListTile(
            title: Text(roundedValue(stats.avgCount)),
            subtitle: const Text('Avg Reps'),
          )
        ];
      case MovementDimension.time:
        return [
          ListTile(
            title: Text(formatDuration(Duration(milliseconds: stats.minCount))),
            subtitle: const Text('Best Time'),
          ),
        ];
      case MovementDimension.distance:
        return [
          ListTile(
            title: Text(formatDistance(stats.maxCount)),
            subtitle: const Text('Best Distance'),
          ),
        ];
      case MovementDimension.energy:
        return [
          ListTile(
            title: Text(stats.sumCount.toString() + 'cals'),
            subtitle: const Text('Total Energy'),
          ),
        ];
    }
  }

  Widget _comments(StrengthSessionWithSets session) {
    assert(session.session.comments != null);
    return Card(
      child: Container(
        padding: const EdgeInsets.all(8),
        width: double.infinity,
        child: ListTile(
          title: const Text('Comments'),
          subtitle: Text(session.session.comments!),
        ),
      ),
    );
  }

  Widget _setsInfo(StrengthSessionWithSets session) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: session.sets.mapToLIndexed((set, index) => ListTile(
                title: Text(
                  set.toDisplayName(session.movement.dimension),
                  style: const TextStyle(fontSize: 20),
                ),
                leading: CircleAvatar(child: Text('${index + 1}')),
              )),
        ),
      ),
    );
  }
}
