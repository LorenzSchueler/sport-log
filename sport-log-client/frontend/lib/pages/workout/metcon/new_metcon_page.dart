
import 'package:flutter/material.dart';

class NewMetconPage extends StatefulWidget {
  const NewMetconPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NewMetconPageState();
}

class _NewMetconPageState extends State<NewMetconPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Metcon")),
      body: Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: const [
          ],
        ),
      ),
    );
  }
}