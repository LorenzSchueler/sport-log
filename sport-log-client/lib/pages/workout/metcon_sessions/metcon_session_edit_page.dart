import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/input_fields/duration_input.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/input_fields/int_input.dart';
import 'package:sport_log/widgets/picker/datetime_picker.dart';
import 'package:sport_log/widgets/picker/picker.dart';
import 'package:sport_log/widgets/pop_scopes.dart';

class MetconSessionEditPage extends StatefulWidget {
  const MetconSessionEditPage({
    required this.metconSessionDescription,
    required this.isNew,
    super.key,
  });

  final MetconSessionDescription metconSessionDescription;
  final bool isNew;

  @override
  State<MetconSessionEditPage> createState() => _MetconSessionEditPageState();
}

class _MetconSessionEditPageState extends State<MetconSessionEditPage> {
  final _logger = Logger('MetconSessionEditPage');
  final _formKey = GlobalKey<FormState>();
  final _dataProvider = MetconSessionDescriptionDataProvider();
  final _metconDescriptionDataProvider = MetconDescriptionDataProvider();

  late final MetconSessionDescription _metconSessionDescription =
      widget.metconSessionDescription.clone();
  late bool _finished = _metconSessionDescription.metconSession.time != null;

  Future<void> _saveMetconSession() async {
    _logger.i("saving metcon session: $_metconSessionDescription");
    final result = widget.isNew
        ? await _dataProvider.createSingle(_metconSessionDescription)
        : await _dataProvider.updateSingle(_metconSessionDescription);
    if (mounted) {
      if (result.isSuccess) {
        Navigator.pop(
          context,
          // needed for return to details page
          ReturnObject.isNew(widget.isNew, _metconSessionDescription),
        );
      } else {
        await showMessageDialog(
          context: context,
          text:
              "${widget.isNew ? 'Creating' : 'Updating'} Metcon Session failed:\n${result.failure}",
        );
      }
    }
  }

  Future<void> _deleteMetconSession() async {
    final delete = await showDeleteWarningDialog(context, "Metcon Session");
    if (!delete) {
      return;
    }
    if (!widget.isNew) {
      final result =
          await _dataProvider.deleteSingle(_metconSessionDescription);
      if (mounted) {
        if (result.isSuccess) {
          Navigator.pop(
            context,
            // needed for return to details page
            ReturnObject.deleted(_metconSessionDescription),
          );
        } else {
          await showMessageDialog(
            context: context,
            text: "Deleting Metcon Session failed:\n${result.failure}",
          );
        }
      }
    } else if (mounted) {
      Navigator.pop(
        context,
        // needed for return to details page
        ReturnObject.deleted(_metconSessionDescription),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DiscardWarningOnPop(
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.isNew ? 'Create' : 'Edit'} Metcon Session"),
          actions: [
            IconButton(
              onPressed: _deleteMetconSession,
              icon: const Icon(AppIcons.delete),
            ),
            IconButton(
              onPressed: _formKey.currentContext != null &&
                      _formKey.currentState!.validate() &&
                      _metconSessionDescription.isValidBeforeSanitation()
                  ? _saveMetconSession
                  : null,
              icon: const Icon(AppIcons.save),
            ),
          ],
        ),
        body: Padding(
          padding: Defaults.edgeInsets.normal,
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                EditTile(
                  leading: AppIcons.notes,
                  caption: "Metcon",
                  child: Text(
                    _metconSessionDescription.metconDescription.metcon.name,
                  ),
                  onTap: () async {
                    final metcon = await showMetconPicker(
                      selectedMetcon:
                          _metconSessionDescription.metconDescription.metcon,
                      context: context,
                    );
                    if (metcon != null) {
                      final metconDescription =
                          await _metconDescriptionDataProvider
                              .getByMetcon(metcon);
                      if (mounted) {
                        setState(() {
                          _metconSessionDescription.metconDescription =
                              metconDescription;
                          _metconSessionDescription.metconSession.metconId =
                              _metconSessionDescription
                                  .metconDescription.metcon.id;
                          switch (_metconSessionDescription
                              .metconDescription.metcon.metconType) {
                            case MetconType.amrap:
                              _metconSessionDescription.metconSession.time =
                                  null;
                              _metconSessionDescription.metconSession.rounds =
                                  0;
                              _metconSessionDescription.metconSession.reps = 0;
                            case MetconType.emom:
                              _metconSessionDescription.metconSession.time =
                                  null;
                              _metconSessionDescription.metconSession.rounds =
                                  null;
                              _metconSessionDescription.metconSession.reps =
                                  null;
                            case MetconType.forTime:
                              _metconSessionDescription.metconSession.time =
                                  Duration.zero;
                              _metconSessionDescription.metconSession.rounds =
                                  null;
                              _metconSessionDescription.metconSession.reps =
                                  null;
                              _finished = true;
                          }
                        });
                      }
                    }
                  },
                ),
                EditTile(
                  leading: AppIcons.calendar,
                  caption: "Start Time",
                  child: Text(
                    _metconSessionDescription.metconSession.datetime
                        .toHumanDateTime(),
                  ),
                  onTap: () async {
                    final datetime = await showDateTimePicker(
                      context: context,
                      initial: _metconSessionDescription.metconSession.datetime,
                    );
                    if (mounted && datetime != null) {
                      setState(() {
                        _metconSessionDescription.metconSession.datetime =
                            datetime;
                      });
                    }
                  },
                ),
                if (_metconSessionDescription
                        .metconDescription.metcon.metconType ==
                    MetconType.forTime)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("finished"),
                      Defaults.sizedBox.horizontal.normal,
                      SizedBox(
                        height: 29,
                        width: 34, // remove left padding
                        child: Switch(
                          value: _finished,
                          onChanged: (finished) {
                            FocusManager.instance.primaryFocus?.unfocus();
                            setState(() {
                              _finished = finished;
                              if (_finished) {
                                _metconSessionDescription.metconSession.time =
                                    Duration.zero;
                                _metconSessionDescription.metconSession.rounds =
                                    null;
                                _metconSessionDescription.metconSession.rounds =
                                    null;
                              } else {
                                _metconSessionDescription.metconSession.time =
                                    null;
                                _metconSessionDescription.metconSession.rounds =
                                    0;
                                _metconSessionDescription.metconSession.reps =
                                    0;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                if (_metconSessionDescription
                            .metconDescription.metcon.metconType ==
                        MetconType.forTime &&
                    _finished)
                  EditTile(
                    caption: 'Time',
                    leading: AppIcons.timeInterval,
                    child: DurationInput(
                      onUpdate: (d) => setState(
                        () => _metconSessionDescription.metconSession.time = d,
                      ),
                      initialDuration:
                          _metconSessionDescription.metconSession.time ??
                              Duration.zero,
                      minDuration: const Duration(seconds: 1),
                    ),
                  ),
                if (_metconSessionDescription
                                .metconDescription.metcon.metconType ==
                            MetconType.forTime &&
                        !_finished ||
                    _metconSessionDescription
                            .metconDescription.metcon.metconType ==
                        MetconType.amrap)
                  Row(
                    children: [
                      Expanded(
                        child: EditTile(
                          leading: AppIcons.repeat,
                          caption: "Rounds",
                          child: IntInput(
                            initialValue: _metconSessionDescription
                                    .metconSession.rounds ??
                                0,
                            minValue: 0,
                            maxValue: _metconSessionDescription
                                        .metconDescription.metcon.metconType ==
                                    MetconType.forTime
                                ? _metconSessionDescription
                                        .metconDescription.metcon.rounds! -
                                    1
                                : 999,
                            onUpdate: (rounds) => setState(
                              () => _metconSessionDescription
                                  .metconSession.rounds = rounds,
                            ),
                          ),
                        ),
                      ),
                      Defaults.sizedBox.horizontal.normal,
                      Expanded(
                        child: EditTile(
                          leading: null,
                          caption: "Reps",
                          child: IntInput(
                            initialValue:
                                _metconSessionDescription.metconSession.reps ??
                                    0,
                            minValue: 0,
                            maxValue: _metconSessionDescription
                                    .metconDescription.moves
                                    .map((e) => e.metconMovement.count)
                                    .sum -
                                1,
                            onUpdate: (reps) => setState(
                              () => _metconSessionDescription
                                  .metconSession.reps = reps,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                EditTile(
                  caption: "Rx",
                  leading: AppIcons.checkBox,
                  child: SizedBox(
                    height: 29, // make it fit into EditTile
                    width: 34, // remove left padding
                    child: Switch(
                      value: _metconSessionDescription.metconSession.rx,
                      onChanged: (rx) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        setState(() {
                          _metconSessionDescription.metconSession.rx = rx;
                        });
                      },
                    ),
                  ),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(AppIcons.comment),
                    labelText: "Comments",
                  ),
                  initialValue:
                      _metconSessionDescription.metconSession.comments,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 5,
                  onChanged: (comments) => setState(() {
                    _metconSessionDescription.metconSession.comments =
                        comments.isEmpty ? null : comments;
                  }),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
