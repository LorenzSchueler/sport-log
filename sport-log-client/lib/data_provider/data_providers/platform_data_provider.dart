import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/platform/all.dart';

class PlatformDataProvider extends EntityDataProvider<Platform> {
  static final _instance = PlatformDataProvider._();
  PlatformDataProvider._();
  factory PlatformDataProvider() => _instance;

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
  static final _instance = PlatformCredentialDataProvider._();
  PlatformCredentialDataProvider._();
  factory PlatformCredentialDataProvider() => _instance;

  @override
  final Api<PlatformCredential> api = Api.platformCredentials;

  @override
  final TableAccessor<PlatformCredential> db = AppDatabase.platformCredentials;

  @override
  List<PlatformCredential> getFromAccountData(AccountData accountData) =>
      accountData.platformCredentials;
}
