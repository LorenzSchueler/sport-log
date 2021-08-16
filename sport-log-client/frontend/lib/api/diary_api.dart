
part of 'api.dart';

extension DiaryRoutes on Api {
  ApiResult<void> createDiary(Diary diary) async {
    return _post(BackendRoutes.diary, diary);
  }

  ApiResult<void> createDiaries(List<Diary> diaries) async {
    return _post(BackendRoutes.diary, diaries);
  }

  ApiResult<List<Diary>> getDiaries() async {
    return _getMultiple(BackendRoutes.diary,
        fromJson: (json) => Diary.fromJson(json));
  }

  ApiResult<void> updateDiary(Diary diary) async {
    return _put(BackendRoutes.diary, diary);
  }

  ApiResult<void> updateDiaries(List<Diary> diaries) async {
    return _put(BackendRoutes.diary, diaries);
  }
}