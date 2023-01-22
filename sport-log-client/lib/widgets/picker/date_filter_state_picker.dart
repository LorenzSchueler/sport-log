import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';

Future<DateFilterState?> showDateFilterStatePicker({
  required BuildContext context,
  required DateFilterState currentDateFilterState,
  bool dismissible = true,
}) async {
  return showDialog<DateFilterState>(
    builder: (_) => DateFilterStatePickerDialog(
      currentDateFilterState: currentDateFilterState,
    ),
    barrierDismissible: dismissible,
    context: context,
  );
}

class DateFilterStatePickerDialog extends StatelessWidget {
  const DateFilterStatePickerDialog({
    required this.currentDateFilterState,
    super.key,
  });

  final DateFilterState currentDateFilterState;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: ListView.separated(
          itemBuilder: (context, index) {
            final dateFilterState =
                DateFilterState.all[index](currentDateFilterState);
            return ListTile(
              title: Center(child: Text(dateFilterState.name)),
              onTap: () => Navigator.pop(context, dateFilterState),
              selected: dateFilterState == currentDateFilterState,
            );
          },
          itemCount: DateFilterState.all.length,
          separatorBuilder: (context, _) => const Divider(),
          shrinkWrap: true,
        ),
      ),
    );
  }
}
