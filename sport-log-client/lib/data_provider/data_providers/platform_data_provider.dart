import 'package:sport_log/api/accessors/platform_api.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/data_providers/action_data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/tables/platform_tables.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/platform/all.dart';
import 'package:sport_log/models/platform/platform_description.dart';

class PlatformDataProvider extends EntityDataProvider<Platform> {
  factory PlatformDataProvider() => _instance;

  PlatformDataProvider._();

  static final _instance = PlatformDataProvider._();

  @override
  final Api<Platform> api = PlatformApi();

  @override
  final TableAccessor<Platform> table = PlatformTable();

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
  final Api<PlatformCredential> api = PlatformCredentialApi();

  @override
  final PlatformCredentialTable table = PlatformCredentialTable();

  @override
  List<PlatformCredential> getFromAccountData(AccountData accountData) =>
      accountData.platformCredentials;

  Future<PlatformCredential?> getByPlatform(Platform platform) =>
      table.getByPlatform(platform);
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
}
