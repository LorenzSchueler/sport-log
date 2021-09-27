import 'package:flutter_bloc/flutter_bloc.dart';

class SessionsUiState {
  const SessionsUiState({
    required this.showFab,
  });

  final bool showFab;

  @override
  bool operator ==(Object other) =>
      other is SessionsUiState && other.showFab == showFab;

  @override
  int get hashCode => showFab.hashCode;

  SessionsUiState copyWith({bool? showFab}) {
    return SessionsUiState(
      showFab: showFab ?? this.showFab,
    );
  }
}

class SessionsUiCubit extends Cubit<SessionsUiState> {
  SessionsUiCubit() : super(const SessionsUiState(showFab: false));

  void hideFab() {
    emit(state.copyWith(showFab: false));
  }

  void showFab() {
    emit(state.copyWith(showFab: true));
  }
}
