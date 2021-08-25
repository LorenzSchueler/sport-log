import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/blocs/authentication/authentication_bloc.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/syncing.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/bloc_observer.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/pages/movements/movements_cubit.dart';
import 'package:sport_log/pages/workout/metcon/metcons_cubit.dart';
import 'package:sport_log/repositories/metcon_repository.dart';
import 'package:sport_log/repositories/movement_repository.dart';

Future<void> initialize({bool doDownSync = true}) async {
  WidgetsFlutterBinding.ensureInitialized(); // TODO: necessary?
  await Config.init();
  await UserState.instance.init();
  await AppDatabase.instance?.init().then((_) {
    DownSync.instance.init().then((downSync) {
      if (doDownSync) downSync.sync();
    });
  });
  await UpSync.instance.init();
  Bloc.observer = SimpleBlocObserver();
}

void main() async {
  initialize().then((_) {
    // TODO: this is a bad idea
    final movementRepo = MovementRepository();
    final movements = getMovementsTestData(movementRepo);
    movementRepo.addAllMovements(movements);
    final movementsCubit = MovementsCubit()..loadMovements(movements);

    runApp(MultiBlocProvider(
      providers: [
        BlocProvider.value(value: AuthenticationBloc()),
        BlocProvider.value(value: MetconsCubit()),
        BlocProvider.value(value: movementsCubit),
      ],
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: movementRepo),
          RepositoryProvider.value(value: MetconRepository()),
        ],
        child: const App(),
      ),
    ));
  });
}

List<Movement> getMovementsTestData(MovementRepository repo) {
  return [
    Movement(
        deleted: false,
        userId: null,
        id: repo.nextMovementId,
        name: "Running",
        category: MovementCategory.cardio,
        description:
            "Running is a method of terrestrial locomotion allowing humans and other animals to move rapidly on foot."),
    Movement(
        deleted: false,
        userId: null,
        id: repo.nextMovementId,
        name: "Cycling",
        category: MovementCategory.cardio,
        description:
            "Cycling, also called bicycling or biking, is the use of bicycles for transport, recreation, exercise or sport."),
    Movement(
        deleted: false,
        userId: null,
        id: repo.nextMovementId,
        name: "Swimming",
        category: MovementCategory.cardio,
        description:
            "Swimming is the self-propulsion of a person through water, or a liquid substance, usually for recreation, sport, exercise, or survival. Locomotion is achieved through coordinated movement of the limbs and the body. Humans can hold their breath underwater and undertake rudimentary locomotive swimming within weeks of birth, as a survival response."),
    Movement(
        deleted: false,
        userId: null,
        id: repo.nextMovementId,
        name: "Squat",
        category: MovementCategory.strength,
        description:
            "A squat is a strength exercise in which the trainee lowers their hips from a standing position and then stands back up."),
    Movement(
        deleted: false,
        userId: null,
        id: repo.nextMovementId,
        name: "Deadlift",
        category: MovementCategory.strength,
        description:
            "The deadlift is a weight training exercise in which a loaded barbell or bar is lifted off the ground to the level of the hips, torso perpendicular to the floor, before being placed back on the ground. It is one of the three powerlifting exercises, along with the squat and bench press."),
    Movement(
        deleted: false,
        userId: null,
        id: repo.nextMovementId,
        name: "Bench Press",
        category: MovementCategory.cardio,
        description:
            "The bench press, or chest press, is an upper-body weight training exercise in which the trainee presses a weight upwards while lying on a weight training bench. The exercise uses the pectoralis major, the anterior deltoids, and the triceps, among other stabilizing muscles. A barbell is generally used to hold the weight, but a pair of dumbbells can also be used."),
    Movement(
        deleted: false,
        userId: null,
        id: repo.nextMovementId,
        name: "Crunch",
        category: MovementCategory.strength,
        description:
            "The crunch is one of the most popular abdominal exercises. When performed properly, it engages all the abdominal muscles but primarily it works the rectus abdominis muscle and the obliques. It allows both building six-pack abs, and tightening the belly."),
    Movement(
        deleted: false,
        userId: null,
        id: repo.nextMovementId,
        name: "Rows",
        category: MovementCategory.strength,
        description: null),
    Movement(
        deleted: false,
        userId: null,
        id: repo.nextMovementId,
        name: "Dip",
        category: MovementCategory.strength,
        description:
            "A dip is an upper-body strength exercise. Narrow, shoulder-width dips primarily train the triceps, with major synergists being the anterior deltoid, the pectoralis muscles (sternal, clavicular, and minor), and the rhomboid muscles of the back (in that order)."),
    Movement(
        deleted: false,
        userId: null,
        id: repo.nextMovementId,
        name: "Push up",
        category: MovementCategory.strength,
        description:
            "A push-up (sometimes called a press-up in British English) is a common calisthenics exercise beginning from the prone position. By raising and lowering the body using the arms, push-ups exercise the pectoral muscles, triceps, and anterior deltoids, with ancillary benefits to the rest of the deltoids, serratus anterior, coracobrachialis and the midsection as a whole."),
    Movement(
        deleted: false,
        userId: null,
        id: repo.nextMovementId,
        name: "Pull up",
        category: MovementCategory.strength,
        description:
            "A pull-up is an upper-body strength exercise. The pull-up is a closed-chain movement where the body is suspended by the hands and pulls up. As this happens, the elbows flex and the shoulders adduct and extend to bring the elbows to the torso."),
    Movement(
        deleted: false,
        userId: null,
        id: repo.nextMovementId,
        name: "Plank",
        category: MovementCategory.strength,
        description:
            "The plank (also called a front hold, hover, or abdominal bridge) is an isometric core strength exercise that involves maintaining a position similar to a push-up for the maximum possible time."),
    Movement(
        deleted: false,
        userId: null,
        id: repo.nextMovementId,
        name: "Lunge",
        category: MovementCategory.strength,
        description: null),
    Movement(
        deleted: false,
        userId: null,
        id: repo.nextMovementId,
        name: "Calf Raises",
        category: MovementCategory.strength,
        description:
            "Calf raises are a method of exercising the gastrocnemius, tibialis posterior, peroneals and soleus muscles of the lower leg. The movement performed is plantar flexion, a.k.a. ankle extension."),
    Movement(
        deleted: false,
        userId: null,
        id: repo.nextMovementId,
        name: "Biceps Curl",
        category: MovementCategory.strength,
        description:
            "The term 'biceps curl' refers to any of a number of weight training exercises that primarily targets the biceps brachii muscle. It may be performed using a barbell, dumbbell, resistance band, or other equipment."),
    Movement(
        deleted: false,
        userId: null,
        id: repo.nextMovementId,
        name: "Veeeeeeeeeeeeeery Loooooooong Naaaaaaame",
        category: MovementCategory.cardio,
        description: ""),
    Movement(
        deleted: false,
        userId: null,
        id: repo.nextMovementId,
        name: "V e e e e e e e e r y  L o o o o o o n g  N a a a a a m e",
        category: MovementCategory.cardio,
        description: ""),
  ];
}
