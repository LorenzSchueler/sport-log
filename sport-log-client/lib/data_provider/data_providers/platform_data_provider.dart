import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sport_log/models/platform/all.dart';

class PlatformDataProvider extends EntityDataProvider<Platform> {
  static final instance = PlatformDataProvider._();
  PlatformDataProvider._();

  @override
  final Api<Platform> api = Api.platforms;

  @override
  final DbAccessor<Platform> db = AppDatabase.platforms;

  @override
  List<Platform> getFromAccountData(AccountData accountData) =>
      accountData.platforms;
}

class PlatformCredentialDataProvider
    extends EntityDataProvider<PlatformCredential> {
  static final instance = PlatformCredentialDataProvider._();
  PlatformCredentialDataProvider._();

  @override
  final Api<PlatformCredential> api = Api.platformCredentials;

  @override
  final DbAccessor<PlatformCredential> db = AppDatabase.platformCredentials;

  @override
  List<PlatformCredential> getFromAccountData(AccountData accountData) =>
      accountData.platformCredentials;
}
