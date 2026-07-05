import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/year_progress.dart';

/// Emits a fresh [YearProgress] snapshot on a timer so the home screen
/// stays live without the user needing to reopen the app.
///
/// Ticking every minute is enough resolution for a year-progress ring —
/// no need to rebuild every second for something that moves this slowly.
final yearProgressProvider = StreamProvider<YearProgress>((ref) {
  late StreamController<YearProgress> controller;

  Timer? timer;

  void emit() => controller.add(YearProgress.fromDate(DateTime.now()));

  controller = StreamController<YearProgress>(
    onListen: () {
      emit();
      timer = Timer.periodic(const Duration(minutes: 1), (_) => emit());
    },
    onCancel: () {
      timer?.cancel();
    },
  );

  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });

  return controller.stream;
});