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
        style: const TextStyle(color: EditTile.iconCaptionColor),
      ),
    );
  }
}

/// A container with a style similar to TextFormField with style ThemeDataExtension.textFormFieldDecoration
class EditTile extends StatelessWidget {
  const EditTile({
    required this.child,
    required this.leading,
    this.caption,
    this.onTap,
    this.onCancel,
    this.unboundedHeight = false,
    this.shrinkWidth = false,
    super.key,
  });

  final String? caption;
  final Widget child;
  final IconData? leading;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  /// if enabled [child] must have a bounded height
  final bool unboundedHeight;

  /// if enabled [child] must have a bounded width
  final bool shrinkWidth;

  static const Color iconCaptionColor = Colors.white70;

  Widget _captionChildColumn(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (caption != null) CaptionTile(caption: caption!),
        DefaultTextStyle(
          style: Theme.of(context).textTheme.titleMedium!,
          child: child,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null
          ? () {
              FocusManager.instance.primaryFocus?.unfocus();
              onTap!();
            }
          : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: unboundedHeight ? null : 49, // height of TextFormField
        child: Row(
          mainAxisSize: shrinkWidth ? MainAxisSize.min : MainAxisSize.max,
          children: [
            if (leading != null) ...[
              Icon(leading, color: iconCaptionColor),
              const SizedBox(width: 15),
            ],
            shrinkWidth
                ? _captionChildColumn(context)
                : Expanded(child: _captionChildColumn(context)),
            if (onCancel != null)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onCancel != null
                    ? () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        onCancel!();
                      }
                    : null,
                icon: const Icon(AppIcons.close),
              ),
          ],
        ),
      ),
    );
  }
}
