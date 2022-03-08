import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/diary_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/diary/diary.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/picker/date_picker.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';

class DiaryEditPage extends StatefulWidget {
  final Diary? diary;
  const DiaryEditPage({Key? key, this.diary}) : super(key: key);

  @override
  State<DiaryEditPage> createState() => DiaryEditPageState();
}

class DiaryEditPageState extends State<DiaryEditPage> {
  final _logger = Logger('DiaryEditPage');
  final _formKey = GlobalKey<FormState>();
  final _dataProvider = DiaryDataProvider.instance;

  late Diary _diary;

  @override
  void initState() {
    _diary = widget.diary?.clone() ?? Diary.defaultValue();
    super.initState();
  }

  Future<void> _saveDiary() async {
    final result = widget.diary != null
        ? await _dataProvider.updateSingle(_diary)
        : await _dataProvider.createSingle(_diary);
    if (result) {
      _formKey.currentState!.deactivate();
      Navigator.pop(context);
    } else {
      await showMessageDialog(
        context: context,
        text: 'Creating Diary Entry failed.',
      );
    }
  }

  Future<void> _deleteDiary() async {
    if (widget.diary != null) {
      await _dataProvider.deleteSingle(_diary);
    }
    _formKey.currentState!.deactivate();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.diary != null ? "Edit Diary Entry" : "Create Diary Entry",
        ),
        actions: [
          IconButton(
            onPressed: _deleteDiary,
            icon: const Icon(AppIcons.delete),
          ),
          IconButton(
            onPressed: _formKey.currentContext != null &&
                    _formKey.currentState!.validate() &&
                    _diary.isValid()
                ? _saveDiary
                : null,
            icon: const Icon(AppIcons.save),
          ),
        ],
      ),
      body: Container(
        padding: Defaults.edgeInsets.normal,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              EditTile(
                leading: AppIcons.calendar,
                caption: "Date",
                child: Text(_diary.date.formatDate),
                onTap: () async {
                  DateTime? date = await showDatePickerWithDefaults(
                    context: context,
                    initialDate: _diary.date,
                  );
                  if (date != null) {
                    setState(() {
                      _diary.date = date;
                    });
                  }
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  icon: Icon(AppIcons.weight),
                  labelText: "Bodyweight",
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
                initialValue: _diary.bodyweight?.toStringAsFixed(1),
                validator: Validator.validateDoubleGtZero,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: const TextStyle(height: 1),
                keyboardType: TextInputType.number,
                onChanged: (bodyweight) {
                  if (Validator.validateDoubleGtZero(bodyweight) == null) {
                    setState(
                      () => _diary.bodyweight = double.parse(bodyweight),
                    );
                  }
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  icon: Icon(AppIcons.comment),
                  labelText: "Comments",
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
                initialValue: _diary.comments,
                style: const TextStyle(height: 1),
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 5,
                onChanged: (comments) =>
                    _diary.comments = comments.isEmpty ? null : comments,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
