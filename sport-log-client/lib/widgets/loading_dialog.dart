
import 'package:flutter/material.dart';

class LoadingDialog extends StatelessWidget {
  const LoadingDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Theme.of(context).backgroundColor.withAlpha(30),
        insetPadding: EdgeInsets.zero,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}