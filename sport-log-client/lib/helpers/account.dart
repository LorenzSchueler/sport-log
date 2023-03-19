import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/models/metcon/metcon_description.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/user/user.dart';
import 'package:sport_log/settings.dart';

// id
//   username
//   password
//   email
// =user
//   accountCreated
//     serverUrl
//     syncEnabled
//       syncInterval
//       lastSync
class Account {
  Account._();

  static Future<void> noAccount() async {
    await Settings.instance.setUserId(randomId());
    await Settings.instance.setAccountCreated(false);
    await Settings.instance.setDefaultServerUrl();
    await Settings.instance.setSyncEnabled(false);
  }

  static Future<ApiResult<User>> register(String serverUrl, User user) async {
    await Settings.instance.setServerUrl(serverUrl);
    final result = await Api.user.postSingle(user);
    if (result.isSuccess) {
      await Settings.instance.setUser(user);
      await Settings.instance.setAccountCreated(true);
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
    await Settings.instance.setServerUrl(serverUrl);
    final result = await Api.user.getSingle(username, password);
    if (result.isSuccess) {
      final user = result.success;
      await Settings.instance.setUser(user);
      await Settings.instance.setAccountCreated(true);
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
      await Settings.instance.setUser(user);
      return Success(user);
    } else {
      return Failure(result.failure);
    }
  }

  static Future<void> updateUserFromDownSync(User user) async {
    // preserve password because User from server only contains password hash
    user.password = Settings.instance.password!;
    await Settings.instance.setUser(user);
  }

  static Future<void> logout() async {
    Sync.instance.stopSync();
    await Settings.instance.setAccountCreated(false);
    await Settings.instance.setLastSync(null);
    await Settings.instance.setUser(null);
    Movement.defaultMovement = null;
    MetconDescription.defaultMetconDescription = null;
    await AppDatabase.reset();
  }

  static Future<ApiResult<void>> delete() async {
    Sync.instance.stopSync();
    final result = await Api.user.deleteSingle();
    if (result.isSuccess) {
      await Settings.instance.setAccountCreated(false);
      await Settings.instance.setLastSync(null);
      await Settings.instance.setUser(null);
      Movement.defaultMovement = null;
      MetconDescription.defaultMetconDescription = null;
      await AppDatabase.reset();
      return Success(null);
    } else {
      return Failure(result.failure);
    }
  }

  static Future<ApiResult<void>> newInitSync() async {
    // check if current User is able to login
    final result = await Api.user
        .getSingle(Settings.instance.username!, Settings.instance.password!);
    if (result.isFailure) {
      return Failure(result.failure);
    }

    Sync.instance.stopSync();
    await Settings.instance.setLastSync(null);
    Movement.defaultMovement = null;
    MetconDescription.defaultMetconDescription = null;
    await AppDatabase.reset();

    await Sync.instance.startSync();
    return Success(null);
  }
}
