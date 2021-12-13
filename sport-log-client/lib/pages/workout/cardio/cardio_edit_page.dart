import 'package:flutter/material.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';

class CardioEditPage extends StatefulWidget {
  final CardioSession? cardioSession;

  const CardioEditPage({Key? key, this.cardioSession}) : super(key: key);

  @override
  State<CardioEditPage> createState() => CardioEditPageState();
}

class CardioEditPageState extends State<CardioEditPage> {
  final _logger = Logger('CardioEditPage');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Cardio Input"),
          actions: const [IconButton(onPressed: null, icon: Icon(Icons.save))],
        ),
        body: const Center(child: Text("not implemented")));
  }
}
