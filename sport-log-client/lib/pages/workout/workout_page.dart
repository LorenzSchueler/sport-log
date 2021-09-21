import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/all.dart';
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
              showDialog<void>(
                  context: context, builder: _movementPickerBuilder);
            },
            icon: Icon(_selectedMovement != null
                ? Icons.filter_alt
                : Icons.filter_alt_outlined),
          ),
        ],
        bottom: _filter,
      ),
      body: WideScreenFrame(child: _mainPage),
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
          movement: _selectedMovement,
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
                showDialog<void>(context: context, builder: _datePickerBuilder);
              },
            ),
            IconButton(
              color: onAppBar,
              onPressed: _dateFilter.goingForwardPossible
                  ? () {
                      setState(() {
                        _dateFilter.goForwardInTime();
                      });
                    }
                  : null,
              icon: const Icon(Icons.arrow_forward_ios_sharp),
            ),
          ],
        ));
  }

  Widget _datePickerBuilder(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: TimeFrame.values.map((timeFrame) {
            final selected = timeFrame == _dateFilter.timeFrame;
            return ListTile(
              title: Center(child: Text(timeFrame.toDisplayName())),
              onTap: () {
                setState(() {
                  _dateFilter.setTimeFrame(timeFrame);
                });
                Navigator.of(context).pop();
              },
              selected: selected,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _movementPickerBuilder(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 0,
        child: FutureBuilder<List<Movement>>(
          future: _movementDataProvider.getNonDeleted(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('Nothing here. Create a movement first.'));
              }
              return ListView.separated(
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final movement = snapshot.data![index];
                  final selected = _selectedMovement != null &&
                      _selectedMovement!.id == movement.id;
                  return ListTile(
                      title: Center(child: Text(movement.name)),
                      selected: selected,
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selectedMovement = null;
                          } else {
                            _selectedMovement = movement;
                          }
                          Navigator.of(context).pop();
                        });
                      });
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: snapshot.data!.length,
              );
            } else if (snapshot.hasError) {
              Future(() =>
                  showSimpleSnackBar(context, 'Failed to select movements.'));
              return const Center(child: Text('Nothing here'));
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
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
