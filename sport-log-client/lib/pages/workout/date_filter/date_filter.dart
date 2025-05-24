import 'package:flutter/material.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/repeat_icon_button.dart';
import 'package:sport_log/widgets/picker/picker.dart';

class DateFilter extends StatefulWidget implements PreferredSizeWidget {
  const DateFilter({
    required this.initialState,
    required this.onFilterChanged,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(34); // height of Row

  final DateFilterState initialState;
  final void Function(DateFilterState) onFilterChanged;

  @override
  State<DateFilter> createState() => _DateFilterState();
}

class _DateFilterState extends State<DateFilter> {
  late DateFilterState _dateFilterState = widget.initialState;

  @override
  void didUpdateWidget(DateFilter oldWidget) {
    _dateFilterState = widget.initialState;
    super.didUpdateWidget(oldWidget);
  }

  void setDateFilterState(DateFilterState dateFilterState) {
    if (mounted) {
      setState(() => _dateFilterState = dateFilterState);
      widget.onFilterChanged(_dateFilterState);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBarColor = Theme.of(context).appBarTheme.foregroundColor!;
    return Row(
      mainAxisAlignment: _dateFilterState is AllFilter
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceBetween,
      children: [
        if (_dateFilterState is! AllFilter)
          RepeatIconButton(
            icon: const Icon(AppIcons.arrowLeft),
            onClick: () => setDateFilterState(_dateFilterState.earlier),
            color: appBarColor,
          ),
        TextButton.icon(
          icon: Text(
            _dateFilterState.label,
            style: TextStyle(color: appBarColor),
          ),
          label: Icon(AppIcons.arrowDropDown, color: appBarColor),
          // ignore: prefer-extracting-callbacks
          onPressed: () async {
            final dateFilterState = await showDateFilterStatePicker(
              selectedDateFilterState: _dateFilterState,
              context: context,
            );
            if (dateFilterState != null) {
              setDateFilterState(dateFilterState);
            }
          },
        ),
        if (_dateFilterState is! AllFilter)
          RepeatIconButton(
            icon: const Icon(AppIcons.arrowRight),
            onClick: _dateFilterState.goingForwardPossible
                ? () => setDateFilterState(_dateFilterState.later)
                : null,
            color: appBarColor,
          ),
      ],
    );
  }
}
