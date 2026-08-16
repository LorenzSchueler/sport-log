import 'package:material_ui/material_ui.dart';

class MountedWrapper<T> {
  MountedWrapper(this._inner, this._context);

  final T _inner;
  final BuildContext _context;

  T? get ifMounted => _context.mounted ? _inner : null;
}
