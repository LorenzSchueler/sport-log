import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/set_input/new_set_input.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/input_fields/duration_input.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/picker/datetime_picker.dart';
import 'package:sport_log/widgets/picker/picker.dart';
import 'package:sport_log/widgets/pop_scopes.dart';

class StrengthEditPage extends StatefulWidget {
  const StrengthEditPage({
    required this.strengthSessionDescription,
    required this.isNew,
    super.key,
  });

  final StrengthSessionDescription strengthSessionDescription;
  final bool isNew;

  @override
  State<StrengthEditPage> createState() => _StrengthEditPageState();
}

class _StrengthEditPageState extends State<StrengthEditPage> {
  final _dataProvider = StrengthSessionDescriptionDataProvider();

  late final StrengthSessionDescription _strengthSessionDescription =
      widget.strengthSessionDescription.clone();

  final _commentsNode = FocusNode();
  final _scrollController = ScrollController();

  Future<void> _saveStrengthSession() async {
    final result = widget.isNew
        ? await _dataProvider.createSingle(_strengthSessionDescription)
        : await _dataProvider.updateSingle(_strengthSessionDescription);
    if (mounted) {
      if (result.isSuccess) {
        Navigator.pop(
          context,
          // needed for return to details page
          ReturnObject.isNew(widget.isNew, _strengthSessionDescription),
        );
      } else {
        await showMessageDialog(
          context: context,
          text:
              "${widget.isNew ? 'Creating' : 'Updating'} Strength Session failed:\n${result.failure}",
        );
      }
    }
  }

  Future<void> _deleteStrengthSession() async {
    final delete = await showDeleteWarningDialog(context, "Strength Session");
    if (!delete) {
      return;
    }
    if (!widget.isNew) {
      final result =
          await _dataProvider.deleteSingle(_strengthSessionDescription);
      if (mounted) {
        if (result.isSuccess) {
          Navigator.pop(
            context,
            // needed for return to details page
            ReturnObject.deleted(_strengthSessionDescription),
          );
        } else {
          await showMessageDialog(
            context: context,
            text: "Deleting Strength Session failed:\n${result.failure}",
          );
        }
      }
    } else if (mounted) {
      Navigator.pop(
        context,
        // needed for return to details page
        ReturnObject.deleted(_strengthSessionDescription),
      );
    }
  }

  void _addNewSet(int count, double? weight) {
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
  }

  @override
  Widget build(BuildContext context) {
    return DiscardWarningOnPop(
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.isNew ? 'Create' : 'Edit'} Strength Session"),
          actions: [
            IconButton(
              onPressed: _deleteStrengthSession,
              icon: const Icon(AppIcons.delete),
            ),
            IconButton(
              onPressed: _strengthSessionDescription.isValidBeforeSanitation()
                  ? _saveStrengthSession
                  : null,
              icon: const Icon(AppIcons.save),
            ),
          ],
        ),
        body: Padding(
          padding: Defaults.edgeInsets.normal,
          child: Column(
            children: [
              _movementInput,
              _dateTimeInput,
              _intervalInput,
              _commentInput,
              const Divider(),
              NewSetInput(
                onNewSet: (count, weight, _, __) => _addNewSet(count, weight),
                confirmChanges: true,
                dimension: _strengthSessionDescription.movement.dimension,
                editWeightUnit: false,
                distanceUnit: DistanceUnit.m,
                editDistanceUnit: false,
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  shrinkWrap: true,
                  itemBuilder: (context, index) =>
                      _setWidget(_strengthSessionDescription.sets[index]),
                  itemCount: _strengthSessionDescription.sets.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget get _movementInput {
    return EditTile(
      caption: 'Movement',
      leading: AppIcons.movement,
      onTap: () async {
        final movement = await showMovementPicker(
          selectedMovement: _strengthSessionDescription.movement,
          context: context,
        );
        if (mounted && movement != null) {
          setState(() {
            _strengthSessionDescription.session.movementId = movement.id;
            _strengthSessionDescription.movement = movement;
          });
        }
      },
      child: Text(
        '${_strengthSessionDescription.movement.name} (${_strengthSessionDescription.movement.dimension.name})',
      ),
    );
  }

  Widget get _dateTimeInput {
    return EditTile(
      caption: 'Start Time',
      leading: AppIcons.calendar,
      onTap: () async {
        final datetime = await showDateTimePicker(
          context: context,
          initial: _strengthSessionDescription.session.datetime,
        );
        if (mounted && datetime != null) {
          setState(() {
            _strengthSessionDescription.session.datetime = datetime;
          });
        }
      },
      child:
          Text(_strengthSessionDescription.session.datetime.toHumanDateTime()),
    );
  }

  Widget get _intervalInput {
    return EditTile.optionalButton(
      caption: 'Interval',
      leading: AppIcons.timeInterval,
      onCancel: () =>
          setState(() => _strengthSessionDescription.session.interval = null),
      builder: () => DurationInput(
        onUpdate: (d) =>
            setState(() => _strengthSessionDescription.session.interval = d),
        initialDuration:
            _strengthSessionDescription.session.interval ?? Duration.zero,
        minDuration: const Duration(seconds: 1),
      ),
      showButton: _strengthSessionDescription.session.interval == null,
      onButtonPressed: () {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() {
          _strengthSessionDescription.session.interval =
              StrengthSession.defaultInterval;
        });
      },
    );
  }

  Widget get _commentInput {
    return OptionalTextFormField(
      textFormField: TextFormField(
        focusNode: _commentsNode,
        keyboardType: TextInputType.multiline,
        minLines: 1,
        maxLines: 5,
        onChanged: (text) {
          setState(() => _strengthSessionDescription.session.comments = text);
        },
        initialValue: _strengthSessionDescription.session.comments,
        decoration: InputDecoration(
          labelText: 'Comment',
          icon: const Icon(AppIcons.edit),
          suffixIcon: IconButton(
            onPressed: () => setState(
              () => _strengthSessionDescription.session.comments = null,
            ),
            icon: const Icon(AppIcons.close),
          ),
        ),
      ),
      showTextFormField: _strengthSessionDescription.session.comments != null,
      leading: AppIcons.edit,
      buttonText: 'Comment',
      onButtonPressed: () {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() {
          _strengthSessionDescription.session.comments = '';
        });
        _commentsNode.requestFocus();
      },
    );
  }

  Widget _setWidget(StrengthSet strengthSet) {
    return EditTile(
      leading: null,
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
