/// An object holding a object.
///
/// Used for passing by reference.
class Pointer<T> {
  Pointer(this.object);

  T object;
}

/// An object holding a nullable object.
///
/// Used for passing by reference.
class NullablePointer<T> extends Pointer<T?> {
  NullablePointer(super.object);
  NullablePointer.nullPointer() : this(null);

  void setNull() => object = null;

  bool get isNull => object == null;
  bool get isNotNull => object != null;
}
