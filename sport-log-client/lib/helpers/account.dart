import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/models/user/user.dart';
import 'package:sport_log/settings.dart';

class Account {
  Account._();

  static ApiResult<User> register(User user) async {
    final result = await Api.user.postSingle(user);
    if (result.isSuccess) {
      Settings.user = user;
      await Sync.instance.startSync();
      return Success(user);
    } else {
      return Failure(result.failure);
    }
  }

  static ApiResult<User> login(
    String username,
    String password,
  ) async {
    final result = await Api.user.getSingle(username, password);
    if (result.isSuccess) {
      User user = result.success;
      Settings.user = user;
      await Sync.instance.startSync();
      return Success(user);
    } else {
      return Failure(result.failure);
    }
  }

  static ApiResult<User> editUser({
    String? username,
    String? password,
    String? email,
  }) async {
    final user = Settings.user!;
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
      Settings.user = user;
      return Success(user);
    } else {
      return Failure(result.failure);
    }
  }

  static void updateUserFromDownSync(User user) {
    user.password = Settings.password!;
    Settings.user = user;
  }

  static Future<void> logout() async {
    Sync.instance.stopSync();
    Settings.lastSync = null;
    Settings.user = null;
    Settings.setDefaults(override: true);
    await AppDatabase.reset();
  }
}
