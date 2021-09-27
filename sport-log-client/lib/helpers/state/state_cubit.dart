import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/helpers/extensions/list_extension.dart';
import 'package:sport_log/helpers/interfaces.dart';

abstract class StateEvent<T extends HasId> {
  const StateEvent();
}

class UpdateEvent<T extends HasId> extends StateEvent<T> {
  const UpdateEvent(this.updated) : super();

  final List<T> updated;
}

class CreateEvent<T extends HasId> extends StateEvent<T> {
  const CreateEvent(this.created) : super();

  final List<T> created;
}

class DeleteEvent<T extends HasId> extends StateEvent<T> {
  const DeleteEvent(this.deleted) : super();

  final List<T> deleted;
}

class UpsertEvent<T extends HasId> extends StateEvent<T> {
  const UpsertEvent(this.upserted) : super();

  final List<T> upserted;
}

typedef StateStream<T extends HasId> = Stream<StateEvent<T>>;
typedef SortFn<T> = int Function(T t1, T t2);

// :)
class StateState<T extends HasId> {
  const StateState(this.objects);

  StateState.empty() : objects = [];

  final List<T> objects;
}

class StateCubit<T extends HasId> extends Cubit<StateState<T>> {
  Int64 idSelector(T t) => t.id;

  StateCubit({
    required StateStream<T> stream,
    SortFn<T>? sortBy,
  })  : _sortFn = sortBy,
        super(StateState.empty()) {
    _subscription = stream.listen((event) {
      if (event is UpdateEvent<T>) {
        final objects = List<T>.from(state.objects);
        objects.updateAll(event.updated, by: idSelector);
        if (sortBy != null) {
          objects.sort(sortBy);
        }
        emit(StateState(objects));
      } else if (event is CreateEvent<T>) {
        final objects = List<T>.from(state.objects);
        objects.addAll(event.created);
        if (sortBy != null) {
          objects.sort(sortBy);
        }
        emit(StateState(objects));
      } else if (event is DeleteEvent<T>) {
        final objects = List<T>.from(state.objects);
        objects.deleteAll(event.deleted, by: idSelector);
        emit(StateState(objects));
      } else if (event is UpsertEvent<T>) {
        final objects = List<T>.from(state.objects);
        objects.upsertAll(event.upserted, by: idSelector);
        if (sortBy != null) {
          objects.sort(sortBy);
        }
        emit(StateState(objects));
      }
    });
  }

  late final StreamSubscription _subscription;
  final SortFn<T>? _sortFn;

  void reset(Iterable<T> elements, {bool alreadySorted = false}) {
    final objects = List<T>.from(elements);
    if (_sortFn != null && !alreadySorted) {
      objects.sort(_sortFn);
    }
    emit(StateState(objects));
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
