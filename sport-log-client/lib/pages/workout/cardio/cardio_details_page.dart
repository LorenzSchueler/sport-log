import 'package:flutter/material.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';

class CardioDetailsPage extends StatefulWidget {
  final CardioSession cardioSession;

  const CardioDetailsPage({Key? key, required this.cardioSession})
      : super(key: key);

  @override
  State<CardioDetailsPage> createState() => CardioDetailsPageState();
}

class CardioDetailsPageState extends State<CardioDetailsPage> {
  final _logger = Logger('CardioDetailsPage');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Cardio Details"),
          actions: const [IconButton(onPressed: null, icon: Icon(Icons.save))],
        ),
        body: const Center(child: Text("not implemented")));
  }
}
