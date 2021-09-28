import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/pages/workout/diary/overview_page.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/movement_picker.dart';
import 'package:sport_log/widgets/wide_screen_frame.dart';

import 'cardio_sessions/overview_page.dart';
import 'strength_sessions/overview_page.dart';
import 'date_filter/date_filter_widget.dart';
import 'metcon_sessions/overview_page.dart';
import 'ui_cubit.dart';

class WorkoutPage extends StatelessWidget {
  WorkoutPage({Key? key}) : super(key: key);

  final GlobalKey<StrengthSessionsPageState> _strengthKey = GlobalKey();
  final GlobalKey<MetconSessionsPageState> _metconKey = GlobalKey();
  final GlobalKey<CardioSessionsPageState> _cardioKey = GlobalKey();
  final GlobalKey<DiaryPageState> _diaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SessionsUiCubit(),
      child: BlocBuilder<SessionsUiCubit, SessionsUiState>(
        buildWhen: (oldState, newState) =>
            oldState.dateFilter != newState.dateFilter ||
            oldState.movement != newState.movement ||
            oldState.tab != newState.tab ||
            oldState.shouldShowFab != newState.shouldShowFab,
        builder: (context, state) {
          final cubit = context.read<SessionsUiCubit>();
          return Scaffold(
            appBar: AppBar(
              title: Text(state.titleText),
              actions: [
                IconButton(
                  onPressed: () =>
                      _onMovementSelection(context, state.movement, cubit),
                  icon: Icon(state.isMovementSelected
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: DateFilter(
                  initialState: state.dateFilter,
                  onFilterChanged: cubit.setDateFilter,
                ),
              ),
            ),
            body: WideScreenFrame(child: _mainPage(state)),
            bottomNavigationBar: BottomNavigationBar(
              items: SessionsPageTab.values.map(_toBottomNavItem).toList(),
              currentIndex: state.tab.index,
              onTap: _onBottomNavItemTapped(cubit),
              type: BottomNavigationBarType.fixed,
            ),
            drawer: const MainDrawer(selectedRoute: Routes.workout),
            floatingActionButton: state.shouldShowFab
                ? FloatingActionButton(
                    child: const Icon(Icons.add),
                    onPressed: () => _onFabTapped(state, context),
                  )
                : null,
          );
        },
      ),
    );
  }

  void _onMovementSelection(BuildContext context, Movement? oldMovement,
      SessionsUiCubit cubit) async {
    final Movement? movement =
        await showMovementPickerDialog(context, selectedMovement: oldMovement);
    if (movement == null) {
      return;
    }
    if (movement.id == oldMovement?.id) {
      cubit.removeMovement();
    } else {
      cubit.setMovement(movement);
    }
  }

  Widget _mainPage(SessionsUiState state) {
    // TODO: preserve state and/or widget when changing tab
    switch (state.tab) {
      case SessionsPageTab.strength:
        return StrengthSessionsPage(key: _strengthKey);
      case SessionsPageTab.metcon:
        return MetconSessionsPage(key: _metconKey);
      case SessionsPageTab.cardio:
        return CardioSessionsPage(key: _cardioKey);
      case SessionsPageTab.diary:
        return DiaryPage(key: _diaryKey);
    }
  }

  BottomNavigationBarItem _toBottomNavItem(SessionsPageTab page) {
    switch (page) {
      case SessionsPageTab.metcon:
        return const BottomNavigationBarItem(
          icon: Icon(CustomIcons.plan),
          label: "Metcons",
        );
      case SessionsPageTab.strength:
        return const BottomNavigationBarItem(
          icon: Icon(CustomIcons.dumbbellNotRotated),
          label: "Strength",
        );
      case SessionsPageTab.cardio:
        return const BottomNavigationBarItem(
          icon: Icon(CustomIcons.heart),
          label: "Cardio",
        );
      case SessionsPageTab.diary:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.edit),
          label: "Other",
        );
    }
  }

  void Function(int) _onBottomNavItemTapped(SessionsUiCubit cubit) {
    return (index) => cubit.setTab(SessionsPageTab.values[index]);
  }

  void _onFabTapped(SessionsUiState state, BuildContext context) {
    switch (state.tab) {
      case SessionsPageTab.strength:
        _strengthKey.currentState?.onFabTapped(context);
        break;
      case SessionsPageTab.metcon:
        _metconKey.currentState?.onFabTapped(context);
        break;
      case SessionsPageTab.cardio:
        _cardioKey.currentState?.onFabTapped(context);
        break;
      case SessionsPageTab.diary:
        _diaryKey.currentState?.onFabTapped(context);
        break;
    }
  }
}
