import 'package:flutter/material.dart';
import 'package:sport_log/widgets/app_icons.dart';

class CaptionTile extends StatelessWidget {
  const CaptionTile({Key? key, required this.caption}) : super(key: key);

  final String caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Text(
        caption,
        style: const TextStyle(color: Colors.white70),
        //Theme.of(context).colorScheme.onBackground),
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
  final IconData? leading;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final widget = Row(
      children: [
        if (leading != null) ...[
          Icon(leading, color: Colors.white70),
          const SizedBox(width: 15),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (caption != null)
              CaptionTile(
                caption: caption!,
              ),
            AnimatedDefaultTextStyle(
              child: child,
              style: Theme.of(context).textTheme.subtitle1!,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
        if (onCancel != null) ...[
          const Spacer(),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(
              AppIcons.close,
            ),
          ),
        ]
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
