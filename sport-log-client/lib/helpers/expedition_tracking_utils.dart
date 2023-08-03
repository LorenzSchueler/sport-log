import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart' hide Route;

class ExpeditionData {
  ExpeditionData({
    required this.cardioId,
    required this.trackingTimes,
  });

  final Int64 cardioId;
  final List<TimeOfDay> trackingTimes;
}

