enum ReturnAction { updated, created, deleted }

class ReturnObject<T> {
  ReturnObject({
    required this.action,
    required this.payload,
  });

  ReturnAction action;
  T payload;
}
