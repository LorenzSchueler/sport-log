import 'package:result_type/result_type.dart';
import 'package:sport_log/api/accessors/user_api.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
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
abstract final class Account {
  static final _logger = Logger("Account");

  static Future<void> noAccount() async {
    _logger.i("noAccount");

    // scenario: initial app start, after delete
    // the user does not exist
    assert(Settings.instance.userId == null);
    // the user has not created an account
    assert(!Settings.instance.accountCreated);

    await Settings.instance.setUserId(randomId());
    // keep username, password and email as is
    // account created is false
    // keep serverUrl
    await Settings.instance.setSyncEnabled(false);
    // keep syncInterval as is
    await Settings.instance.setLastSync(null);

    // result: userId exists, user may exists, account not created
  }

  static Future<ApiResult<void>> register(String serverUrl, User user) async {
    _logger.i("register");

    // scenario: initial app start, after noAccount, logout or delete
    // the user may exist
    // there may be data in the db
    // the user has not created an account
    assert(!Settings.instance.accountCreated);

    await Settings.instance.setServerUrl(serverUrl);
    final result = await UserApi().postSingle(user);
    if (result.isSuccess) {
      await Settings.instance.setUser(user);
      await Settings.instance.setAccountCreated(true);
      // serverUrl already set
      await Settings.instance.setSyncEnabled(true);
      await Settings.instance.setDefaultSyncInterval();

      // set userId of all data in db to id of new user
      await AppDatabase.setUserId(user.id);

      await Sync.instance.startSync();

      return Success(null);
    } else {
      // keep new serverUrl
      return Failure(result.failure);
    }

    // result: user exits, account created, userId of old db data updated
  }

  static Future<ApiResult<User>> login(
    String serverUrl,
    String username,
    String password,
  ) async {
    _logger.i("login");

    // scenario: initial app start, after noAccount, logout or delete
    // the user may exist
    // there may be data in the db
    // the user has not created an account
    assert(!Settings.instance.accountCreated);

    await Settings.instance.setServerUrl(serverUrl);
    final result = await UserApi().getSingle(username, password);
    if (result.isSuccess) {
      final user = result.success;
      await Settings.instance.setUser(user);
      await Settings.instance.setAccountCreated(true);
      // serverUrl already set
      await Settings.instance.setSyncEnabled(true);
      await Settings.instance.setDefaultSyncInterval();

      // set userId of all data in db to id of logged in user
      await AppDatabase.setUserId(user.id);

      await Sync.instance.startSync();

      return Success(user);
    } else {
      // keep new serverUrl
      return Failure(result.failure);
    }

    // result: user exits, account created, userId of old db data updated
  }

  static Future<ApiResult<User>> editUser({
    String? username,
    String? password,
    String? email,
  }) async {
    _logger.i("editUser");

    // scenario: after login or register (otherwise username password and email not shown)
    // the user exists
    assert(Settings.instance.user != null);
    // the user has created an account
    assert(Settings.instance.accountCreated);

    final user = Settings.instance.user!;
    if (username == null && password == null && email == null) {
      // nothing to change
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
    final result = await UserApi().putSingle(user);
    if (result.isSuccess) {
      await Settings.instance.setUser(user);

      return Success(user);
    } else {
      return Failure(result.failure);
    }

    // result: no state change
  }

  static Future<void> updateUserFromDownSync(User user) async {
    _logger.i("updateUserFromDownSync");

    // scenario: after login or register
    // the user exists
    assert(Settings.instance.user != null);
    // the user has created an account
    assert(Settings.instance.accountCreated);

    // preserve password because user from server only contains password hash
    user.password = Settings.instance.password!;
    await Settings.instance.setUser(user);

    // result: no state change
  }

  static Future<void> logout() async {
    _logger.i("logout");

    // scenario: after login or register
    // the user exists
    assert(Settings.instance.user != null);
    // the user has created an account
    assert(Settings.instance.accountCreated);

    Sync.instance.stopSync();
    // keep userId as is
    await Settings.instance.setUsername(null);
    await Settings.instance.setPassword(null);
    await Settings.instance.setEmail(null);
    await Settings.instance.setAccountCreated(false);
    // keep serverUrl as is
    await Settings.instance.setSyncEnabled(false);
    // keep syncInterval as is
    await Settings.instance.setLastSync(null);
    // keep db data

    // result: user still exists, no account created
    // now we are in the same state as if we had called noAccount
  }

  static Future<ApiResult<void>> delete() async {
    _logger.i("delete");

    // scenario: after login or register
    // the user exists
    assert(Settings.instance.user != null);
    // the user has created an account
    assert(Settings.instance.accountCreated);

    Sync.instance.stopSync();
    final result = await UserApi().deleteSingle();
    if (result.isSuccess) {
      await Settings.instance.setUser(null);
      await Settings.instance.setAccountCreated(false);
      // keep serverUrl as is
      await Settings.instance.setSyncEnabled(false);
      // keep syncInterval as is
      await Settings.instance.setLastSync(null);

      Movement.defaultMovement = null;
      MetconDescription.defaultMetconDescription = null;

      await AppDatabase.reset();

      return Success(null);
    } else {
      return Failure(result.failure);
    }

    // result: user does not exist, no account created
    // now we are in the same state as in the initial app start
  }

  static Future<ApiResult<void>> newInitSync() async {
    _logger.i("newInitSync");

    // scenario: after login or register
    // the user exists
    assert(Settings.instance.user != null);
    // the user has created an account
    assert(Settings.instance.accountCreated);

    // check if current user is able to login
    final result = await UserApi()
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

    // result: on state change
  }
}
