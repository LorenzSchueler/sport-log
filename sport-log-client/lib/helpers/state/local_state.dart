import 'package:fixnum/fixnum.dart';
import 'package:sport_log/helpers/interfaces.dart';

class LocalState<T extends HasId> {
  LocalState(this._objects);

  LocalState.empty() : _objects = {};

  LocalState.fromList(List<T> objects)
      : _objects = {for (final o in objects) o.id: o};

  Map<Int64, T> _objects;

  Map<Int64, T> get asMap => _objects;

  List<T> get asList => _objects.values.toList();

  List<T> sortedBy(int Function(T o1, T o2) compareFn) {
    return asList..sort(compareFn);
  }

  void update(T object) {
    assert(_objects.containsKey(object.id));
    _objects[object.id] = object;
  }

  void create(T object) {
    assert(!_objects.containsKey(object.id));
    _objects[object.id] = object;
  }

  void delete(Int64 id) {
    assert(_objects.containsKey(id));
    _objects.remove(id);
  }

  bool get isEmpty => _objects.isEmpty;
}
