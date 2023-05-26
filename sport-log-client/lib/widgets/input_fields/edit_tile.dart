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

  // ignore: non_constant_identifier_names
  EditTile.Switch({
    required IconData? leading,
    String? caption,
    required bool value,
    required void Function(bool) onChanged,
    void Function()? onCancel,
    bool shrinkWidth = false,
    Key? key,
  }) : this(
          child: SizedBox(
            height: 29, // make it fit into EditTile
            width: 34, // remove left padding
            child: Switch(
              value: value,
              onChanged: (isSet) {
                FocusManager.instance.primaryFocus?.unfocus();
                onChanged(isSet);
              },
            ),
          ),
          leading: leading,
          caption: caption,
          onCancel: onCancel,
          shrinkWidth: shrinkWidth,
          key: key,
        );

  EditTile.optionalActionChip({
    required Widget Function() builder,
    required IconData leading,
    required String caption,
    required bool showActionChip,
    required void Function() onActionChipTap,
    void Function()? onTap,
    void Function()? onCancel,
    bool unboundedHeight = false,
    bool shrinkWidth = false,
    Key? key,
  }) : this(
          leading: leading,
          caption: showActionChip ? null : caption,
          onTap: showActionChip ? null : onTap,
          onCancel: showActionChip ? null : onCancel,
          unboundedHeight: showActionChip ? false : unboundedHeight,
          shrinkWidth: shrinkWidth,
          key: key,
          child: showActionChip
              ? ActionChip(
                  avatar: const Icon(AppIcons.add),
                  label: Text(caption),
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    onActionChipTap();
                  },
                )
              : builder(),
        );

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
            if (leading != null)
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Icon(leading, color: iconCaptionColor),
              ),
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
