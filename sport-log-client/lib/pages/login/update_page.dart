import 'package:flutter/material.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/data_provider/data_providers/app_data_provider.dart';
import 'package:sport_log/helpers/request_permission.dart';
import 'package:sport_log/pages/login/welcome_screen.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';

bool _updateInProgress = false;

class UpdatePage extends StatelessWidget {
  const UpdatePage({super.key});

  Future<void> update(BuildContext context) async {
    if (_updateInProgress) {
      return;
    }
    _updateInProgress = true;
    final updateDownloadResult = await AppDataProvider().downloadUpdate(
      onNoInternet: () => showMessageDialog(
        context: context,
        title: "Update Failed",
        text: "Internet required.",
      ),
    );
    if (updateDownloadResult.isOk) {
      final filename = updateDownloadResult.ok;
      if (await PermissionRequest.request(Permission.manageExternalStorage) &&
          await PermissionRequest.request(Permission.requestInstallPackages)) {
        await OpenFile.open(filename);
      }
    } else if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    update(context);

    return const WelcomeScreen(
      content: Column(
        children: [Text("Downloading Updates ..."), LinearProgressIndicator()],
      ),
    );
  }
}
