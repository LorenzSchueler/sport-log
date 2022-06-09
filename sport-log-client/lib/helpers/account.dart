import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/models/metcon/metcon_description.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/user/user.dart';
import 'package:sport_log/settings.dart';

class Account {
  Account._();

  static void noAccount(User user) {
    Settings.instance.accountCreated = false;
    Settings.instance.syncEnabled = false;
    Settings.instance.user = user;
  }

  static Future<ApiResult<User>> register(String serverUrl, User user) async {
    Settings.instance.serverUrl = serverUrl;
    final result = await Api.user.postSingle(user);
    if (result.isSuccess) {
      Settings.instance.user = user;
      await Sync.instance.startSync();
      return Success(user);
    } else {
      return Failure(result.failure);
    }
  }

  static Future<ApiResult<User>> login(
    String serverUrl,
    String username,
    String password,
  ) async {
    Settings.instance.serverUrl = serverUrl;
    final result = await Api.user.getSingle(username, password);
    if (result.isSuccess) {
      User user = result.success;
      Settings.instance.user = user;
      await Sync.instance.startSync();
      return Success(user);
    } else {
      return Failure(result.failure);
    }
  }

  static Future<ApiResult<User>> editUser({
    String? username,
    String? password,
    String? email,
  }) async {
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
    final result = await Api.user.putSingle(user);
    if (result.isSuccess) {
      Settings.instance.user = user;
      return Success(user);
    } else {
      return Failure(result.failure);
    }
  }

  static void updateUserFromDownSync(User user) {
    user.password = Settings.instance.password!;
    Settings.instance.user = user;
  }

  static Future<void> logout() async {
    Sync.instance.stopSync();
    Settings.instance.lastSync = null;
    Settings.instance.user = null;
    Movement.defaultMovement = null;
    MetconDescription.defaultMetconDescription = null;
    await Settings.instance.setDefaults(override: true);
    await AppDatabase.reset();
  }

  static Future<ApiResult<void>> delete() async {
    Sync.instance.stopSync();
    final result = await Api.user.deleteSingle();
    if (result.isSuccess) {
      Settings.instance.lastSync = null;
      Settings.instance.user = null;
      Movement.defaultMovement = null;
      MetconDescription.defaultMetconDescription = null;
      await Settings.instance.setDefaults(override: true);
      await AppDatabase.reset();
      return Success(null);
    } else {
      return Failure(result.failure);
    }
  }

  static Future<ApiResult<void>> newInitSync() async {
    final result = await Api.user
        .getSingle(Settings.instance.username!, Settings.instance.password!);
    if (result.isFailure) {
      return Failure(result.failure);
    }

    Sync.instance.stopSync();
    Settings.instance.lastSync = null;
    Movement.defaultMovement = null;
    MetconDescription.defaultMetconDescription = null;
    await AppDatabase.reset();

    await Sync.instance.startSync();
    return Success(null);
  }
}
