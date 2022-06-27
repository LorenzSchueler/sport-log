import 'package:flutter/material.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/repeat_icon_button.dart';

class DateFilter extends StatefulWidget {
  const DateFilter({
    required this.initialState,
    required this.onFilterChanged,
    super.key,
  });

  final DateFilterState initialState;
  final void Function(DateFilterState) onFilterChanged;

  @override
  State<DateFilter> createState() => _DateFilterState();
}

class _DateFilterState extends State<DateFilter> {
  late DateFilterState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  @override
  void didUpdateWidget(covariant DateFilter oldWidget) {
    _state = widget.initialState;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final onAppBar = Theme.of(context).appBarTheme.foregroundColor!;
    return Row(
      mainAxisAlignment: _state is NoFilter
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceBetween,
      children: [
        if (_state is! NoFilter)
          RepeatIconButton(
            icon: const Icon(AppIcons.arrowBackOpen),
            onClick: () {
              setState(() => _state = _state.earlier);

              widget.onFilterChanged(_state);
            },
            color: onAppBar,
          ),
        TextButton.icon(
          icon: Text(
            _state.label,
            style: TextStyle(color: onAppBar),
          ),
          label: Icon(
            AppIcons.arrowDropDown,
            color: onAppBar,
          ),
          onPressed: () {
            showDialog<void>(context: context, builder: _datePickerBuilder);
          },
        ),
        if (_state is! NoFilter)
          RepeatIconButton(
            icon: const Icon(AppIcons.arrowForwardOpen),
            onClick: _state.goingForwardPossible
                ? () {
                    setState(() => _state = _state.later);
                    widget.onFilterChanged(_state);
                  }
                : null,
            color: onAppBar,
          ),
      ],
    );
  }

  Widget _datePickerBuilder(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DayFilter.current(),
            WeekFilter.current(),
            MonthFilter.current(),
            YearFilter.current(),
            const NoFilter()
          ].map((filter) {
            final selected = filter == _state;
            return ListTile(
              title: Center(child: Text(filter.name)),
              onTap: () {
                setState(() => _state = filter);
                widget.onFilterChanged(_state);
                Navigator.pop(context);
              },
              selected: selected,
            );
          }).toList(),
        ),
      ),
    );
  }
}
