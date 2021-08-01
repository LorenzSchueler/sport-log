
import 'package:sport_log/api/api.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/bloc_observer.dart';
import 'package:sport_log/models/metcon.dart';
import 'package:sport_log/models/movement.dart';
import 'package:sport_log/repositories/authentication_repository.dart';
import 'package:sport_log/repositories/movement_repository.dart';
import 'package:sport_log/repositories/metcon_repository.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/blocs/authentication/authentication_bloc.dart';
import 'package:sport_log/models/user.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  User? user;
  AuthenticationRepository? authRepo;
  if (!Config.isWeb) {
    authRepo = await AuthenticationRepository.getInstance();
    user = await authRepo.getUser();
  }
  final api = Api(urlBase: await Config.apiUrlBase);
  final authBloc = AuthenticationBloc(
      authenticationRepository: authRepo,
      api: api,
      user: user,
  );
  Bloc.observer = SimpleBlocObserver();
  final movementRepo = MovementRepository();
  addTestDataToMovementRepo(movementRepo);
  runApp(BlocProvider.value(
    value: authBloc,
    child: MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepo),
        RepositoryProvider.value(value: api),
        RepositoryProvider.value(value: movementRepo),
        RepositoryProvider.value(value: MetconRepository()),
      ],
      child: App(
        isAuthenticatedAtStart: user != null,
      ),
    ),
  ));
}

void addTestDataToMovementRepo(MovementRepository movementRepo) {
  movementRepo.createMovement(NewMovement(name: "Running", category: MovementCategory.cardio, description: "Running is a method of terrestrial locomotion allowing humans and other animals to move rapidly on foot."));
  movementRepo.createMovement(NewMovement(name: "Squat", category: MovementCategory.strength, description: "A squat is a strength exercise in which the trainee lowers their hips from a standing position and then stands back up."));
  movementRepo.createMovement(NewMovement(name: "Cycling", category: MovementCategory.cardio, description: "Cycling, also called bicycling or biking, is the use of bicycles for transport, recreation, exercise or sport."));
  movementRepo.createMovement(NewMovement(name: "Swimming", category: MovementCategory.cardio, description: "Swimming is the self-propulsion of a person through water, or a liquid substance, usually for recreation, sport, exercise, or survival. Locomotion is achieved through coordinated movement of the limbs and the body. Humans can hold their breath underwater and undertake rudimentary locomotive swimming within weeks of birth, as a survival response."));
  movementRepo.createMovement(NewMovement(name: "Deadlift", category: MovementCategory.strength, description: "The deadlift is a weight training exercise in which a loaded barbell or bar is lifted off the ground to the level of the hips, torso perpendicular to the floor, before being placed back on the ground. It is one of the three powerlifting exercises, along with the squat and bench press."));
  movementRepo.createMovement(NewMovement(name: "Bench Press", category: MovementCategory.cardio, description: "The bench press, or chest press, is an upper-body weight training exercise in which the trainee presses a weight upwards while lying on a weight training bench. The exercise uses the pectoralis major, the anterior deltoids, and the triceps, among other stabilizing muscles. A barbell is generally used to hold the weight, but a pair of dumbbells can also be used."));
  movementRepo.createMovement(NewMovement(name: "Crunch", category: MovementCategory.strength, description: "The crunch is one of the most popular abdominal exercises. When performed properly, it engages all the abdominal muscles but primarily it works the rectus abdominis muscle and the obliques. It allows both building six-pack abs, and tightening the belly."));
  movementRepo.createMovement(NewMovement(name: "Rows", category: MovementCategory.strength));
}