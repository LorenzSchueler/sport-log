import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/widgets/form_widgets/int_picker.dart';

class DiaryEditPage extends StatefulWidget {
  const DiaryEditPage({Key? key}) : super(key: key);

  @override
  State<DiaryEditPage> createState() => DiaryEditPageState();
}

class DiaryEditPageState extends State<DiaryEditPage> {
  final _logger = Logger('DiaryEditPage');

  double? _bodyweight;
  String? _comments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Diary Entry"),
        actions: const [IconButton(onPressed: null, icon: Icon(Icons.save))],
      ),
      body: Column(
        children: [
          const Text("date picker goes here"),
          TextField(
            decoration: const InputDecoration(labelText: "Bodyweight"),
            keyboardType: TextInputType.number,
            onSubmitted: (bodyweight) => _bodyweight = double.parse(bodyweight),
          ),
          TextField(
            decoration: const InputDecoration(labelText: "Comments"),
            keyboardType: TextInputType.multiline,
            minLines: 1,
            maxLines: 5,
            onSubmitted: (comments) => _comments = comments,
          )
        ],
      ),
    );
  }
}
