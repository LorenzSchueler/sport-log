import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/tables/all.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/platform/all.dart';
import 'package:sport_log/models/platform/platform_description.dart';

class PlatformDataProvider extends EntityDataProvider<Platform> {
  factory PlatformDataProvider() => _instance;

  PlatformDataProvider._();

  static final _instance = PlatformDataProvider._();

  @override
  final Api<Platform> api = Api.platforms;

  @override
  final TableAccessor<Platform> db = AppDatabase.platforms;

  @override
  List<Platform> getFromAccountData(AccountData accountData) =>
      accountData.platforms;
}

class PlatformCredentialDataProvider
    extends EntityDataProvider<PlatformCredential> {
  factory PlatformCredentialDataProvider() => _instance;

  PlatformCredentialDataProvider._();

  static final _instance = PlatformCredentialDataProvider._();

  @override
  final Api<PlatformCredential> api = Api.platformCredentials;

  @override
  final PlatformCredentialTable db = AppDatabase.platformCredentials;

  @override
  List<PlatformCredential> getFromAccountData(AccountData accountData) =>
      accountData.platformCredentials;

  Future<PlatformCredential?> getByPlatform(Platform platfrom) =>
      db.getByPlatform(platfrom);
}

class PlatformDescriptionDataProvider
    extends DataProvider<PlatformDescription> {
  factory PlatformDescriptionDataProvider() {
    if (_instance == null) {
      _instance = PlatformDescriptionDataProvider._();
      _instance!._platformDataProvider.addListener(_instance!.notifyListeners);
      _instance!._platformCredentialDataProvider
          .addListener(_instance!.notifyListeners);
      _instance!._actionProviderDataProvider
          .addListener(_instance!.notifyListeners);
    }
    return _instance!;
  }

  PlatformDescriptionDataProvider._();

  static PlatformDescriptionDataProvider? _instance;

  final _platformDataProvider = PlatformDataProvider();
  final _platformCredentialDataProvider = PlatformCredentialDataProvider();
  final _actionProviderDataProvider = ActionProviderDataProvider();

  @override
  Future<DbResult> createSingle(PlatformDescription object) async {
    if (object.platformCredential == null) {
      return DbResult.success();
    }
    return _platformCredentialDataProvider
        .createSingle(object.platformCredential!);
  }

  @override
  Future<DbResult> updateSingle(PlatformDescription object) async {
    if (object.platformCredential == null) {
      return DbResult.success();
    }
    return _platformCredentialDataProvider
        .updateSingle(object.platformCredential!);
  }

  @override
  Future<DbResult> deleteSingle(PlatformDescription object) async {
    if (object.platformCredential == null) {
      return DbResult.success();
    }
    return _platformCredentialDataProvider
        .deleteSingle(object.platformCredential!);
  }

  @override
  Future<List<PlatformDescription>> getNonDeleted() async {
    return Future.wait(
      (await _platformDataProvider.getNonDeleted())
          .map(
            (platform) async => PlatformDescription(
              platform: platform,
              platformCredential:
                  await _platformCredentialDataProvider.getByPlatform(platform),
              actionProviders:
                  await _actionProviderDataProvider.getByPlatform(platform),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<bool> pullFromServer() async {
    if (!await _platformDataProvider.pullFromServer(notify: false)) {
      return false;
    }
    if (!await _platformCredentialDataProvider.pullFromServer(notify: false)) {
      return false;
    }
    return _actionProviderDataProvider.pullFromServer();
  }

  @override
  Future<bool> pushCreatedToServer() async {
    return _platformCredentialDataProvider.pushCreatedToServer();
  }

  @override
  Future<bool> pushUpdatedToServer() async {
    return _platformCredentialDataProvider.pushUpdatedToServer();
  }
}
