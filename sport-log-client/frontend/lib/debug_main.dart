
import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/models/metcon/metcon.dart';

void main() async {
  Database db = Database();
  final m1 = Metcon(id: Int64(1), userId: Int64(4), name: "hallo", metconType: MetconType.amrap, rounds: 3, timecap: null, description: "description^", deleted: false);
  final m2 = Metcon(id: Int64(2), userId: Int64(4), name: "hallo", metconType: MetconType.amrap, rounds: 3, timecap: null, description: "description^", deleted: false);
  db.metconsDao.insertMetcon(m1);
  db.metconsDao.insertMetcon(m2);

  final allMetcons = db.metconsDao.getAllMetcons();
}