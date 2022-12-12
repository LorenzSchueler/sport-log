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
class NullablePointer<T> {
  NullablePointer(this.object);
  NullablePointer.nullPointer() : object = null;

  T? object;

  void setNull() => object = null;

  bool get isNull => object == null;
  bool get isNotNull => object != null;
}
