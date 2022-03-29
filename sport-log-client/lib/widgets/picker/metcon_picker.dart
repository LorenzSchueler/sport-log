import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/metcon/metcon.dart';
import 'package:sport_log/routes.dart';
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
  State<MetconPickerDialog> createState() => MetconPickerDialogState();
}

class MetconPickerDialogState extends State<MetconPickerDialog> {
  final _dataProvider = MetconDataProvider();

  List<Metcon> _metcons = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _update('');
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
        ));
  }

  Widget get _searchBar {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: TextFormField(
        initialValue: _search,
        onChanged: _update,
        decoration: InputDecoration(
          labelText: 'Search',
          prefixIcon: const Icon(AppIcons.search),
          border: InputBorder.none,
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
    if (_metcons.isEmpty) {
      return const Center(child: Text('No routes here.'));
    }
    return Scrollbar(
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
