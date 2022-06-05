import 'dart:async';

import 'package:flutter/material.dart' hide Route;
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/models/metcon/metcon.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';

Future<Metcon?> showMetconPicker({
  required BuildContext context,
  Metcon? selectedMetcon,
  bool dismissable = true,
}) async {
  return showDialog<Metcon>(
    builder: (_) => MetconPickerDialog(selectedMetcon: selectedMetcon),
    barrierDismissible: dismissable,
    context: context,
  );
}

class MetconPickerDialog extends StatefulWidget {
  const MetconPickerDialog({
    required this.selectedMetcon,
    Key? key,
  }) : super(key: key);

  final Metcon? selectedMetcon;

  @override
  State<MetconPickerDialog> createState() => _MetconPickerDialogState();
}

class _MetconPickerDialogState extends State<MetconPickerDialog> {
  final _dataProvider = MetconDataProvider();
  late final StreamSubscription<bool> _keyboardSubscription;

  List<Metcon> _metcons = [];
  String _search = '';

  @override
  void initState() {
    _keyboardSubscription =
        KeyboardVisibilityController().onChange.listen((isVisible) {
      if (!isVisible) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
    _update('');
    super.initState();
  }

  @override
  void dispose() {
    _keyboardSubscription.cancel();
    super.dispose();
  }

  Future<void> _update(String newSearch) async {
    final metcons = await _dataProvider.getByName(newSearch.trim());
    if (widget.selectedMetcon != null) {
      final index = metcons
          .indexWhere((metcon) => metcon.id == widget.selectedMetcon!.id);
      if (index >= 0) {
        metcons.insert(0, metcons.removeAt(index));
      }
    }
    setState(() {
      _metcons = metcons;
      _search = newSearch;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _searchBar,
          const Divider(
            height: 1,
            thickness: 2,
          ),
          Expanded(child: _metconList)
        ],
      ),
    );
  }

  Widget get _searchBar {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
      child: TextFormField(
        autofocus: true,
        initialValue: _search,
        onChanged: _update,
        decoration: Theme.of(context).textFormFieldDecoration.copyWith(
              labelText: 'Search',
              prefixIcon: const Icon(AppIcons.search),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        Routes.metcon.edit,
                      ),
                      icon: const Icon(AppIcons.add),
                    )
                  : null,
            ),
      ),
    );
  }

  Widget get _metconList {
    return _metcons.isEmpty
        ? const Center(child: Text('No metcons here.'))
        : Scrollbar(
            child: ListView.separated(
              itemBuilder: _routeBuilder,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: _metcons.length,
            ),
          );
  }

  Widget _routeBuilder(BuildContext context, int index) {
    final metcon = _metcons[index];
    final selected = metcon.id == widget.selectedMetcon?.id;

    return ListTile(
      title: Text(metcon.name),
      onTap: () {
        Navigator.pop(context, metcon);
      },
      selected: selected,
      trailing: selected ? const Icon(AppIcons.check) : null,
    );
  }
}
