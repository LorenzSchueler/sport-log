
import 'package:sport_log/helpers/update_validatable.dart';
import 'package:sport_log/models/metcon/metcon_description.dart';
import 'package:sport_log/models/metcon/metcon_session.dart';

class MetconSessionDescription implements Validatable {
  MetconSessionDescription({
    required this.metconSession,
    required this.metconDescription,
  });

  MetconSession metconSession;
  MetconDescription metconDescription;

  @override
  bool isValid() {
    return metconDescription.isValid()
        && metconSession.metconId == metconDescription.metcon.id;
  }
}