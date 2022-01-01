import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/pages/workout/strength_sessions/new_set_input.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/form_widgets/duration_picker.dart';
import 'package:sport_log/widgets/form_widgets/edit_tile.dart';
import 'package:sport_log/widgets/form_widgets/movement_picker.dart';
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
  final _scrollController = ScrollController();
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
        body: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Expanded(
                child: Scrollbar(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                onNewSet: (count, [weight]) {
                  final newSet = StrengthSet(
                    id: randomId(),
                    strengthSessionId: _session.session.id,
                    setNumber: _session.sets.length,
                    count: count,
                    weight: weight,
                    deleted: false,
                  );
                  setState(() {
                    _session.sets.add(newSet);
                  });
                  Future.delayed(
                      const Duration(milliseconds: 100),
                      () => _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.decelerate,
                          ));
                },
              ),
            ],
          ),
        ));
  }

  Widget get _movementInput {
    return EditTile(
      caption: 'Movement',
      child: Text(
          '${_session.movement.name} (${_session.movement.dimension.displayName})'),
      leading: const Icon(CustomIcons.trendingUp),
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
      leading: const Icon(CustomIcons.timeInterval),
      onCancel: () {
        setState(() => _session.session.interval = null);
      },
    );
  }

  Widget get _commentInput {
    assert(_session.session.comments != null);
    return TextFormField(
      focusNode: _commentsNode,
      maxLines: null,
      onChanged: (text) {
        setState(() => _session.session.comments = text);
      },
      decoration: const InputDecoration(
        labelText: 'Comment',
        icon: Icon(Icons.edit),
        contentPadding: EdgeInsets.symmetric(vertical: 5),
      ),
      onEditingComplete: () {
        _commentsNode.unfocus();
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
          _session.sets.forEachIndexed((set, index) {
            set.setNumber = index;
          });
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
          Text(set.toDisplayName(_session.movement.dimension)),
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
