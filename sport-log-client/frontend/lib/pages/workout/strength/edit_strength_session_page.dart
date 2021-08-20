
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/models/all.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';

class EditStrengthSessionPage extends StatefulWidget {
  const EditStrengthSessionPage({
    Key? key,
    StrengthSessionDescription? description,
  }) : initial = description, super(key: key);

  final StrengthSessionDescription? initial;

  @override
  State<StatefulWidget> createState() => _EditStrengthSessionPageState();
}

class _EditStrengthSessionPageState extends State<EditStrengthSessionPage> {

  late StrengthSessionDescription ssd;
  late bool movementInitialized;
  final scaffoldState = GlobalKey<ScaffoldState>();
  late bool datetimeIsNow;

  @override
  void initState() {
    super.initState();
    final userId = Api.instance.currentUser!.id;
    ssd = widget.initial ?? StrengthSessionDescription(
      strengthSession: StrengthSession(
          id: randomId(),
          userId: userId,
          datetime: DateTime.now(),
          movementId: Int64(0),
          movementUnit: MovementUnit.reps,
          interval: null,
          comments: null,
          deleted: false
      ),
      strengthSets: [],
      movement: Movement(
          id: Int64(1),
          userId: userId,
          name: "",
          description: null,
          category: MovementCategory.strength,
          deleted: false
      ),
    );
    movementInitialized = widget.initial != null;
    datetimeIsNow = widget.initial == null ? true : false;
  }
  
  void _submit() {
    if (!_formIsValid()) {
      return;
    }
    if (datetimeIsNow) {
      setState(() {
        ssd.strengthSession.datetime = DateTime.now();
      });
    }
  }

  bool _formIsValid() {
    return ssd.isValid() && movementInitialized;
  }

  void _setDateTimeNow() {
    setState(() {
      ssd.strengthSession.datetime = DateTime.now();
      datetimeIsNow = true;
    });
  }

  void _setDate(DateTime date) {
    int hour = ssd.strengthSession.datetime.hour;
    int minute = ssd.strengthSession.datetime.minute;
    setState(() {
      ssd.strengthSession.datetime = DateTime(
          date.year, date.month, date.day, hour, minute);
      datetimeIsNow = false;
    });
  }
  
  void _setTime(TimeOfDay time) {
    int year = ssd.strengthSession.datetime.year;
    int month = ssd.strengthSession.datetime.month;
    int day = ssd.strengthSession.datetime.day;
    setState(() {
      ssd.strengthSession.datetime = DateTime(year, month, day, time.hour, time.minute);
      datetimeIsNow = false;
    });
  }

  void _pickDateAndTime() async {
    final date = await showRoundedDatePicker(
      styleDatePicker: MaterialRoundedDatePickerStyle(
        paddingMonthHeader: const EdgeInsets.only(top: 15),
      ),
      context: context,
      initialDate: ssd.strengthSession.datetime,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      theme: ThemeData.dark(),
      // height: 350,
      textActionButton: "Set today",
      onTapActionButton: () {
        _setDate(DateTime.now());
        Navigator.of(context).pop();
      },
    );
    if (date != null) {
      _setDate(date);
    }
    final time = await showRoundedTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(ssd.strengthSession.datetime),
      theme: ThemeData.dark(),
      leftBtn: "Set now",
      onLeftBtn: () {
        final oldDate = ssd.strengthSession.datetime;
        final today = DateTime.now();
        if (oldDate.year == today.year
            && oldDate.month == today.month
            && oldDate.day == today.day) {
          _setDateTimeNow();
        } else {
          _setTime(TimeOfDay.now());
        }
        Navigator.of(context).pop();
      }
    );
    if (time != null) {
      _setTime(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldState,
      appBar: AppBar(
        title: Text(widget.initial == null ? "New Strength Session" : "EditStrengthSession"),
      ),
      body: _buildForm(context),
    );
  }
  
  Widget _buildForm(BuildContext context) {
    final datetimeStr = DateFormat('dd.MM.yyyy HH:mm')
        .format(ssd.strengthSession.datetime);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Form(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(datetimeIsNow ? 'now' : datetimeStr),
              onTap: _pickDateAndTime,
            ),
          ],
        )
      )
    );
  }
}