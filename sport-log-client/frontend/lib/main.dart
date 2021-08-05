
import 'package:sport_log/api/api.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/bloc_observer.dart';
import 'package:sport_log/models/movement.dart';
import 'package:sport_log/pages/workout/metcon/metcons_cubit.dart';
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
  authRepo = await AuthenticationRepository.getInstance();
  user = await authRepo.getUser();
  final api = Api(urlBase: await Config.apiUrlBase);
  final authBloc = AuthenticationBloc(
      authenticationRepository: authRepo,
      api: api,
      user: user,
  );
  Bloc.observer = SimpleBlocObserver();
  final movementRepo = MovementRepository();
  addTestDataToMovementRepo(movementRepo);
  runApp(MultiBlocProvider(
    providers: [
      BlocProvider.value(value: authBloc),
      BlocProvider.value(value: MetconsCubit())
    ],
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
  movementRepo.addMovement(Movement(userId: null, id: 0, name: "Running", category: MovementCategory.cardio, description: "Running is a method of terrestrial locomotion allowing humans and other animals to move rapidly on foot."));
  movementRepo.addMovement(Movement(userId: null, id: 1, name: "Cycling", category: MovementCategory.cardio, description: "Cycling, also called bicycling or biking, is the use of bicycles for transport, recreation, exercise or sport."));
  movementRepo.addMovement(Movement(userId: null, id: 2, name: "Swimming", category: MovementCategory.cardio, description: "Swimming is the self-propulsion of a person through water, or a liquid substance, usually for recreation, sport, exercise, or survival. Locomotion is achieved through coordinated movement of the limbs and the body. Humans can hold their breath underwater and undertake rudimentary locomotive swimming within weeks of birth, as a survival response."));
  movementRepo.addMovement(Movement(userId: null, id: 3, name: "Squat", category: MovementCategory.strength, description: "A squat is a strength exercise in which the trainee lowers their hips from a standing position and then stands back up."));
  movementRepo.addMovement(Movement(userId: null, id: 4, name: "Deadlift", category: MovementCategory.strength, description: "The deadlift is a weight training exercise in which a loaded barbell or bar is lifted off the ground to the level of the hips, torso perpendicular to the floor, before being placed back on the ground. It is one of the three powerlifting exercises, along with the squat and bench press."));
  movementRepo.addMovement(Movement(userId: null, id: 5, name: "Bench Press", category: MovementCategory.cardio, description: "The bench press, or chest press, is an upper-body weight training exercise in which the trainee presses a weight upwards while lying on a weight training bench. The exercise uses the pectoralis major, the anterior deltoids, and the triceps, among other stabilizing muscles. A barbell is generally used to hold the weight, but a pair of dumbbells can also be used."));
  movementRepo.addMovement(Movement(userId: null, id: 6, name: "Crunch", category: MovementCategory.strength, description: "The crunch is one of the most popular abdominal exercises. When performed properly, it engages all the abdominal muscles but primarily it works the rectus abdominis muscle and the obliques. It allows both building six-pack abs, and tightening the belly."));
  movementRepo.addMovement(Movement(userId: null, id: 7, name: "Rows", category: MovementCategory.strength, description: null));
  movementRepo.addMovement(Movement(userId: null, id: 8, name: "Dip", category: MovementCategory.strength, description: "A dip is an upper-body strength exercise. Narrow, shoulder-width dips primarily train the triceps, with major synergists being the anterior deltoid, the pectoralis muscles (sternal, clavicular, and minor), and the rhomboid muscles of the back (in that order)."));
  movementRepo.addMovement(Movement(userId: null, id: 9, name: "Push up", category: MovementCategory.strength, description: "A push-up (sometimes called a press-up in British English) is a common calisthenics exercise beginning from the prone position. By raising and lowering the body using the arms, push-ups exercise the pectoral muscles, triceps, and anterior deltoids, with ancillary benefits to the rest of the deltoids, serratus anterior, coracobrachialis and the midsection as a whole."));
  movementRepo.addMovement(Movement(userId: null, id: 10, name: "Pull up", category: MovementCategory.strength, description: "A pull-up is an upper-body strength exercise. The pull-up is a closed-chain movement where the body is suspended by the hands and pulls up. As this happens, the elbows flex and the shoulders adduct and extend to bring the elbows to the torso."));
  movementRepo.addMovement(Movement(userId: null, id: 11, name: "Plank", category: MovementCategory.strength, description: "The plank (also called a front hold, hover, or abdominal bridge) is an isometric core strength exercise that involves maintaining a position similar to a push-up for the maximum possible time."));
  movementRepo.addMovement(Movement(userId: null, id: 12, name: "Lunge", category: MovementCategory.strength, description: null));
  movementRepo.addMovement(Movement(userId: null, id: 13, name: "Calf Raises", category: MovementCategory.strength, description: "Calf raises are a method of exercising the gastrocnemius, tibialis posterior, peroneals and soleus muscles of the lower leg. The movement performed is plantar flexion, a.k.a. ankle extension."));
  movementRepo.addMovement(Movement(userId: null, id: 14, name: "Biceps Curl", category: MovementCategory.strength, description: "The term 'biceps curl' refers to any of a number of weight training exercises that primarily targets the biceps brachii muscle. It may be performed using a barbell, dumbbell, resistance band, or other equipment."));
  movementRepo.addMovement(Movement(userId: null, id: 15, name: "Veeeeeeeeeeeeeery Loooooooong Naaaaaaame", category: MovementCategory.cardio, description: ""));
  movementRepo.addMovement(Movement(userId: null, id: 16, name: "V e e e e e e e e r y  L o o o o o o n g  N a a a a a m e", category: MovementCategory.cardio, description: ""));
}