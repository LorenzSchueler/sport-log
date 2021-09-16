import 'package:sport_log/helpers/validation.dart';
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
    return validate(metconDescription.isValid(),
            'MetconSessionDescription: metcon description not valid') &&
        validate(metconSession.metconId == metconDescription.metcon.id,
            'MetconSessionDescription: metcon id mismatch');
  }
}
