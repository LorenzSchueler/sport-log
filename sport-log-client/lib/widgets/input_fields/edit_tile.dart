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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          if (leading != null) ...[
            Icon(leading, color: Colors.white70),
            const SizedBox(width: 15),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (caption != null) CaptionTile(caption: caption!),
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.subtitle1!,
                  child: child,
                ),
              ],
            ),
          ),
          if (onCancel != null) ...[
            const Spacer(),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onCancel,
              icon: const Icon(
                AppIcons.close,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
