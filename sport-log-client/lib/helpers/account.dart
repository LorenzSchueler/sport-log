import 'package:sport_log/api/accessors/user_api.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/result.dart';
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
    await Settings.instance.setEpochMap(null);

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
    return UserApi().postSingle(user).onOkAsync((_) async {
      await Settings.instance.setUser(user);
      await Settings.instance.setAccountCreated(true);
      // serverUrl already set
      await Settings.instance.setSyncEnabled(true);
      await Settings.instance.setDefaultSyncInterval();

      // because the id of entities is not changed, registering as a different user on the same server will fail unless the old user is deleted first
      await Sync.instance.startSync();
    });
    // on error keep new serverUrl

    // result: user exits, account created, userId of old db data updated
  }

  static Future<ApiResult<User>> login(
    String serverUrl,
    String username,
    String password,
  ) async {
    _logger.i("login");

    // scenario: initial app start, when password changed, after noAccount, logout or delete
    // the user may exist
    // there may be data in the db
    // the user may have created an account

    await Settings.instance.setServerUrl(serverUrl);
    return UserApi().getSingle(username, password).mapAsync((user) async {
      await Settings.instance.setUser(user);
      await Settings.instance.setAccountCreated(true);
      // serverUrl already set
      await Settings.instance.setSyncEnabled(true);
      await Settings.instance.setDefaultSyncInterval();

      // because the id of entities is not changed, logging in as a different user on the same server will fail unless the old user is deleted first
      await Sync.instance.startSync();

      return user;
    });
    // on error keep new serverUrl

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
      return Ok(user);
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
    return UserApi().putSingle(user).mapAsync((_) async {
      await Settings.instance.setUser(user);
      return user;
    });

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
    await Settings.instance.setEpochMap(null);
    await EntityDataProvider.setAllCreated();

    // result: user still exists, no account created, all data is set to created
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
    return UserApi().deleteSingle().onOkAsync((_) async {
      await Settings.instance.setUser(null);
      await Settings.instance.setAccountCreated(false);
      // keep serverUrl as is
      await Settings.instance.setSyncEnabled(false);
      // keep syncInterval as is
      await Settings.instance.setEpochMap(null);

      Movement.defaultMovement = null;
      MetconDescription.defaultMetconDescription = null;

      await AppDatabase.reset();
    });

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
    if (result.isErr) {
      return result;
    }

    Sync.instance.stopSync();

    await Settings.instance.setEpochMap(null);

    Movement.defaultMovement = null;
    MetconDescription.defaultMetconDescription = null;

    await AppDatabase.reset();

    await Sync.instance.startSync();
    return Ok(null);

    // result: no state change
  }
}
