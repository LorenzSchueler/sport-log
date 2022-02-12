part of '../api.dart';

class DiaryApi extends ApiAccessor<Diary> {
  @override
  Diary fromJson(Map<String, dynamic> json) => Diary.fromJson(json);

  @override
  String get singularRoute => version + '/diary';

  @override
  String get pluralRoute => version + '/diaries';

}
