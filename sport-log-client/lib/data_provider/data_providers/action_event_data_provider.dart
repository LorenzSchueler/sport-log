import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/action/action_event.dart';

class ActionEventDataProvider extends DataProviderImpl<ActionEvent>
    with ConnectedMethods<ActionEvent> {
  @override
  final ApiAccessor<ActionEvent> api = Api.instance.actionEvents;

  @override
  final Table<ActionEvent> db = AppDatabase.instance!.actionEvents;
}
