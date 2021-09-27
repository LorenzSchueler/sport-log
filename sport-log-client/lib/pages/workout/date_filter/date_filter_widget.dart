import 'package:flutter/material.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/helpers/typedefs.dart';
import 'package:sport_log/widgets/form_widgets/repeat_icon_button.dart';

import 'date_filter_state.dart';

class DateFilter extends StatefulWidget {
  const DateFilter({
    Key? key,
    required this.initialState,
    required this.onFilterChanged,
  }) : super(key: key);

  final DateFilterState initialState;
  final ChangeCallback<DateFilterState> onFilterChanged;

  @override
  _DateFilterState createState() => _DateFilterState();
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
    setState(() => _state = widget.initialState);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final onAppBar = appBarForegroundOf(context);
    return Row(
      mainAxisAlignment: _state is NoFilter
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceBetween,
      children: [
        if (_state is! NoFilter)
          RepeatIconButton(
            icon: const Icon(Icons.arrow_back_ios_sharp),
            onClick: () {
              _state = _state.earlier;
              widget.onFilterChanged(_state);
            },
            onRepeat: () => setState(() => _state = _state.earlier),
            onRepeatEnd: () => widget.onFilterChanged(_state),
            color: onAppBar,
          ),
        TextButton.icon(
          icon: Text(
            _state.label,
            style: TextStyle(
              color: onAppBar,
            ),
          ),
          label: Icon(
            Icons.arrow_drop_down_sharp,
            color: onAppBar,
          ),
          onPressed: () {
            showDialog<void>(context: context, builder: _datePickerBuilder);
          },
        ),
        if (_state is! NoFilter)
          RepeatIconButton(
            icon: const Icon(Icons.arrow_forward_ios_sharp),
            onClick: () {
              _state = _state.later;
              widget.onFilterChanged(_state);
            },
            onRepeat: () => setState(() => _state = _state.later),
            onRepeatEnd: () => widget.onFilterChanged(_state),
            color: onAppBar,
            enabled: _state.goingForwardPossible,
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
                Navigator.of(context).pop();
              },
              selected: selected,
            );
          }).toList(),
        ),
      ),
    );
  }
}