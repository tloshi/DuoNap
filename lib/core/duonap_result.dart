/// Outcome of an operation. Services and repositories return this instead of throwing.
sealed class DuoNapResult<T> {
  const DuoNapResult();
}

final class DuoNapSuccess<T> extends DuoNapResult<T> {
  const DuoNapSuccess(this.data);

  final T data;
}

final class DuoNapFailure<T> extends DuoNapResult<T> {
  const DuoNapFailure(this.code, this.message);

  final String code;
  final String message;
}

extension DuoNapResultFold<T> on DuoNapResult<T> {
  R fold<R>(
    R Function(DuoNapFailure<T> failure) onFailure,
    R Function(T data) onSuccess,
  ) {
    final self = this;
    if (self is DuoNapSuccess<T>) return onSuccess(self.data);
    return onFailure(self as DuoNapFailure<T>);
  }
}
