import 'package:flutter/widgets.dart';

export 'colors.dart';

/// Which colour set the Synqt widgets below it use. The payment sheet sets it to the phone's setting, so it follows
/// the phone even when the app forces a theme of its own.
final class SynqtBrightness extends InheritedWidget {
  const SynqtBrightness({super.key, required this.brightness, required super.child});

  final Brightness brightness;

  static Brightness of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SynqtBrightness>()?.brightness ??
      MediaQuery.platformBrightnessOf(context);

  @override
  bool updateShouldNotify(SynqtBrightness oldWidget) => oldWidget.brightness != brightness;
}

/// Instrument Sans at [size] on the mobile type scale, weight 400, 500 or 600. Text grows with the payer's text size setting.
TextStyle synqtFont(double size, {FontWeight weight = FontWeight.w400, Color? color, bool tabular = false}) =>
    TextStyle(
      fontFamily: 'SynqtInstrumentSans',
      package: 'synqt',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.3,
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    );
