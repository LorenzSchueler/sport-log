import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/strength_sessions/new_set_input.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/duration_input.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/picker/datetime_picker.dart';
import 'package:sport_log/widgets/picker/movement_picker.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/widgets/input_fields/text_tile.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';

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
  final _dataProvider = StrengthSessionDescriptionDataProvider();

  late final StrengthSessionDescription _strengthSessionDescription;

  final _commentsNode = FocusNode();
  final _scrollController = ScrollController();
  late final StreamSubscription<bool> _keyboardSubscription;

  @override
  void initState() {
    super.initState();
    _strengthSessionDescription = widget.strengthSessionDescription?.clone() ??
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
    if (result.isSuccess()) {
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
        text: 'Creating Strength Session failed:\n${result.failure}',
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
    return DiscardWarningOnPop(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.strengthSessionDescription != null
                ? "Edit Strength Session"
                : "Create Strength Session",
          ),
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
          padding: Defaults.edgeInsets.normal,
          child: ListView(
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
                onNewSet: (count, weight, _, __) {
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
                    _strengthSessionDescription.orderSets();
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
                confirmChanges: true,
                dimension: _strengthSessionDescription.movement.dimension,
                editWeightUnit: false,
                distanceUnit: DistanceUnit.m,
                editDistanceUnit: false,
              ),
              const Divider(),
              Expanded(child: _setList),
            ],
          ),
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
        final movement = await showMovementPicker(context: context);
        if (movement != null) {
          setState(() {
            _strengthSessionDescription.session.movementId = movement.id;
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
          Text(_strengthSessionDescription.session.datetime.toHumanDateTime()),
      leading: AppIcons.calendar,
      onTap: () async {
        final datetime = await showDateTimePicker(
          context: context,
          initial: _strengthSessionDescription.session.datetime,
        );
        if (datetime != null) {
          setState(() {
            _strengthSessionDescription.session.datetime = datetime;
          });
        }
      },
    );
  }

  Widget get _intervalInput {
    assert(_strengthSessionDescription.session.interval != null);
    return EditTile(
      caption: 'Interval',
      child: DurationInput(
        setDuration: (d) =>
            setState(() => _strengthSessionDescription.session.interval = d),
        initialDuration: _strengthSessionDescription.session.interval!,
      ),
      leading: AppIcons.timeInterval,
      onCancel: () =>
          setState(() => _strengthSessionDescription.session.interval = null),
    );
  }

  Widget get _commentInput {
    assert(_strengthSessionDescription.session.comments != null);
    return TextFormField(
      focusNode: _commentsNode,
      keyboardType: TextInputType.multiline,
      minLines: 1,
      maxLines: 5,
      onChanged: (text) {
        setState(() => _strengthSessionDescription.session.comments = text);
      },
      initialValue: _strengthSessionDescription.session.comments,
      decoration: Theme.of(context).textFormFieldDecoration.copyWith(
            labelText: 'Comment',
            icon: const Icon(AppIcons.edit),
            suffixIcon: IconButton(
              onPressed: () => setState(
                () => _strengthSessionDescription.session.comments = null,
              ),
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
    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      itemBuilder: (context, index) =>
          _setWidget(_strengthSessionDescription.sets[index]),
      itemCount: _strengthSessionDescription.sets.length,
    );
  }

  Widget _setWidget(StrengthSet strengthSet) {
    return TextTile(
      caption: "Set ${strengthSet.setNumber + 1}",
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
