import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/input_fields/duration_input.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/input_fields/int_input.dart';
import 'package:sport_log/widgets/picker/datetime_picker.dart';
import 'package:sport_log/widgets/picker/metcon_picker.dart';
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

  late final MetconSessionDescription _metconSessionDescription;
  late bool _finished;

  @override
  void initState() {
    super.initState();
    final metconSessionDescription = widget.metconSessionDescription.clone();
    _metconSessionDescription = metconSessionDescription;
    _finished = _metconSessionDescription.metconSession.time != null;
  }

  Future<void> _saveMetconSession() async {
    _logger.i("saving metcon session: $_metconSessionDescription");
    final result = widget.isNew
        ? await _dataProvider.createSingle(_metconSessionDescription)
        : await _dataProvider.updateSingle(_metconSessionDescription);
    if (result.isSuccess()) {
      _formKey.currentState!.deactivate();
      if (mounted) {
        Navigator.pop(
          context,
          ReturnObject(
            action: widget.isNew ? ReturnAction.created : ReturnAction.updated,
            payload: _metconSessionDescription,
          ), // needed for return to details page
        );
      }
    } else {
      await showMessageDialog(
        context: context,
        text: 'Creating Metcon Session failed:\n${result.failure}',
      );
    }
  }

  Future<void> _deleteMetconSession() async {
    if (!widget.isNew) {
      await _dataProvider.deleteSingle(_metconSessionDescription);
    }
    _formKey.currentState!.deactivate();
    if (mounted) {
      Navigator.pop(
        context,
        ReturnObject(
          action: ReturnAction.deleted,
          payload: _metconSessionDescription,
        ), // needed for return to details page
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DiscardWarningOnPop(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isNew ? "Create Metcon Session" : "Edit Metcon Session",
          ),
          actions: [
            IconButton(
              onPressed: _deleteMetconSession,
              icon: const Icon(AppIcons.delete),
            ),
            IconButton(
              onPressed: _formKey.currentContext != null &&
                      _formKey.currentState!.validate() &&
                      _metconSessionDescription.isValid()
                  ? _saveMetconSession
                  : null,
              icon: const Icon(AppIcons.save),
            ),
          ],
        ),
        body: Container(
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
                    Metcon? metcon = await showMetconPicker(
                      context: context,
                    );
                    if (metcon != null) {
                      final metconDescription =
                          await _metconDescriptionDataProvider
                              .getByMetcon(metcon);
                      setState(() {
                        _metconSessionDescription.metconDescription =
                            metconDescription;
                        _metconSessionDescription.metconSession.metconId =
                            _metconSessionDescription
                                .metconDescription.metcon.id;
                        switch (_metconSessionDescription
                            .metconDescription.metcon.metconType) {
                          case MetconType.amrap:
                            _metconSessionDescription.metconSession.time = null;
                            _metconSessionDescription.metconSession.rounds = 0;
                            _metconSessionDescription.metconSession.reps = 0;
                            break;
                          case MetconType.emom:
                            _metconSessionDescription.metconSession.time = null;
                            _metconSessionDescription.metconSession.rounds =
                                null;
                            _metconSessionDescription.metconSession.reps = null;
                            break;
                          case MetconType.forTime:
                            _metconSessionDescription.metconSession.time =
                                Duration.zero;
                            _metconSessionDescription.metconSession.rounds =
                                null;
                            _metconSessionDescription.metconSession.reps = null;
                            _finished = true;
                            break;
                        }
                      });
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
                    DateTime? datetime = await showDateTimePicker(
                      context: context,
                      initial: _metconSessionDescription.metconSession.datetime,
                    );
                    if (datetime != null) {
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
                        height: 20,
                        width: 34,
                        child: Switch(
                          value: _finished,
                          onChanged: (finished) => setState(() {
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
                              _metconSessionDescription.metconSession.reps = 0;
                            }
                          }),
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
                      setDuration: (d) => setState(
                        () => _metconSessionDescription.metconSession.time = d,
                      ),
                      initialDuration:
                          _metconSessionDescription.metconSession.time!,
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
                            maxValue: _metconSessionDescription
                                        .metconDescription.metcon.metconType ==
                                    MetconType.forTime
                                ? _metconSessionDescription
                                        .metconDescription.metcon.rounds! -
                                    1
                                : 999,
                            setValue: (rounds) => setState(
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
                            maxValue: _metconSessionDescription
                                    .metconDescription.moves
                                    .map((e) => e.metconMovement.count)
                                    .sum -
                                1,
                            setValue: (reps) => setState(
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
                    height: 20,
                    width: 34,
                    child: Switch(
                      value: _metconSessionDescription.metconSession.rx,
                      onChanged: (rx) {
                        setState(() {
                          _metconSessionDescription.metconSession.rx = rx;
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                TextFormField(
                  decoration:
                      Theme.of(context).textFormFieldDecoration.copyWith(
                            icon: const Icon(AppIcons.comment),
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
