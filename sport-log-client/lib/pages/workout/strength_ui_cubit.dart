import 'package:flutter_bloc/flutter_bloc.dart';

class StrengthUiState {
  const StrengthUiState({
    required this.showFab,
  });

  final bool showFab;

  @override
  bool operator ==(Object other) =>
      other is StrengthUiState && other.showFab == showFab;

  @override
  int get hashCode => showFab.hashCode;

  StrengthUiState copyWith({bool? showFab}) {
    return StrengthUiState(
      showFab: showFab ?? this.showFab,
    );
  }
}

class StrengthUiCubit extends Cubit<StrengthUiState> {
  StrengthUiCubit() : super(const StrengthUiState(showFab: false));

  void hideFab() {
    emit(state.copyWith(showFab: false));
  }

  void showFab() {
    emit(state.copyWith(showFab: true));
  }
}
