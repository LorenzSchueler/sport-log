import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/pages/workout/strength_sessions/new_set_input.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/form_widgets/duration_picker.dart';
import 'package:sport_log/widgets/form_widgets/edit_tile.dart';
import 'package:sport_log/widgets/form_widgets/movement_picker.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/widgets/form_widgets/text_tile.dart';
import 'package:sport_log/widgets/message_dialog.dart';

class StrengthSessionEditPage extends StatefulWidget {
  const StrengthSessionEditPage({
    Key? key,
    required this.strengthSessionDescription,
  }) : super(key: key);

  final StrengthSessionDescription? strengthSessionDescription;

  @override
  _StrengthSessionEditPageState createState() =>
      _StrengthSessionEditPageState();
}

class _StrengthSessionEditPageState extends State<StrengthSessionEditPage> {
  final _logger = Logger("StrengthSessionEditPage");
  final _dataProvider = StrengthSessionDescriptionDataProvider.instance;

  late final StrengthSessionDescription _strengthSessionDescription;

  final _commentsNode = FocusNode();
  final _scrollController = ScrollController();
  late final StreamSubscription<bool> _keyboardSubscription;

  @override
  void initState() {
    super.initState();
    _strengthSessionDescription = widget.strengthSessionDescription ??
        StrengthSessionDescription.defaultValue();
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

  Future<void> _saveStrengthSession() async {
    final result = widget.strengthSessionDescription != null
        ? await _dataProvider.updateSingle(_strengthSessionDescription)
        : await _dataProvider.createSingle(_strengthSessionDescription);
    if (result) {
      Navigator.pop(
        context,
        ReturnObject(
          action: widget.strengthSessionDescription != null
              ? ReturnAction.updated
              : ReturnAction.created,
          payload: _strengthSessionDescription,
        ), // needed for return to details page
      );
    } else {
      await showMessageDialog(
        context: context,
        text: 'Creating Strength Session failed.',
      );
    }
  }

  Future<void> _deleteStrengthSession() async {
    if (widget.strengthSessionDescription != null) {
      await _dataProvider.deleteSingle(_strengthSessionDescription);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit session'),
        actions: [
          IconButton(
            onPressed: _deleteStrengthSession,
            icon: const Icon(AppIcons.delete),
          ),
          IconButton(
            onPressed: _strengthSessionDescription.isValid()
                ? _saveStrengthSession
                : null,
            icon: const Icon(AppIcons.save),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            _movementInput,
            _dateTimeInput,
            if (_strengthSessionDescription.session.interval != null)
              _intervalInput,
            if (_strengthSessionDescription.session.comments != null)
              _commentInput,
            if (_strengthSessionDescription.session.interval == null ||
                _strengthSessionDescription.session.comments == null)
              _buttonBar,
            NewSetInput(
              dimension: _strengthSessionDescription.movement.dimension,
              onNewSet: (count, weight) {
                final newSet = StrengthSet(
                  id: randomId(),
                  strengthSessionId: _strengthSessionDescription.session.id,
                  setNumber: _strengthSessionDescription.sets.length,
                  count: count,
                  weight: weight,
                  deleted: false,
                );
                setState(() {
                  _strengthSessionDescription.sets.add(newSet);
                });
                Future.delayed(
                  const Duration(milliseconds: 100),
                  () => _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.decelerate,
                  ),
                );
              },
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: _scrollController,
                children: [
                  _setList,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _movementInput {
    return EditTile(
      caption: 'Movement',
      child: Text(
        '${_strengthSessionDescription.movement.name} (${_strengthSessionDescription.movement.dimension.displayName})',
      ),
      leading: AppIcons.exercise,
      onTap: () async {
        final movement = await showMovementPickerDialog(context);
        if (movement != null) {
          setState(() {
            _strengthSessionDescription.movement = movement;
          });
        }
      },
    );
  }

  Widget get _buttonBar {
    return ButtonBar(
      children: [
        if (_strengthSessionDescription.session.interval == null)
          ActionChip(
            label: const Text('Interval'),
            avatar: const Icon(AppIcons.add),
            onPressed: () {
              setState(() {
                _strengthSessionDescription.session.interval =
                    const Duration(seconds: 90);
              });
            },
          ),
        if (_strengthSessionDescription.session.comments == null)
          ActionChip(
            label: const Text('Comment'),
            avatar: const Icon(AppIcons.add),
            onPressed: () {
              setState(() {
                _strengthSessionDescription.session.comments = '';
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
      child:
          Text(_strengthSessionDescription.session.datetime.toHumanWithTime()),
      leading: AppIcons.calendar,
      onTap: () async {
        final date = await showRoundedDatePicker(
          context: context,
          theme: Theme.of(context),
        );
        if (date != null) {
          final defaultTime = TimeOfDay.fromDateTime(
            _strengthSessionDescription.session.datetime,
          );
          final time = await showRoundedTimePicker(
            context: context,
            initialTime: defaultTime,
            theme: Theme.of(context),
          );
          final newDateTime = date.withTime(time ?? defaultTime);
          setState(() {
            _strengthSessionDescription.session.datetime = newDateTime;
          });
        }
      },
    );
  }

  Widget get _intervalInput {
    assert(_strengthSessionDescription.session.interval != null);
    return EditTile(
      caption: 'Interval',
      child: DurationPicker(
        setDuration: (d) =>
            setState(() => _strengthSessionDescription.session.interval = d),
        initialDuration: _strengthSessionDescription.session.interval!,
      ),
      leading: AppIcons.timeInterval,
      onCancel: () {
        setState(() => _strengthSessionDescription.session.interval = null);
      },
    );
  }

  Widget get _commentInput {
    assert(_strengthSessionDescription.session.comments != null);
    return TextFormField(
      focusNode: _commentsNode,
      maxLines: null,
      onChanged: (text) {
        setState(() => _strengthSessionDescription.session.comments = text);
      },
      initialValue: _strengthSessionDescription.session.comments,
      decoration: InputDecoration(
        labelText: 'Comment',
        icon: const Icon(AppIcons.edit),
        contentPadding: const EdgeInsets.symmetric(vertical: 5),
        suffixIcon: IconButton(
          onPressed: () async {
            setState(() => _strengthSessionDescription.session.comments = null);
          },
          icon: const Icon(AppIcons.close),
        ),
      ),
      onEditingComplete: () {
        _commentsNode.unfocus();
        setState(() => _strengthSessionDescription.session.comments = null);
      },
    );
  }

  Widget get _setList {
    return ReorderableListView(
      buildDefaultDragHandles: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _strengthSessionDescription.sets.mapToListIndexed(_setToWidget),
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final set = _strengthSessionDescription.sets.removeAt(oldIndex);
          _strengthSessionDescription.sets.insert(newIndex, set);
          _strengthSessionDescription.orderSets();
        });
      },
    );
  }

  Widget _setToWidget(StrengthSet strengthSet, int index) {
    return TextTile(
      key: ValueKey(strengthSet.id),
      caption: "Set ${index + 1}",
      onCancel: () => setState(() {
        _strengthSessionDescription.sets.remove(strengthSet);
        _strengthSessionDescription.orderSets();
      }),
      child: Text(
        strengthSet
            .toDisplayName(_strengthSessionDescription.movement.dimension),
      ),
    );
  }
}
