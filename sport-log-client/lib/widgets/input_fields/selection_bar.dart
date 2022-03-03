import 'package:flutter/material.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/helpers/typedefs.dart';

class SelectionBar<T> extends StatelessWidget {
  const SelectionBar({
    Key? key,
    required this.onChange,
    required this.items,
    required this.getLabel,
    required this.selectedItem,
  }) : super(key: key);

  final ChangeCallback<T> onChange;
  final List<T> items;
  final String Function(T) getLabel;
  final T selectedItem;

  @override
  Widget build(BuildContext context) {
    final background = primaryColorOf(context);
    final primary = onPrimaryColorOf(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: items.map((item) {
        final isSelected = item == selectedItem;
        return OutlinedButton(
          onPressed: isSelected ? () {} : () => onChange(item),
          child: Text(getLabel(item)),
          style: isSelected
              ? OutlinedButton.styleFrom(
                  backgroundColor: background,
                  primary: primary,
                )
              : OutlinedButton.styleFrom(
                  side: BorderSide.none,
                ),
        );
      }).toList(),
    );
  }
}
