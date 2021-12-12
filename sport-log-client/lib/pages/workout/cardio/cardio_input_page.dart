import 'package:flutter/material.dart';
import 'package:sport_log/helpers/logger.dart';

class CardioInputPage extends StatefulWidget {
  const CardioInputPage({Key? key}) : super(key: key);

  @override
  State<CardioInputPage> createState() => CardioInputPageState();
}

class CardioInputPageState extends State<CardioInputPage> {
  final _logger = Logger('CardioInputPage');

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
