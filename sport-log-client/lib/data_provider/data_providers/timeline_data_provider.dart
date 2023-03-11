import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/diary_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/models/all.dart';

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

  Future<List<TimelineUnion>> getByTimerangeAndMovementOrMetconAndComment({
    required DateTime? from,
    required DateTime? until,
    required String? comment,
    required MovementOrMetcon? movementOrMetcon,
  }) async =>
      _combineAndSort(
        strengthSessionsDescription: movementOrMetcon?.isMetcon ?? false
            ? []
            : await _strengthDataProvider.getByTimerangeAndMovementAndComment(
                from: from,
                until: until,
                movement: movementOrMetcon?.movement,
                comment: comment,
              ),
        metconSessionsDescription: movementOrMetcon?.isMovement ?? false
            ? []
            : await _metconDataProvider.getByTimerangeAndMetconAndComment(
                from: from,
                until: until,
                metcon: movementOrMetcon?.metcon,
                comment: comment,
              ),
        cardioSessionsDescription: movementOrMetcon?.isMetcon ?? false
            ? []
            : await _cardioDataProvider.getByTimerangeAndMovementAndComment(
                from: from,
                until: until,
                movement: movementOrMetcon?.movement,
                comment: comment,
              ),
        diaries: movementOrMetcon != null
            ? []
            : await _diaryDataProvider.getByTimerangeAndComment(
                from: from,
                until: until,
                comment: comment,
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
