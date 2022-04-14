part of '../api.dart';

class DiaryApi extends Api<Diary> {
  @override
  Diary _fromJson(Map<String, dynamic> json) => Diary.fromJson(json);

  @override
  String get _singularRoute => apiVersion + '/diary';

  @override
  String get _pluralRoute => apiVersion + '/diaries';
}
