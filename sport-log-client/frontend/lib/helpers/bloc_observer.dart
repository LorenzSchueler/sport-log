
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

/// observes all blocs and logs to console
class SimpleBlocObserver extends BlocObserver {
  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    log('${bloc.runtimeType} $transition', name: "bloc observer");
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    log('${bloc.runtimeType} $error $stackTrace', name: "bloc observer");
    super.onError(bloc, error, stackTrace);
  }
}