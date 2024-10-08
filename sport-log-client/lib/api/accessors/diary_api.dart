import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/diary/diary.dart';

class DiaryApi extends Api<Diary> {
  factory DiaryApi() => _instance;

  DiaryApi._();

  static final _instance = DiaryApi._();

  @override
  Diary fromJson(Map<String, dynamic> json) => Diary.fromJson(json);

  @override
  final route = '/diary';
}
