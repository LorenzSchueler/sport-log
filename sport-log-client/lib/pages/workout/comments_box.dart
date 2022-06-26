import 'package:flutter/material.dart';

class CommentsBox extends StatelessWidget {
  const CommentsBox({required this.comments, super.key});

  final String comments;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 80),
      child: SingleChildScrollView(
        child: Text(comments, textAlign: TextAlign.left),
      ),
    );
  }
}
