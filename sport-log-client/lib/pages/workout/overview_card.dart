import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/comments_box.dart';

class OverviewCard extends StatelessWidget {
  const OverviewCard({
    required this.datetime,
    required this.left,
    required this.right,
    required this.comments,
    required this.onTap,
    required this.onLongPress,
    this.dateOnly = false,
    super.key,
  });

  final DateTime datetime;
  final List<Widget> left;
  final List<Widget> right;
  final String? comments;
  final void Function() onTap;
  final void Function()? onLongPress;
  final bool dateOnly;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: Defaults.edgeInsets.normal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateOnly
                              ? datetime.humanDate
                              : datetime.humanDateTime,
                        ),
                        if (left.isNotEmpty) ...[
                          Defaults.sizedBox.vertical.normal,
                          ...left,
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: right,
                    ),
                  ),
                ],
              ),
              if (comments != null) ...[
                const Divider(),
                CommentsBox(comments: comments!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
