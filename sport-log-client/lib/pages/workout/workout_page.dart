import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/pages/workout/metcon/metcons_page.dart';
import 'package:sport_log/pages/workout/strength/strength_sessions_page.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/simple_overlay.dart';
import 'package:sport_log/widgets/wide_screen_frame.dart';

import 'date_filter_state.dart';

enum BottomNavPage { metcon, strength, cardio, diary }

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  BottomNavPage _currentPage = BottomNavPage.metcon;
  final DateFilterState _dateFilter =
      DateFilterState(timeFrame: TimeFrame.month, start: DateTime.now());
  bool _showDateFilter = false;

  Movement? _selectedMovement;

  final _movementDataProvider = MovementDataProvider();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedMovement?.name ?? 'Sessions'),
        actions: [
          IconButton(
            onPressed: () async {
              // TODO: doesn't work like that
              final movements = await _movementDataProvider.getNonDeletedFull();
              showDialog<void>(
                  context: context,
                  builder: (context) {
                    return Dialog(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final md = movements[index];
                          final selected = _selectedMovement != null &&
                              _selectedMovement!.id == md.movement.id;
                          return ListTile(
                              title: Text(md.movement.name),
                              trailing:
                                  selected ? const Icon(Icons.check) : null,
                              selected: selected,
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    _selectedMovement = null;
                                  } else {
                                    _selectedMovement = md.movement;
                                  }
                                  Navigator.of(context).pop();
                                });
                              });
                        },
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemCount: movements.length,
                      ),
                    );
                  });
            },
            icon: Icon(_selectedMovement != null
                ? Icons.filter_alt
                : Icons.filter_alt_outlined),
          ),
        ],
        bottom: _filter,
      ),
      body: SimpleOverlay(
        child: WideScreenFrame(child: _mainPage),
        overlay: _overlay,
        hideOverlay: () => setState(() => _showDateFilter = false),
        showOverlay: _showDateFilter,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: BottomNavPage.values.map(_toBottomNavItem).toList(),
        currentIndex: _currentPage.index,
        onTap: _onBottomNavItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
      drawer: const MainDrawer(selectedRoute: Routes.workout),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _onFabTapped(context),
      ),
    );
  }

  Widget get _mainPage {
    // TODO: preserve state and/or widget when changing tab
    switch (_currentPage) {
      case BottomNavPage.metcon:
        return const MetconsPage();
      case BottomNavPage.strength:
        return StrengthSessionsPage(
          start: _dateFilter.start,
          end: _dateFilter.end,
        );
      case BottomNavPage.cardio:
        return const Center(
          child: Text("Cardio"),
        );
      case BottomNavPage.diary:
        return const Center(
          child: Text("Weight and Comments"),
        );
    }
  }

  BottomNavigationBarItem _toBottomNavItem(BottomNavPage page) {
    switch (page) {
      case BottomNavPage.metcon:
        return const BottomNavigationBarItem(
          icon: Icon(CustomIcons.plan),
          label: "Workouts",
        );
      case BottomNavPage.strength:
        return const BottomNavigationBarItem(
          icon: Icon(CustomIcons.dumbbellNotRotated),
          label: "Strength",
        );
      case BottomNavPage.cardio:
        return const BottomNavigationBarItem(
          icon: Icon(CustomIcons.heart),
          label: "Cardio",
        );
      case BottomNavPage.diary:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.edit),
          label: "Other",
        );
    }
  }

  void _onBottomNavItemTapped(int index) {
    setState(() {
      _currentPage = BottomNavPage.values[index];
    });
  }

  void _onFabTapped(BuildContext context) {
    switch (_currentPage) {
      case BottomNavPage.metcon:
        Navigator.of(context).pushNamed(Routes.editMetcon);
        break;
      case BottomNavPage.strength:
        Navigator.of(context).pushNamed(Routes.editStrengthSession);
        break;
      default:
    }
  }

  PreferredSizeWidget get _filter {
    final onAppBar = appBarForegroundOf(context);
    return PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              color: onAppBar,
              onPressed: _dateFilter.timeFrame == TimeFrame.all
                  ? null
                  : () {
                      setState(() {
                        _dateFilter.goBackInTime();
                        _showDateFilter = false;
                      });
                    },
              icon: const Icon(Icons.arrow_back_ios_sharp),
            ),
            TextButton.icon(
              label: Icon(
                Icons.arrow_drop_down_sharp,
                color: onAppBar,
              ),
              icon: Text(
                _dateFilter.getLabel(),
                style: TextStyle(
                  color: onAppBar,
                ),
              ),
              onPressed: () {
                setState(() => _showDateFilter = !_showDateFilter);
              },
            ),
            IconButton(
              color: onAppBar,
              onPressed: _dateFilter.goingForwardPossible
                  ? () {
                      setState(() {
                        _dateFilter.goForwardInTime();
                        _showDateFilter = false;
                      });
                    }
                  : null,
              icon: const Icon(Icons.arrow_forward_ios_sharp),
            ),
          ],
        ));
  }

  Widget get _overlay {
    final appBarColor = Theme.of(context).cardColor;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 23),
        child: Material(
          color: appBarColor,
          clipBehavior: Clip.none,
          elevation: 3,
          shape: const _CustomDateShape(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Container(
            width: 200,
            child: ListView.separated(
              shrinkWrap: true,
              itemBuilder: (context, index) => ListTile(
                title: Center(
                    child: Text(TimeFrame.values[index].toDisplayName())),
                onTap: () {
                  setState(() {
                    _dateFilter.setTimeFrame(TimeFrame.values[index]);
                    _showDateFilter = false;
                  });
                },
              ),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: TimeFrame.values.length,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomDateShape extends RoundedRectangleBorder {
  const _CustomDateShape({
    BorderSide side = BorderSide.none,
    BorderRadiusGeometry borderRadius = BorderRadius.zero,
  }) : super(side: side, borderRadius: borderRadius);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..moveTo(rect.width / 2 - 15, rect.top)
      ..lineTo(rect.width / 2, rect.top - 20)
      ..lineTo(rect.width / 2 + 15, rect.top)
      ..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  }
}
