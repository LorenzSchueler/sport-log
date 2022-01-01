import 'package:flutter/material.dart';
import 'package:sport_log/widgets/form_widgets/edit_tile.dart';

class TextTile extends StatelessWidget {
  const TextTile({
    Key? key,
    required this.child,
    this.leading,
    this.caption,
  }) : super(key: key);

  final String? caption;
  final Widget child;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) leading!,
        if (leading != null)
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
              style:
                  Theme.of(context).textTheme.subtitle1!.copyWith(color: null),
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ],
    );
  }
}
