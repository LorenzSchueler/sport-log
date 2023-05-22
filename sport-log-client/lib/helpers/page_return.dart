enum ReturnAction { updated, created, deleted }

class ReturnObject<T> {
  ReturnObject.created(this.payload) : action = ReturnAction.created;
  ReturnObject.updated(this.payload) : action = ReturnAction.updated;
  ReturnObject.deleted(this.payload) : action = ReturnAction.deleted;
  ReturnObject.isNew(bool isNew, this.payload)
      : action = isNew ? ReturnAction.created : ReturnAction.updated;

  ReturnAction action;
  T payload;
}
