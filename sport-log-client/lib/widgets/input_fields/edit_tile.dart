import 'package:flutter/material.dart';
import 'package:sport_log/widgets/app_icons.dart';

class CaptionTile extends StatelessWidget {
  const CaptionTile({required this.caption, super.key});

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
    required this.child,
    required this.leading,
    this.caption,
    this.onTap,
    this.onCancel,
    this.shrink = false,
    super.key,
  });

  final String? caption;
  final Widget child;
  final IconData? leading;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  /// if enabled [child] must have a bounded width
  final bool shrink;

  Widget _captionChildColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (caption != null) CaptionTile(caption: caption!),
        DefaultTextStyle(
          style: Theme.of(context).textTheme.subtitle1!,
          child: child,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: shrink ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (leading != null) ...[
            Icon(leading, color: Colors.white70),
            const SizedBox(width: 15),
          ],
          shrink
              ? _captionChildColumn(context)
              : Expanded(child: _captionChildColumn(context)),
          if (onCancel != null)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onCancel,
              icon: const Icon(
                AppIcons.close,
              ),
            ),
        ],
      ),
    );
  }
}
