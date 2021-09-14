enum ReturnAction { updated, created, deleted }

class ReturnObject<T> {
  ReturnObject({
    required this.action,
    required this.object,
  });

  ReturnAction action;
  T object;
}
