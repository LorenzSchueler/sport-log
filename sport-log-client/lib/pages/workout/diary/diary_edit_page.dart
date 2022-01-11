import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/state/page_return.dart';
import 'package:sport_log/models/diary/diary.dart';
import 'package:sport_log/widgets/form_widgets/edit_tile.dart';

class DiaryEditPage extends StatefulWidget {
  final Diary? diary;
  const DiaryEditPage({Key? key, this.diary}) : super(key: key);

  @override
  State<DiaryEditPage> createState() => DiaryEditPageState();
}

class DiaryEditPageState extends State<DiaryEditPage> {
  final _logger = Logger('DiaryEditPage');

  late Diary _diary;

  @override
  void initState() {
    super.initState();
    _diary = widget.diary ??
        Diary(
            id: randomId(),
            userId: UserState.instance.currentUser!.id,
            date: DateTime.now(),
            bodyweight: null,
            comments: null,
            deleted: false);
  }

  void _saveDiary() {
    // TODO save in Db
    Navigator.of(context).pop(ReturnObject(
        action:
            widget.diary != null ? ReturnAction.updated : ReturnAction.created,
        payload: _diary));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Edit Diary Entry"), actions: [
          IconButton(
              onPressed: _diary.bodyweight != null || _diary.comments != null
                  ? _saveDiary
                  : null,
              icon: const Icon(Icons.save))
        ]),
        body: Container(
          padding: const EdgeInsets.all(10),
          child: ListView(
            children: [
              EditTile(
                  leading: Icons.crop,
                  caption: "Date",
                  child: Text(formatDate(_diary.date)),
                  onTap: () async {
                    DateTime? date = await showDatePicker(
                      context: context,
                      initialDate: _diary.date,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _diary.date = date;
                      });
                    }
                  }),
              TextFormField(
                decoration: const InputDecoration(
                  icon: Icon(Icons.crop),
                  labelText: "Bodyweight",
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
                initialValue: _diary.bodyweight?.toStringAsFixed(1),
                style: const TextStyle(height: 1),
                keyboardType: TextInputType.number,
                onFieldSubmitted: (bodyweight) =>
                    _diary.bodyweight = double.parse(bodyweight),
              ),
              TextFormField(
                decoration: const InputDecoration(
                  icon: Icon(Icons.crop),
                  labelText: "Comments",
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
                initialValue: _diary.comments,
                style: const TextStyle(height: 1),
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 5,
                onFieldSubmitted: (comments) => _diary.comments = comments,
              )
            ],
          ),
        ));
  }
}
