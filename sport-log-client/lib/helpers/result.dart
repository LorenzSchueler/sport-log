import 'dart:async';

sealed class Result<S, E> {
  S get ok => (this as Ok<S, E>)._ok;
  E get err => (this as Err<S, E>)._err;

  bool get isOk => this is Ok;
  bool get isErr => this is Err;

  Result<U, E> map<U extends Object>(U Function(S) transform) =>
      isOk ? Ok(transform(ok)) : Err(err);

  Result<U, E> flatMap<U, E2>(Result<U, E> Function(S) transform) =>
      isOk ? transform(ok) : Err(err);

  void onOk(void Function(S) transform) {
    if (isOk) {
      transform(ok);
    }
  }

  Result<S, E2> mapErr<E2>(E2 Function(E) transform) =>
      isOk ? Ok(ok) : Err(transform(err));

  Result<S, E2> flatMapErr<V, E2>(Result<S, E2> Function(E) transform) =>
      isOk ? Ok(ok) : transform(err);

  void onErr(void Function(E) transform) {
    if (isErr) {
      transform(err);
    }
  }

  S unwrapOr(S initial) => isOk ? ok! : initial;

  S unwrapOrElse(S Function(E) operation) => isOk ? ok! : operation(err);

  Result<S, void> nullErr() => this as Result<S, void>;
}

final class Ok<S, E> extends Result<S, E> {
  Ok(this._ok);

  final S _ok;
}

final class Err<S, E> extends Result<S, E> {
  Err(this._err);

  final E _err;
}

extension FutureResult<S, E> on Future<Result<S, E>> {
  Future<Result<U, E>> mapAsync<U extends Object>(
    FutureOr<U> Function(S) transform,
  ) async {
    final self = await this;
    return self.isOk ? Ok(await transform(self.ok)) : Err(self.err);
  }

  Future<Result<U, E>> flatMapAsync<U extends Object>(
    FutureOr<Result<U, E>> Function(S) transform,
  ) async {
    final self = await this;
    return self.isOk ? await transform(self.ok) : Err(self.err);
  }

  Future<Result<S, E>> onOkAsync(FutureOr<void> Function(S) transform) async {
    final self = await this;
    if (self.isOk) {
      await transform(self.ok);
    }
    return self;
  }

  Future<Result<S, E2>> mapErrAsync<E2 extends Object>(
    FutureOr<E2> Function(E) transform,
  ) async {
    final self = await this;
    return self.isOk ? Ok(self.ok) : Err(await transform(self.err));
  }

  Future<Result<S, E2>> flatMapErrAsync<V, E2>(
    FutureOr<Result<S, E2>> Function(E) transform,
  ) async {
    final self = await this;
    return self.isErr ? await transform(self.err) : Ok(self.ok);
  }

  Future<Result<S, E>> onErrAsync(FutureOr<void> Function(E) transform) async {
    final self = await this;
    if (self.isErr) {
      await transform(self.err);
    }
    return self;
  }

  Future<S> unwrapOrAsync(S initial) async {
    final self = await this;
    return self.isOk ? self.ok! : initial;
  }

  Future<S> unwrapOrElseAsync(FutureOr<S> Function(E) operation) async {
    final self = await this;
    return self.isOk ? self.ok! : operation(self.err);
  }

  Future<Result<S, void>> nullErr() => this;
}
