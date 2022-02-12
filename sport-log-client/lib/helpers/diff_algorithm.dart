import 'package:sport_log/database/db_interfaces.dart';

class Diffing<T> {
  List<T> toDelete = [];
  List<T> toCreate = [];
  List<T> toUpdate = [];
}

Diffing<T> diff<T extends HasId>(List<T> oldList, List<T> newList) {
  int sortingFn(T o1, T o2) => o1.id.compareTo(o2.id);
  oldList.sort(sortingFn);
  newList.sort(sortingFn);

  int indexOld = 0;
  int indexNew = 0;

  final result = Diffing<T>();

  while (true) {
    if (indexNew >= newList.length) {
      result.toDelete.addAll(oldList.sublist(indexOld));
      break;
    }
    if (indexOld >= oldList.length) {
      result.toCreate.addAll(newList.sublist(indexNew));
      break;
    }
    if (newList[indexNew].id < oldList[indexOld].id) {
      result.toCreate.add(newList[indexNew]);
      ++indexNew;
    } else if (newList[indexNew].id > oldList[indexOld].id) {
      result.toDelete.add(oldList[indexOld]);
      ++indexOld;
    } else {
      result.toUpdate.add(newList[indexNew]);
      ++indexNew;
      ++indexOld;
    }
  }
  return result;
}
