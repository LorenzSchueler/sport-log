import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/pages/workout/strength_sessions/new_set_input.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/form_widgets/duration_picker.dart';
import 'package:sport_log/widgets/form_widgets/edit_tile.dart';
import 'package:sport_log/widgets/form_widgets/int_picker.dart';
import 'package:sport_log/widgets/movement_picker.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';

class StrengthSessionEditPage extends StatefulWidget {
  const StrengthSessionEditPage({
    Key? key,
    required this.initialSession,
  }) : super(key: key);

  final StrengthSessionWithSets initialSession;

  @override
  _StrengthSessionEditPageState createState() =>
      _StrengthSessionEditPageState();
}

class _StrengthSessionEditPageState extends State<StrengthSessionEditPage> {
  late final StrengthSessionWithSets _session;

  final _commentsNode = FocusNode();
  late final StreamSubscription<bool> _keyboardSubscription;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession.copy();
    _keyboardSubscription =
        KeyboardVisibilityController().onChange.listen((isVisible) {
      if (!isVisible) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  @override
  void dispose() {
    _keyboardSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit session')),
      body: Column(
        children: [
          Expanded(
            child: Scrollbar(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _movementInput,
                    _dateTimeInput,
                    if (_session.session.interval != null) _intervalInput,
                    if (_session.session.comments != null) _commentInput,
                    if (_session.session.interval == null ||
                        _session.session.comments == null)
                      _buttonBar,
                    const CaptionTile(caption: 'Sets'),
                    _setList,
                  ],
                ),
              ),
            ),
          ),
          NewSetInput(
            dimension: _session.movement.dimension,
            onNewSet: (set) => setState(() => _session.sets.add(set)),
          ),
        ],
      ),
    );
  }

  Widget get _movementInput {
    return EditTile(
      caption: 'Movement',
      child: Text(
          '${_session.movement.name} (${_session.movement.dimension.displayName})'),
      leading: const Icon(CustomIcons.trending_up),
      onTap: () async {
        final maybeMovement = await showMovementPickerDialog(context);
        if (maybeMovement != null) {
          setState(() {
            _session.movement = maybeMovement;
          });
        }
      },
    );
  }

  Widget get _buttonBar {
    return ButtonBar(
      children: [
        if (_session.session.interval == null)
          ActionChip(
            label: const Text('Interval'),
            avatar: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _session.session.interval = const Duration(seconds: 90);
              });
            },
          ),
        if (_session.session.comments == null)
          ActionChip(
            label: const Text('Comment'),
            avatar: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _session.session.comments = '';
              });
              _commentsNode.requestFocus();
            },
          ),
      ],
    );
  }

  Widget get _dateTimeInput {
    return EditTile(
      caption: 'Date',
      child: Text(_session.session.datetime.toHumanWithTime()),
      leading: const Icon(Icons.calendar_today),
      onTap: () async {
        final maybeDate = await showRoundedDatePicker(
            context: context, theme: Theme.of(context));
        if (maybeDate != null) {
          final defaultTime = TimeOfDay.fromDateTime(_session.session.datetime);
          final maybeTime = await showRoundedTimePicker(
            context: context,
            initialTime: defaultTime,
            theme: Theme.of(context),
          );
          final newDateTime = maybeDate.withTime(maybeTime ?? defaultTime);
          setState(() {
            _session.session.datetime = newDateTime;
          });
        }
      },
    );
  }

  Widget get _intervalInput {
    assert(_session.session.interval != null);
    return EditTile(
      caption: 'Interval',
      child: DurationPicker(
        setDuration: (d) => setState(() => _session.session.interval = d),
        initialDuration: _session.session.interval!,
      ),
      leading: const Icon(CustomIcons.time_interval),
      onCancel: () {
        setState(() => _session.session.interval = null);
      },
    );
  }

  Widget get _commentInput {
    assert(_session.session.comments != null);
    return EditTile(
      caption: 'Comment',
      child: TextField(
        focusNode: _commentsNode,
        maxLines: null,
        onChanged: (text) {
          setState(() => _session.session.comments = text);
        },
        decoration: const InputDecoration(
          hintText: 'Add comment',
          enabledBorder: InputBorder.none,
        ),
      ),
      leading: const Icon(Icons.edit),
      onCancel: () {
        setState(() => _session.session.comments = null);
      },
    );
  }

  Widget get _setList {
    return ReorderableListView(
      buildDefaultDragHandles: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _session.sets.mapToLIndexed(_setToWidget),
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final set = _session.sets.removeAt(oldIndex);
          _session.sets.insert(newIndex, set);
        });
      },
    );
  }

  Widget _setToWidget(StrengthSet set, int index) {
    return Card(
      key: ValueKey(set.id),
      child: Row(
        children: [
          CircleAvatar(child: Text((index + 1).toString())),
          IntPicker(
            initialValue: set.count,
            setValue: (value) {
              setState(() {
                _session.sets[index].count = value;
              });
            },
          ),
          if (set.weight == null)
            ActionChip(
              label: const Text('Weight'),
              onPressed: () {
                _session.sets[index].weight = 20;
              },
              avatar: const Icon(Icons.add),
            ),
          if (set.weight != null) Text(set.weight.toString()),
        ],
      ),
    );
  }
}
