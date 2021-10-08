import 'package:flutter/material.dart';
import 'package:sport_log/helpers/theme.dart';

class CaptionTile extends StatelessWidget {
  const CaptionTile({Key? key, required this.caption}) : super(key: key);

  final String caption;

  @override
  Widget build(BuildContext context) {
    final captionStyle = Theme.of(context).textTheme.caption;
    return Padding(
      padding: const EdgeInsets.only(left: leftPadding, top: topPadding),
      child: SizedBox(
        width: double.infinity,
        child: Text(caption, style: captionStyle),
      ),
    );
  }

  static const double leftPadding = 16;
  static const double topPadding = 10;
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
    final widget = Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (caption != null) CaptionTile(caption: caption!),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 16,
                  bottom: 16,
                  right: 32,
                  left: CaptionTile.leftPadding,
                ),
                child: leading,
              ),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  child: child,
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                      color: onTap == null ? null : primaryColorOf(context)),
                  duration: const Duration(milliseconds: 200),
                ),
              ),
              if (onCancel != null)
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        ],
      ),
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
