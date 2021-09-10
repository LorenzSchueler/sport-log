import 'package:result_type/result_type.dart';

extension ResultExtension<S, F> on Result<S, F> {
  S or(S value) {
    if (isFailure) {
      return value;
    }
    return success;
  }

  S orDo(S Function(F fail) onError) {
    if (isFailure) {
      return onError(failure);
    }
    return success;
  }
}
