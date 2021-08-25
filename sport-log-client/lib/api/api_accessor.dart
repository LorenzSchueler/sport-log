/*
abstract class ApiAccessor<T> {
  // things needed to be overridden
  T fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson(T object);
  String get singularRoute; // everything after url base, e. g. '/v1/user'
  String get pluralRoute;

  // fields
  final client = Client();
  final urlBase = Config.apiUrlBase;

  // actual methods
  ApiResult<T> getSingle(Int64? id) async {}

  ApiResult<List<T>> getMultiple() async {}

  ApiResult<void> postSingle(T object) async {}

  ApiResult<void> postMultiple(List<T> objects) async {}

  ApiResult<void> updateSingle(T object) async {}

  ApiResult<void> updateMultiple(List<T> objects) async {}

  // helper methods
  ApiResult<T> _errorHandling<T>(
      Future<Result<T, ApiError>> Function(http.Client client) req) async {
    try {
      return req(_client);
    } on SocketException {
      return Failure(ApiError.noInternetConnection);
    } catch (e) {
      _logger.e("Unhandled error: " + e.toString());
      return Failure(ApiError.unhandled);
    }
  }
}
*/
