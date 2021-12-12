import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/models/movement/movement.dart';

import 'date_filter/date_filter_state.dart';

enum SessionsPageTab { timeline, strength, metcon, cardio, diary }

class SessionsUiState {
  const SessionsUiState({
    required bool showFab,
    required DateFilterState dateFilter,
    required Movement? movement,
    required SessionsPageTab tab,
  })  : _showFab = showFab,
        _dateFilter = dateFilter,
        _movement = movement,
        _tab = tab;

  final bool _showFab;
  final DateFilterState _dateFilter;
  final Movement? _movement;
  final SessionsPageTab _tab;

  @override
  bool operator ==(Object other) =>
      other is SessionsUiState &&
      other._showFab == _showFab &&
      other._dateFilter == _dateFilter &&
      other._movement == _movement &&
      other._tab == _tab;

  @override
  int get hashCode => Object.hash(_showFab, _dateFilter, _movement, _tab);

  SessionsUiState copyWith({
    bool? showFab,
    DateFilterState? dateFilter,
    Movement? movement,
    SessionsPageTab? tab,
  }) {
    return SessionsUiState(
      showFab: showFab ?? _showFab,
      dateFilter: dateFilter ?? _dateFilter,
      movement: movement ?? _movement,
      tab: tab ?? _tab,
    );
  }

  SessionsUiState noMovement() {
    return SessionsUiState(
      dateFilter: _dateFilter,
      showFab: _showFab,
      tab: _tab,
      movement: null,
    );
  }

  bool get isTimelinePage => _tab == SessionsPageTab.timeline;
  bool get isStrengthPage => _tab == SessionsPageTab.strength;
  bool get isMetconPage => _tab == SessionsPageTab.metcon;
  bool get isCardioPage => _tab == SessionsPageTab.cardio;
  bool get isDiaryPage => _tab == SessionsPageTab.diary;
  bool get shouldShowFab => _showFab;
  bool get isMovementSelected => _movement != null;

  String get titleText => _movement?.name ?? 'Sessions';
  Movement? get movement => _movement?.copy();
  DateFilterState get dateFilter => _dateFilter;
  SessionsPageTab get tab => _tab;
}

class SessionsUiCubit extends Cubit<SessionsUiState> {
  SessionsUiCubit()
      : super(SessionsUiState(
          showFab: false,
          dateFilter: MonthFilter.current(),
          movement: null,
          tab: SessionsPageTab.timeline,
        ));

  void hideFab() {
    emit(state.copyWith(showFab: false));
  }

  void showFab() {
    emit(state.copyWith(showFab: true));
  }

  void removeMovement() {
    emit(state.noMovement());
  }

  void setMovement(Movement movement) {
    emit(state.copyWith(movement: movement));
  }

  void setDateFilter(DateFilterState dateFilter) {
    emit(state.copyWith(dateFilter: dateFilter));
  }

  void setTab(SessionsPageTab tab) {
    emit(state.copyWith(tab: tab));
  }
}
