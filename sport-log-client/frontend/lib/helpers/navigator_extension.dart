
import 'package:flutter/material.dart';

extension Nav on Navigator {
  static changeNamed(BuildContext context, String route) {
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  }
}