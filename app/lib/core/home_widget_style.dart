import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The different visual layouts available for displaying year progress on
/// the Home screen. Selected on the Widgets page, applied by [HomeScreen].
enum HomeWidgetStyle { ring, bar, dial, minimal }

extension HomeWidgetStyleX on HomeWidgetStyle {
  String get label => switch (this) {
        HomeWidgetStyle.ring => 'Ring',
        HomeWidgetStyle.bar => 'Bar',
        HomeWidgetStyle.dial => 'Dial',
        HomeWidgetStyle.minimal => 'Minimal',
      };

  String get description => switch (this) {
        HomeWidgetStyle.ring => 'Circular progress ring with full stat grid',
        HomeWidgetStyle.bar => 'Horizontal progress bar, compact stats',
        HomeWidgetStyle.dial => 'Radial dial with tick marks',
        HomeWidgetStyle.minimal => 'Just the number — nothing else',
      };

  IconData get icon => switch (this) {
        HomeWidgetStyle.ring => Icons.donut_large_rounded,
        HomeWidgetStyle.bar => Icons.linear_scale_rounded,
        HomeWidgetStyle.dial => Icons.speed_rounded,
        HomeWidgetStyle.minimal => Icons.text_fields_rounded,
      };
}

final homeWidgetStyleProvider = StateProvider<HomeWidgetStyle>((ref) => HomeWidgetStyle.ring);