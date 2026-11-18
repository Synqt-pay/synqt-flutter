import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../strings.dart';
import 'icon_paths.dart';
import 'theme.dart';

// Synqt-styled widgets: the building blocks of the SDK's payment sheet, for apps that want their own screens to match.
// Mobile type scale in Instrument Sans, spacing in 4, 8, 16 and 24, 12 radius cards and inputs, 48 high pill buttons, a visible
// focus ring, light and dark. Colours follow SynqtColors.of(context).

/// The sheet's line icons.
enum SynqtIcon { lock, close, warning, chevronDown, copy, timer }

String _hex(Color color) => '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// An icon at [size] in [color], growing with the text size like the text beside it. Decorative: the control it sits
/// on carries the label.
class SynqtIconView extends StatelessWidget {
  const SynqtIconView(this.icon, {super.key, this.size = 24, required this.color});

  final SynqtIcon icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scaled = MediaQuery.textScalerOf(context).scale(size);
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256"><path fill="${_hex(color)}" d="${iconPaths[icon.name]}"/></svg>',
      width: scaled,
      height: scaled,
      excludeFromSemantics: true,
    );
  }
}

/// The Synqt wordmark, 26 high (the smallest size the brand uses): letters in the logo ink (positive on light,
/// negative on dark), the dot always magenta.
class SynqtLogo extends StatelessWidget {
  const SynqtLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final ink = _hex(SynqtColors.of(context).logoInk);
    final letters = logoLetters
        .map((letter) => '<path transform="translate(${letter.$1} ${letter.$2})" d="${letter.$3}"/>')
        .join();
    final dot =
        '<path fill="${_hex(SynqtColors.magenta)}" transform="translate(${logoDot.$1} ${logoDot.$2})" d="${logoDot.$3}"/>';
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 154.854 51.266"><g fill="$ink">$letters</g>$dot</svg>',
      height: 26,
      width: 154.854 * 26 / 51.266,
      semanticsLabel: text('synqt_sheet_logo'),
    );
  }
}

/// A panel with a title in the mobile subtitle style (20 Regular).
class SynqtCard extends StatelessWidget {
  const SynqtCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = SynqtColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: synqtFont(20, color: colors.text)),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// The keyboard and text handling for a [SynqtTextField].
enum SynqtKeyboard { text, name, email, phone, number }

/// Label above, input, helper below. A non-null [error] replaces the helper and turns the edge red. [placeholder] shows
/// in the empty input.
///
/// [value] is the text to show; when it changes from outside (the sheet clears a field), the field follows.
/// [focusRequest] focuses the field and scrolls to it each time it changes to a new number above zero.
///
/// [autofillHints] replace the [keyboard]'s own. [inputFormatters], [contextMenuBuilder] and
/// [enableIMEPersonalizedLearning] are as on [TextField], for fields that need more control, such as card details.
class SynqtTextField extends StatefulWidget {
  const SynqtTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper = '',
    this.placeholder = '',
    this.error,
    this.keyboard = SynqtKeyboard.text,
    this.focusRequest = 0,
    this.onFocusChange,
    this.autofillHints,
    this.inputFormatters,
    this.contextMenuBuilder,
    this.enableIMEPersonalizedLearning = true,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String helper;
  final String placeholder;
  final String? error;
  final SynqtKeyboard keyboard;
  final int focusRequest;
  final ValueChanged<bool>? onFocusChange;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final EditableTextContextMenuBuilder? contextMenuBuilder;
  final bool enableIMEPersonalizedLearning;

  @override
  State<SynqtTextField> createState() => _SynqtTextFieldState();
}

class _SynqtTextFieldState extends State<SynqtTextField> {
  late final _controller = TextEditingController(text: widget.value);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      setState(() {}); // the focus ring
      widget.onFocusChange?.call(_focus.hasFocus);
    });
  }

  @override
  void didUpdateWidget(SynqtTextField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
    if (widget.focusRequest != old.focusRequest && widget.focusRequest > 0) {
      _focus.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 250));
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SynqtColors.of(context);
    final keyboard = widget.keyboard;
    OutlineInputBorder edge(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      // One element for screen readers: label, field, then the error or helper.
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.label,
                style: synqtFont(16, weight: FontWeight.w500, color: colors.text),
              ),
            ),
            TextField(
              controller: _controller,
              focusNode: _focus,
              onChanged: widget.onChanged,
              style: synqtFont(16, color: colors.text),
              cursorColor: colors.action,
              keyboardType: switch (keyboard) {
                SynqtKeyboard.text => TextInputType.text,
                SynqtKeyboard.name => TextInputType.name,
                SynqtKeyboard.email => TextInputType.emailAddress,
                SynqtKeyboard.phone => TextInputType.phone,
                SynqtKeyboard.number => TextInputType.number,
              },
              autofillHints:
                  widget.autofillHints ??
                  switch (keyboard) {
                    SynqtKeyboard.email => const [AutofillHints.email],
                    SynqtKeyboard.phone => const [AutofillHints.telephoneNumber],
                    _ => null,
                  },
              inputFormatters: widget.inputFormatters,
              contextMenuBuilder: widget.contextMenuBuilder ?? _defaultMenu,
              enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
              textCapitalization: keyboard == SynqtKeyboard.name ? TextCapitalization.words : TextCapitalization.none,
              autocorrect: keyboard == SynqtKeyboard.text || keyboard == SynqtKeyboard.name,
              enableSuggestions: keyboard == SynqtKeyboard.text || keyboard == SynqtKeyboard.name,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: colors.surface,
                hintText: widget.placeholder.isEmpty ? null : widget.placeholder,
                hintStyle: synqtFont(16, color: colors.textMuted),
                constraints: const BoxConstraints(minHeight: 52),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                enabledBorder: edge(widget.error != null ? colors.danger : colors.borderControl, 1),
                focusedBorder: edge(colors.focusRing, 2),
              ),
            ),
            _HelperText(widget.error ?? widget.helper, isError: widget.error != null),
          ],
        ),
      ),
    );
  }
}

/// Labelled dropdown in the input's style. [options] pairs the value to keep with the text to show; [error] works as on
/// [SynqtTextField].
class SynqtDropdown extends StatelessWidget {
  const SynqtDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.helper = '',
    this.error,
  });

  final String label;
  final String value;
  final List<({String value, String label})> options;
  final ValueChanged<String> onChanged;
  final String helper;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final colors = SynqtColors.of(context);
    final selected = options.any((option) => option.value == value) ? value : options.firstOrNull?.value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                label,
                style: synqtFont(16, weight: FontWeight.w500, color: colors.text),
              ),
            ),
            Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: error != null ? colors.danger : colors.borderControl),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selected,
                  dropdownColor: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  icon: SynqtIconView(SynqtIcon.chevronDown, color: colors.text),
                  style: synqtFont(16, color: colors.text),
                  items: [
                    for (final option in options)
                      DropdownMenuItem(
                        value: option.value,
                        child: Text(option.label, style: synqtFont(16, color: colors.text)),
                      ),
                  ],
                  onChanged: (value) => onChanged(value ?? ''),
                ),
              ),
            ),
            _HelperText(error ?? helper, isError: error != null),
          ],
        ),
      ),
    );
  }
}

/// [primary] is the action colour (one per screen), [accent] is brand magenta for dark sections, [outline] is secondary.
enum SynqtButtonKind { primary, accent, outline }

/// A 48 high pill button in the Synqt style.
class SynqtButton extends StatelessWidget {
  const SynqtButton({super.key, required this.label, required this.onPressed, this.kind = SynqtButtonKind.primary});

  final String label;
  final VoidCallback? onPressed;
  final SynqtButtonKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = SynqtColors.of(context);
    final (fill, ink) = switch (kind) {
      SynqtButtonKind.primary => (colors.action, colors.onAction),
      // White on brand magenta is 3.29:1, so the label is Off-Blue Black (5.14:1).
      SynqtButtonKind.accent => (SynqtColors.magenta, colors.onAccent),
      SynqtButtonKind.outline => (colors.surface, colors.text),
    };
    final shape = StadiumBorder(
      side: kind == SynqtButtonKind.outline ? BorderSide(color: colors.borderControl) : BorderSide.none,
    );
    return Semantics(
      button: true,
      child: Material(
        color: fill,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          overlayColor: WidgetStatePropertyAll(colors.pressedOverlay),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: synqtFont(16, weight: FontWeight.w500, color: ink, tabular: true),
            ),
          ),
        ),
      ),
    );
  }
}

/// Error banner: the words lead, with a warning icon, so colour is never the only cue.
class SynqtErrorBanner extends StatelessWidget {
  const SynqtErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = SynqtColors.of(context);
    return MergeSemantics(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.dangerTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.dangerLine),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SynqtIconView(SynqtIcon.warning, color: colors.danger),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: synqtFont(16, color: colors.danger)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelperText extends StatelessWidget {
  const _HelperText(this.value, {required this.isError});

  final String value;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    final colors = SynqtColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(value, style: synqtFont(13, color: isError ? colors.danger : colors.textMuted)),
    );
  }
}

/// Frames in one loop of the Lottie file (60fps), and how far aqua runs behind magenta.
const orbitLoop = 174.0;
const orbitDelay = 7.2;

/// The Synqt Orbit loader, drawn natively from the designer's Lottie file (synqt-loaders/lottie/orbit-*.json): a hub in
/// the text colour, with a magenta and an aqua dot that each turn once, glide into the hub and back out. Decorative, so
/// screen readers skip it; with animations turned off it holds still.
class OrbitLoader extends StatefulWidget {
  const OrbitLoader({super.key, this.size = 72});

  final double size;

  @override
  State<OrbitLoader> createState() => _OrbitLoaderState();
}

class _OrbitLoaderState extends State<OrbitLoader> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2900),
  ); // 174 frames at 60fps

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: widget.size,
      child: CustomPaint(painter: _OrbitPainter(_controller, SynqtColors.of(context).text)),
    ),
  );
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.progress, this.hub) : super(repaint: progress);

  final Animation<double> progress;
  final Color hub;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height) / 100; // the Lottie canvas is 100 by 100
    final center = size.center(Offset.zero);
    final frame = progress.value * orbitLoop;
    void dot(Offset at, Color color) => canvas.drawCircle(at, 11 * unit, Paint()..color = color);
    dot(center, hub);
    // Later dots are drawn on top, as in the Lottie file: hub, then aqua, then magenta.
    for (final (offset, color) in [(orbitDelay, SynqtColors.aqua), (0.0, SynqtColors.magenta)]) {
      final (angle, distance) = orbitDot(frame - offset);
      final rad = angle * math.pi / 180;
      dot(center + Offset(distance * unit * math.sin(rad), -distance * unit * math.cos(rad)), color);
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.hub != hub;
}

/// Where an Orbit dot is at [frame] (60fps, looping every 174): degrees clockwise from the top, and distance from the
/// centre on the 100-unit canvas. Keyframes from the Lottie file: turn 0 to 96.05, glide in to 120.06, wait, glide out
/// from 149.99 to 174.
(double, double) orbitDot(double frame) {
  final loopFrame = (frame % orbitLoop + orbitLoop) % orbitLoop;
  final angle = loopFrame < 96.05 ? 360 * ease(loopFrame / 96.05) : 360.0;
  final double distance;
  if (loopFrame < 96.05) {
    distance = 40;
  } else if (loopFrame < 120.06) {
    distance = 40 * (1 - ease((loopFrame - 96.05) / 24.01));
  } else if (loopFrame < 149.99) {
    distance = 0;
  } else {
    distance = 40 * ease((loopFrame - 149.99) / 24.01);
  }
  return (angle, distance);
}

/// The file's one easing curve, cubic-bezier(0.65, 0, 0.35, 1), solved for x by bisection.
double ease(double progress) {
  double bezier(double fraction, double control1, double control2) =>
      3 * (1 - fraction) * (1 - fraction) * fraction * control1 +
      3 * (1 - fraction) * fraction * fraction * control2 +
      fraction * fraction * fraction;
  var lo = 0.0, hi = 1.0;
  for (var index = 0; index < 24; index++) {
    final mid = (lo + hi) / 2;
    if (bezier(mid, 0.65, 0.35) < progress) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return bezier((lo + hi) / 2, 0, 1);
}

Widget _defaultMenu(BuildContext context, EditableTextState state) =>
    AdaptiveTextSelectionToolbar.editableText(editableTextState: state);
