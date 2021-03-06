import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/diary_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';

class TimelineDataProvider extends DataProvider<TimelineUnion> {
  factory TimelineDataProvider() {
    if (_instance == null) {
      _instance = TimelineDataProvider._();
      _instance!._strengthDataProvider.addListener(_instance!.notifyListeners);
      _instance!._metconDataProvider.addListener(_instance!.notifyListeners);
      _instance!._cardioDataProvider.addListener(_instance!.notifyListeners);
      _instance!._diaryDataProvider.addListener(_instance!.notifyListeners);
    }
    return _instance!;
  }

  TimelineDataProvider._();

  static TimelineDataProvider? _instance;

  final _strengthDataProvider = StrengthSessionDescriptionDataProvider();
  final _metconDataProvider = MetconSessionDescriptionDataProvider();
  final _cardioDataProvider = CardioSessionDescriptionDataProvider();
  final _diaryDataProvider = DiaryDataProvider();

  @override
  Future<DbResult> createSingle(TimelineUnion object) =>
      throw UnimplementedError();

  @override
  Future<DbResult> updateSingle(TimelineUnion object) =>
      throw UnimplementedError();

  @override
  Future<DbResult> deleteSingle(TimelineUnion object) =>
      throw UnimplementedError();

  @override
  Future<List<TimelineUnion>> getNonDeleted() async => _combineAndSort(
        strengthSessionsDescription:
            await _strengthDataProvider.getNonDeleted(),
        metconSessionsDescription: await _metconDataProvider.getNonDeleted(),
        cardioSessionsDescription: await _cardioDataProvider.getNonDeleted(),
        diaries: await _diaryDataProvider.getNonDeleted(),
      );

  @override
  Future<bool> pushUpdatedToServer() => throw UnimplementedError();

  @override
  Future<bool> pushCreatedToServer() => throw UnimplementedError();

  @override
  Future<bool> pullFromServer() async {
    if (!await _strengthDataProvider.pullFromServer()) {
      return false;
    }
    if (!await _metconDataProvider.pullFromServer()) {
      return false;
    }
    if (!await _cardioDataProvider.pullFromServer()) {
      return false;
    }
    return _diaryDataProvider.pullFromServer();
  }

  Future<List<TimelineUnion>> getByTimerange({
    DateTime? from,
    DateTime? until,
  }) async =>
      _combineAndSort(
        strengthSessionsDescription:
            await _strengthDataProvider.getByTimerangeAndMovement(
          from: from,
          until: until,
          movement: null,
        ),
        metconSessionsDescription:
            await _metconDataProvider.getByTimerangeAndMetcon(
          from: from,
          until: until,
          metcon: null,
        ),
        cardioSessionsDescription:
            await _cardioDataProvider.getByTimerangeAndMovement(
          from: from,
          until: until,
          movement: null,
        ),
        diaries: await _diaryDataProvider.getByTimerange(
          from: from,
          until: until,
        ),
      );

  List<TimelineUnion> _combineAndSort({
    required List<StrengthSessionDescription> strengthSessionsDescription,
    required List<MetconSessionDescription> metconSessionsDescription,
    required List<CardioSessionDescription> cardioSessionsDescription,
    required List<Diary> diaries,
  }) =>
      strengthSessionsDescription.map(TimelineUnion.strengthSession).toList()
        ..addAll(metconSessionsDescription.map(TimelineUnion.metconSession))
        ..addAll(cardioSessionsDescription.map(TimelineUnion.cardioSession))
        ..addAll(diaries.map(TimelineUnion.diary))
        ..sort((a, b) => b.compareTo(a));

  Future<TimelineRecords> getRecords() async => TimelineRecords(
        await _strengthDataProvider.getStrengthRecords(),
        await _metconDataProvider.getMetconRecords(),
      );
}
