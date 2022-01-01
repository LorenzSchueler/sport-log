import 'package:flutter/material.dart';
import 'package:sport_log/helpers/theme.dart';

class CaptionTile extends StatelessWidget {
  const CaptionTile({Key? key, required this.caption}) : super(key: key);

  final String caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Text(
        caption,
        style: TextStyle(color: Colors.grey.shade400),
      ),
    );
  }
}

class EditTile extends StatelessWidget {
  const EditTile({
    Key? key,
    required this.child,
    required this.leading,
    this.caption,
    this.onTap,
    this.onCancel,
  }) : super(key: key);

  final String? caption;
  final Widget child;
  final Widget leading;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final widget = Row(
      children: [
        leading,
        const SizedBox(
          width: 15,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (caption != null)
              CaptionTile(
                caption: caption!,
              ),
            AnimatedDefaultTextStyle(
              child: child,
              style: Theme.of(context).textTheme.subtitle1!.copyWith(
                  color: onTap == null ? null : primaryColorOf(context)),
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
        if (onCancel != null) const Spacer(),
        if (onCancel != null)
          IconButton(
              onPressed: onCancel,
              icon: const Icon(
                Icons.close,
              ))
      ],
    );

    if (onTap == null) {
      return widget;
    } else {
      return InkWell(
        onTap: onTap,
        child: widget,
      );
    }
  }
}
