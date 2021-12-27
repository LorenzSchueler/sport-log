import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/diary/diary.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/pages/workout/session_tab_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/movement_picker.dart';
import 'package:sport_log/widgets/value_unit_description.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({Key? key}) : super(key: key);

  @override
  State<DiaryPage> createState() => DiaryPageState();
}

class DiaryPageState extends State<DiaryPage> {
  final _logger = Logger('DiaryPage');

  final List<Diary> _diaries = [
    Diary(
        id: randomId(),
        userId: UserState.instance.currentUser!.id,
        date: DateTime.now(),
        bodyweight: null,
        comments: null,
        deleted: false),
    Diary(
        id: randomId(),
        userId: UserState.instance.currentUser!.id,
        date: DateTime.now().subtract(const Duration(days: 1)),
        bodyweight: 78.3,
        comments: null,
        deleted: false),
    Diary(
        id: randomId(),
        userId: UserState.instance.currentUser!.id,
        date: DateTime.now().subtract(const Duration(days: 2)),
        bodyweight: null,
        comments: "bla bli\nblub\n..la",
        deleted: false),
    Diary(
        id: randomId(),
        userId: UserState.instance.currentUser!.id,
        date: DateTime.now().subtract(const Duration(days: 3)),
        bodyweight: 80.0,
        comments: "bla",
        deleted: false),
    Diary(
        id: randomId(),
        userId: UserState.instance.currentUser!.id,
        date: DateTime.now().subtract(const Duration(days: 5)),
        bodyweight: 180.0,
        comments:
            "very long line bc abc abc abc abc abc abc abc abc abc abc abc",
        deleted: false),
  ];

  DateFilterState _dateFilter = MonthFilter.current();
  Movement? _movement;
  final SessionsPageTab sessionsPageTab = SessionsPageTab.diary;
  final String route = Routes.diary.overview;
  final String defaultTitle = "Diary";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_movement?.name ?? defaultTitle),
        actions: [
          IconButton(
            onPressed: () async {
              final Movement? movement = await showMovementPickerDialog(context,
                  selectedMovement: _movement);
              if (movement == null) {
                return;
              } else if (movement.id == _movement?.id) {
                setState(() {
                  _movement = null;
                });
              } else {
                setState(() {
                  _movement = movement;
                });
              }
            },
            icon: Icon(_movement != null
                ? Icons.filter_alt
                : Icons.filter_alt_outlined),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: DateFilter(
            initialState: _dateFilter,
            onFilterChanged: (dateFilter) => setState(() {
              _dateFilter = dateFilter;
            }),
          ),
        ),
      ),
      body: Container(
          child: ListView.builder(
        itemBuilder: _buildDiaryEntry,
        itemCount: _diaries.length,
      )),
      bottomNavigationBar:
          SessionTabUtils.bottomNavigationBar(context, sessionsPageTab),
      drawer: MainDrawer(selectedRoute: route),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.of(context).pushNamed(Routes.diary.edit);
          }),
    );
  }

  Widget _buildDiaryEntry(BuildContext context, int index) {
    final Diary diary = _diaries[index];

    return GestureDetector(
        onTap: () {
          _showDetails(context, diary);
        },
        child: diaryCard(diary));
  }

  static Widget diaryCard(Diary diary) {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDate(diary.date),
                  style: const TextStyle(fontSize: 20),
                ),
                Defaults.sizedBox.horizontal.big,
                SizedBox(
                  width: 80,
                  child: diary.bodyweight != null
                      ? ValueUnitDescription(
                          value: diary.bodyweight!.toStringAsFixed(1),
                          unit: "kg",
                          description: null)
                      : null,
                ),
                Defaults.sizedBox.horizontal.big,
                Expanded(
                  child: Text(
                    diary.comments ?? "",
                    textAlign: TextAlign.start,
                    softWrap: true,
                  ),
                ),
              ],
            )));
  }

  void _showDetails(BuildContext context, Diary diary) {
    Navigator.of(context).pushNamed(Routes.diary.edit, arguments: diary);
  }
}
