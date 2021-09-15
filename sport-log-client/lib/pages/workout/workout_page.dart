import 'package:flutter/material.dart';
import 'package:sport_log/pages/workout/metcon/metcons_page.dart';
import 'package:sport_log/pages/workout/strength/strength_sessions_page.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/simple_overlay.dart';
import 'package:sport_log/widgets/wide_screen_frame.dart';

import 'date_filter_state.dart';

enum BottomNavPage { workout, strength, cardio, other }

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  BottomNavPage _currentPage = BottomNavPage.workout;
  final DateFilterState _dateFilter =
      DateFilterState(timeFrame: TimeFrame.month, start: DateTime.now());
  bool _showDateFilter = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_showDateFilter == true) {
          setState(() => _showDateFilter = false);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Home"),
          bottom: _timeFilter,
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
      ),
    );
  }

  Widget get _mainPage {
    switch (_currentPage) {
      case BottomNavPage.workout:
        return const MetconsPage();
      case BottomNavPage.strength:
        return const StrengthSessionsPage();
      case BottomNavPage.cardio:
        return const Center(
          child: Text("Cardio"),
        );
      case BottomNavPage.other:
        return const Center(
          child: Text("Weight and Comments"),
        );
    }
  }

  BottomNavigationBarItem _toBottomNavItem(BottomNavPage page) {
    switch (page) {
      case BottomNavPage.workout:
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
      case BottomNavPage.other:
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
      case BottomNavPage.workout:
        Navigator.of(context).pushNamed(Routes.editMetcon);
        break;
      case BottomNavPage.strength:
        Navigator.of(context).pushNamed(Routes.editStrengthSession);
        break;
      default:
    }
  }

  PreferredSizeWidget get _timeFilter {
    final primaryColor = Theme.of(context).primaryColor;
    return PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
                onPressed: _dateFilter.timeFrame == TimeFrame.all
                    ? null
                    : () {
                        setState(() {
                          _dateFilter.goBackInTime();
                          _showDateFilter = false;
                        });
                      },
                icon: const Icon(Icons.arrow_back_ios_sharp)),
            TextButton.icon(
              label: const Icon(Icons.arrow_drop_down_sharp),
              icon: Text(
                _dateFilter.getLabel(),
                style: TextStyle(
                  fontSize: 20,
                  color: primaryColor,
                ),
              ),
              onPressed: () {
                setState(() => _showDateFilter = !_showDateFilter);
              },
            ),
            IconButton(
                onPressed: _dateFilter.goingForwardPossible
                    ? () {
                        setState(() {
                          _dateFilter.goForwardInTime();
                          _showDateFilter = false;
                        });
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward_ios_sharp)),
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
