import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Synqt semantic colour tokens from the synqt-brand-design skill, the same values as the Android SDK's synqt_colors.xml
/// and the iOS SDK's SynqtColors. Pick the set for the screen with [SynqtColors.of] or [SynqtColors.forBrightness].
/// Generated: don't edit by hand.
final class SynqtColors {
  const SynqtColors({
    required this.surface,
    required this.surfacePanel,
    required this.text,
    required this.textMuted,
    required this.onAccent,
    required this.action,
    required this.onAction,
    required this.actionTint,
    required this.eyebrow,
    required this.border,
    required this.borderControl,
    required this.focusRing,
    required this.logoInk,
    required this.pressedOverlay,
    required this.danger,
    required this.dangerTint,
    required this.dangerLine,
  });

  final Color surface;
  final Color surfacePanel;
  final Color text;
  final Color textMuted;
  final Color onAccent;
  final Color action;
  final Color onAction;

  /// Dark: magenta at 12%.
  final Color actionTint;
  final Color eyebrow;
  final Color border;

  /// slate-muted: a 3:1 field edge in both themes (brand owner, 26 Oct 2026).
  final Color borderControl;
  final Color focusRing;
  final Color logoInk;
  final Color pressedOverlay;

  /// The icon, border and words of an error. Dark: danger-light (brand owner, 26 Oct 2026): #B4232C is 2.59:1 on the dark surface, this is 9.98:1.
  final Color danger;

  /// Frames the error banner, with danger_line.
  final Color dangerTint;
  final Color dangerLine;

  static const magenta = Color(0xFFF318FF);

  /// For the Orbit loader only. The brand keeps aqua for dark grounds; its use on light is an open point.
  static const aqua = Color(0xFF27FFE2);

  static const light = SynqtColors(
    surface: Color(0xFFFFFFFF),
    surfacePanel: Color(0xFFF0F0F0),
    text: Color(0xFF1A1C29),
    textMuted: Color(0xFF4E5670),
    onAccent: Color(0xFF1A1C29),
    action: Color(0xFFB505BF),
    onAction: Color(0xFFFFFFFF),
    actionTint: Color(0xFFFEEEFF),
    eyebrow: Color(0xFFB505BF),
    border: Color(0xFFE7EAF2),
    borderControl: Color(0xFF7A8296),
    focusRing: Color(0xFF1A1C29),
    logoInk: Color(0xFF1A1C29),
    pressedOverlay: Color(0x331A1C29),
    danger: Color(0xFFB4232C),
    dangerTint: Color(0xFFFCEBEC),
    dangerLine: Color(0xFFF2D1D3),
  );

  static const dark = SynqtColors(
    surface: Color(0xFF1A1C29),
    surfacePanel: Color(0xFF212536),
    text: Color(0xFFFFFFFF),
    textMuted: Color(0xFFA7AFC5),
    onAccent: Color(0xFF1A1C29),
    action: Color(0xFFF318FF),
    onAction: Color(0xFF1A1C29),
    actionTint: Color(0x1FF318FF),
    eyebrow: Color(0xFFF470FF),
    border: Color(0xFF2A2F42),
    borderControl: Color(0xFF7A8296),
    focusRing: Color(0xFF27FFE2),
    logoInk: Color(0xFFFFFFFF),
    pressedOverlay: Color(0x33FFFFFF),
    danger: Color(0xFFFFB4AE),
    dangerTint: Color(0xFF212536),
    dangerLine: Color(0xFFFFB4AE),
  );

  static SynqtColors forBrightness(Brightness brightness) => brightness == Brightness.dark ? dark : light;

  /// The set for the nearest [SynqtBrightness], else the phone's light or dark setting.
  static SynqtColors of(BuildContext context) => forBrightness(SynqtBrightness.of(context));
}
