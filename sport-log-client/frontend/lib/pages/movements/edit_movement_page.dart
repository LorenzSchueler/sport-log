
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/api/api_error.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/movement/ui_movement.dart';
import 'package:sport_log/pages/movements/movement_request_bloc.dart';
import 'package:sport_log/widgets/loading_dialog.dart';
import 'package:sport_log/widgets/wide_screen_frame.dart';

class EditMovementPage extends StatefulWidget {
  EditMovementPage({
    Key? key,
    UiMovement? initialMovement,
    String? initialName,
  }) : assert(initialMovement == null || initialName == null),
       _initialMovement = initialMovement,
       _initialName = initialName,
       super(key: key) {
    if (initialMovement != null) {
      assert(_initialMovement!.id != null);
    }
  }

  final UiMovement? _initialMovement;
  final String? _initialName;

  @override
  State<StatefulWidget> createState() => _EditMovementPageState();

  bool get _isEditing => _initialMovement != null;
}

class _EditMovementPageState extends State<EditMovementPage> {

  _EditMovementPageState();

  @override
  void initState() {
    super.initState();
    if (widget._initialMovement != null) {
      _movement = widget._initialMovement!;
    } else {
      _movement = UiMovement(
        id: null,
        userId: null,
        name: widget._initialName ?? "",
        category: _categoryDefaultValue,
        description: null
      );
    }
  }

  late UiMovement _movement;

  final _descriptionFocusNode = FocusNode();
  static const _categoryDefaultValue = MovementCategory.strength;

  void _setName(String name) {
    setState(() => _movement.name = name);
  }

  void _setCategory(MovementCategory category) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _movement.category = category);
  }

  void _setDescription(String? description) {
    setState(() => _movement.description = description);
  }

  bool _inputIsValid() {
    return _movement.name != "";
  }

  void _submit(MovementRequestBloc requestBloc) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_inputIsValid()) {
      return;
    }
    if (widget._isEditing) {
      assert(_movement.id != null);
      assert(_movement.userId != null);
      requestBloc.add(MovementRequestUpdate(_movement));
    } else {
      requestBloc.add(MovementRequestCreate(_movement));
    }
  }

  void _delete(MovementRequestBloc requestBloc) {
    if (widget._isEditing) {
      assert(_movement.id != null);
      assert(_movement.userId != null);
      requestBloc.add(MovementRequestDelete(_movement.id!));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestBloc = MovementRequestBloc.fromContext(context);
    return BlocConsumer(
      bloc: requestBloc,
      listener: (context, state) {
        if (state is MovementRequestFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.reason.toErrorMessage()))
          );
        } else if (state is MovementRequestSucceeded) {
          final navigator = Navigator.of(context);
          navigator.pop();
          if (state.payload is int) {
            navigator.pop(state.payload);
          } else {
            navigator.pop();
          }
        } else if (state is MovementRequestPending) {
          showDialog<void>(
            context: context,
            builder: (_) => const LoadingDialog(),
          );
        }
      },
      builder: (context, state) => _buildForm(context, requestBloc),
    );
  }

  Widget _buildForm(BuildContext context, MovementRequestBloc requestBloc) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget._isEditing ? "Edit Movement" : "New Movement"),
          leading: IconButton(
            onPressed: _inputIsValid() ? () => _submit(requestBloc) : null,
            icon: const Icon(Icons.save),
          ),
          actions: [
            IconButton(
              onPressed: () => _delete(requestBloc),
              icon: const Icon(Icons.delete),
            )
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
      initialValue: _movement.name,
      onChanged: _setName,
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
    if (_movement.description == null) {
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
        initialValue: _movement.description ?? "",
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
          )
        )
      ),
    );
  }

  Widget _categoryInput(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.button!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: MovementCategory.values.map((category) => TextButton(
        onPressed: () => _setCategory(category),
        child: Text(
          category.toDisplayName(),
          style: style.copyWith(
            color: (category == _movement.category)
                ? theme.primaryColor
                : theme.disabledColor,
          ),
        ),
      )).toList(),
    );
  }
}