import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/helpers/state/page_return.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/widgets/approve_dialog.dart';
import 'package:sport_log/widgets/wide_screen_frame.dart';

class EditMovementPage extends StatefulWidget {
  const EditMovementPage({
    Key? key,
    required MovementDescription initialMovement,
  })  : _initialMovement = initialMovement,
        _isEditing = true,
        super(key: key);

  EditMovementPage.fromName({
    Key? key,
    required String initialName,
  })  : _initialMovement =
            MovementDescription.defaultValue(UserState.instance.currentUser!.id)
              ..movement.name = initialName,
        _isEditing = false,
        super(key: key);

  EditMovementPage.newMovement({Key? key})
      : _isEditing = false,
        _initialMovement = MovementDescription.defaultValue(
            UserState.instance.currentUser!.id),
        super(key: key);

  final MovementDescription _initialMovement;
  final bool _isEditing;

  @override
  State<StatefulWidget> createState() => _EditMovementPageState();
}

class _EditMovementPageState extends State<EditMovementPage> {
  final _dataProvider = MovementDataProvider();
  final _descriptionFocusNode = FocusNode();
  late MovementDescription _md;

  @override
  void initState() {
    super.initState();
    _md = widget._initialMovement.copy();
  }

  void _setCategory(MovementCategory category) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _md.movement.category = category);
  }

  void _setDescription(String? description) {
    setState(() => _md.movement.description = description);
  }

  bool get _inputIsValid => _md.isValid();
  bool get _hasChanges => _md != widget._initialMovement;

  void _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_inputIsValid) {
      return;
    }
    if (widget._isEditing) {
      assert(_md.movement.userId != null && _hasChanges);
      // TODO: do error handling
      await _dataProvider.updateSingle(_md.movement);
      Navigator.of(context)
          .pop(ReturnObject(action: ReturnAction.updated, object: _md));
    } else {
      // TODO: do error handling
      await _dataProvider.createSingle(_md.movement);
      Navigator.of(context)
          .pop(ReturnObject(action: ReturnAction.created, object: _md));
    }
  }

  void _delete() {
    if (widget._isEditing) {
      assert(_md.movement.userId != null);
      _dataProvider.deleteSingle(_md.movement);
      Navigator.of(context)
          .pop(ReturnObject(action: ReturnAction.deleted, object: _md));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget._isEditing ? "Edit Movement" : "New Movement"),
          leading: IconButton(
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              if (_hasChanges) {
                final bool? approved = await showDiscardWarningDialog(context);
                if (approved == null || !approved) return;
              }
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            if (widget._isEditing)
              IconButton(
                onPressed: () => _delete(),
                icon: const Icon(Icons.delete),
              ),
            IconButton(
                onPressed:
                    _inputIsValid && _hasChanges ? () => _submit() : null,
                icon: const Icon(Icons.save))
          ],
        ),
        body: WideScreenFrame(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              child: ListView(
                children: [
                  _nameInput(context),
                  _maybeDescriptionInput(context),
                  _categoryInput(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nameInput(BuildContext context) {
    return TextFormField(
      initialValue: _md.movement.name,
      onChanged: (name) => setState(() => _md.movement.name = name),
      style: Theme.of(context).textTheme.headline6,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.text,
      decoration: const InputDecoration(
        labelText: "Name",
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _maybeDescriptionInput(BuildContext context) {
    if (_md.movement.description == null) {
      return OutlinedButton.icon(
        onPressed: () {
          _setDescription("");
          _descriptionFocusNode.requestFocus();
        },
        icon: const Icon(Icons.add),
        label: const Text("Add description..."),
      );
    } else {
      return _descriptionInput(context);
    }
  }

  Widget _descriptionInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextFormField(
        initialValue: _md.movement.description ?? "",
        focusNode: _descriptionFocusNode,
        keyboardType: TextInputType.multiline,
        minLines: 1,
        maxLines: null,
        onChanged: _setDescription,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: "Description",
          suffixIcon: IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: () => _setDescription(null),
          ),
        ),
      ),
    );
  }

  Widget _categoryInput(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.button!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: MovementCategory.values
          .map((category) => TextButton(
                onPressed: () => _setCategory(category),
                child: Text(
                  category.toDisplayName(),
                  style: style.copyWith(
                    color: (category == _md.movement.category)
                        ? theme.primaryColor
                        : theme.disabledColor,
                  ),
                ),
              ))
          .toList(),
    );
  }
}
