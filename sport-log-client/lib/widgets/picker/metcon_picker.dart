import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/models/all.dart';

Future<MetconDescription?> showMetconPicker({
  required BuildContext context,
  bool dismissable = true,
}) async {
  final _dataProvider = MetconDescriptionDataProvider.instance;
  final _metconDescriptions = await _dataProvider.getNonDeleted();

  return showDialog<MetconDescription>(
    builder: (_) => MetconPickerDialog(_metconDescriptions),
    barrierDismissible: dismissable,
    context: context,
  );
}

class MetconPickerDialog extends StatelessWidget {
  final List<MetconDescription> _metconDescriptions;

  const MetconPickerDialog(this._metconDescriptions, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(clipBehavior: Clip.antiAlias, child: _routeList);
  }

  Widget get _routeList {
    if (_metconDescriptions.isEmpty) {
      return const Center(child: Text('No routes here.'));
    }
    return Scrollbar(
      child: ListView.separated(
        itemBuilder: _routeBuilder,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: _metconDescriptions.length,
      ),
    );
  }

  Widget _routeBuilder(BuildContext context, int index) {
    final metconDescription = _metconDescriptions[index];

    return ListTile(
      title: Text(metconDescription.name),
      onTap: () {
        Navigator.pop(context, metconDescription);
      },
    );
  }
}
