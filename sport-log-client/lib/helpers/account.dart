import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/models/user/user.dart';
import 'package:sport_log/settings.dart';

class Account {
  Account._();

  static Future<Result<User, String>> login(
      String username, String password) async {
    final result = await Api.instance.user.getSingle(username, password);
    if (result.isSuccess) {
      User user = result.success;
      Settings.instance.user = user;
      Sync.instance.startSync();
      return Success(user);
    } else {
      return Failure(result.failure.toErrorMessage());
    }
  }

  static Future<Result<User, String>> register(User user) async {
    final result = await Api.instance.user.postSingle(user);
    if (result.isSuccess) {
      Settings.instance.user = user;
      Sync.instance.startSync();
      return Success(user);
    } else {
      return Failure(result.failure.toErrorMessage());
    }
  }

  static void logout() {
    Sync.instance.stopSync();
    Settings.instance.user = null;
  }
}
