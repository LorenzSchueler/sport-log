import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/platform/platform_credential.dart';

class PlatformCredentialDataProvider
    extends DataProviderImpl<PlatformCredential>
    with ConnectedMethods<PlatformCredential> {
  @override
  final ApiAccessor<PlatformCredential> api = Api.instance.platformCredentials;

  @override
  final Table<PlatformCredential> db =
      AppDatabase.instance!.platformCredentials;
}