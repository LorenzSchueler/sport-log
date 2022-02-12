import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/models/user/user.dart';
import 'package:sport_log/settings.dart';

class Account {
  Account._();

  static Future<Result<User, String>> register(User user) async {
    final result = await Api.instance.user.postSingle(user);
    if (result.isSuccess) {
      Settings.instance.user = user;
      await AppDatabase.instance!.open();
      Sync.instance.startSync();
      return Success(user);
    } else {
      return Failure(result.failure.toErrorMessage());
    }
  }

  static Future<Result<User, String>> login(
      String username, String password) async {
    final result = await Api.instance.user.getSingle(username, password);
    if (result.isSuccess) {
      User user = result.success;
      Settings.instance.user = user;
      await AppDatabase.instance!.open();
      Sync.instance.startSync();
      return Success(user);
    } else {
      return Failure(result.failure.toErrorMessage());
    }
  }

  static Future<Result<User, String>> editUser(
      {String? username, String? password, String? email}) async {
    final user = Settings.instance.user!;
    if (username == null && password == null && email == null) {
      return Success(user);
    }
    if (username != null) {
      user.username = username;
    }
    if (password != null) {
      user.password = password;
    }
    if (email != null) {
      user.email = email;
    }
    final result = await Api.instance.user.putSingle(user);
    if (result.isSuccess) {
      Settings.instance.user = user;
      return Success(user);
    } else {
      return Failure(result.failure.toErrorMessage());
    }
  }

  static void logout() async {
    Sync.instance.stopSync();
    Settings.instance.user = null;
    await AppDatabase.instance!.delete();
  }
}
