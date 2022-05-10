import 'package:flutter/material.dart';

class SelectionBar<T> extends StatelessWidget {
  const SelectionBar({
    Key? key,
    required this.onChange,
    required this.items,
    required this.getLabel,
    required this.selectedItem,
  }) : super(key: key);

  final void Function(T) onChange;
  final List<T> items;
  final String Function(T) getLabel;
  final T selectedItem;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: items.map((item) {
        final isSelected = item == selectedItem;
        return OutlinedButton(
          onPressed: isSelected ? () {} : () => onChange(item),
          style: isSelected
              ? OutlinedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  primary: Theme.of(context).colorScheme.onPrimary,
                )
              : OutlinedButton.styleFrom(
                  side: BorderSide.none,
                ),
          child: Text(getLabel(item)),
        );
      }).toList(),
    );
  }
}
