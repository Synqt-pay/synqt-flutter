import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'addon.dart';
import 'method_form.dart';
import 'payment_methods.dart';
import 'payment_sheet_model.dart';
import 'results.dart';
import 'strings.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

export 'payment_sheet_model.dart' show PaymentSheetModel, PaymentSummary;

/// Shows [model] as a bottom sheet over [context], or as a centred card on a tablet (600 wide or more on its shorter
/// side), and completes with its result once, however it closes. Only the close button, Done, or the system back
/// gesture close it, never a tap outside or a swipe down, and none of them while a payment is being sent.
Future<CreatePayinResult?> showPaymentSheet(
  BuildContext context,
  PaymentSheetModel model, {
  VoidCallback? onPresented,
}) {
  final done = Completer<CreatePayinResult?>();
  final code = model.form.code;
  final view = View.of(context);
  final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
  model
    ..copy = ((value) => unawaited(Clipboard.setData(ClipboardData(text: value))))
    ..announce = ((message) {
      if (message.isNotEmpty) {
        unawaited(SemanticsService.sendAnnouncement(view, message, direction));
      }
    })
    ..openLink = ((link) => _launch(link, LaunchMode.externalApplication))
    // An https link opens the method's app only if it is installed (a universal link or App Link); otherwise try the
    // app's own scheme.
    ..openInApp = ((link) async {
      for (final candidate in appLinks(link, appSchemes[code])) {
        final mode = candidate.startsWith('https://')
            ? LaunchMode.externalNonBrowserApplication
            : LaunchMode.externalApplication;
        if (await _launch(candidate, mode)) return true;
      }
      return false;
    });
  ModalRoute<void>? route;
  model.onFinish = (result) {
    final currentRoute = route;
    // Pop the sheet itself, even if a dropdown menu is open over it.
    if (currentRoute != null && currentRoute.isCurrent) {
      currentRoute.navigator!.pop();
    } else if (currentRoute != null && currentRoute.isActive) {
      currentRoute.navigator!.removeRoute(currentRoute);
    }
    if (!done.isCompleted) done.complete(result);
  };
  // A keyboard left open by the app would sit over the sheet.
  FocusManager.instance.primaryFocus?.unfocus();
  final surface = SynqtColors.forBrightness(MediaQuery.platformBrightnessOf(context)).surface;
  Widget content(BuildContext sheetContext) {
    route = ModalRoute.of(sheetContext);
    return _PaymentSheet(model: model, onPresented: onPresented);
  }

  unawaited(
    (MediaQuery.sizeOf(context).shortestSide >= 600
            // The dialog lifts itself above the keyboard and takes the safe area, so the sheet's bottom spacer is 0.
            ? showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => Dialog(
                  backgroundColor: surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(width: 640, child: content(dialogContext)),
                ),
              )
            : showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                isDismissible: false,
                enableDrag: false,
                useSafeArea: true,
                backgroundColor: surface,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                // The sheet's own full-size Material would otherwise paint square corners over the rounded ones.
                clipBehavior: Clip.antiAlias,
                builder: content,
              ))
        .whenComplete(() {
          // What the payer typed in an add-on's fields doesn't outlive the sheet.
          model.section?.clear();
          // The route went some other way (the app popped it): still answer once.
          if (!done.isCompleted) done.complete(model.accepted);
        }),
  );
  return done.future;
}

Future<bool> _launch(String link, LaunchMode mode) async {
  final uri = Uri.tryParse(link);
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: mode);
  } on PlatformException {
    return false;
  }
}

/// The value, unless it is blank or the "-" SYNQT sends for a detail it does not have.
String? _shown(String? value) => value == null || value.isBlank || value == '-' ? null : value;

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.model, this.onPresented});

  final PaymentSheetModel model;
  final VoidCallback? onPresented;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _bannerKey = GlobalKey();

  /// Bank and provider fields shown as "couldn't load", scrolled to when Pay finds them empty.
  final _banksFailedKeys = <String, GlobalKey>{};
  final _scroll = ScrollController();
  NextStep? _shownNext;
  int _bannerRequest = 0;

  /// For an add-on method marked secure, such as CARD: the sheet is covered while the app is not in front, so the app
  /// switcher's snapshot shows none of its fields.
  AppLifecycleListener? _lifecycle;
  bool _covered = false;

  PaymentSheetModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    model.addListener(_update);
    if (addonMethods.any((method) => method.code == model.form.code && method.secure) && model.section != null) {
      _lifecycle = AppLifecycleListener(
        onStateChange: (state) => setState(() => _covered = state != AppLifecycleState.resumed),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPresented?.call();
      model.start();
    });
  }

  void _update() {
    if (!mounted) return;
    setState(() {});
    // A new next step starts at the top.
    if (model.next != _shownNext) {
      _shownNext = model.next;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
    final request = model.focusRequest;
    // Text fields scroll to themselves; the banner and a bank list that didn't load are scrolled to here.
    final key = request?.path == 'banner' ? _bannerKey : _banksFailedKeys[request?.path];
    if (request != null && key != null && request.count != _bannerRequest) {
      _bannerRequest = request.count;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = key.currentContext;
        if (target != null) Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 250));
      });
    }
  }

  @override
  void dispose() {
    model.removeListener(_update);
    _lifecycle?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The sheet follows the phone's light or dark setting, also while it is open, even when the app forces its own.
    final brightness = MediaQuery.platformBrightnessOf(context);
    final colors = SynqtColors.forBrightness(brightness);
    return SynqtBrightness(
      brightness: brightness,
      child: Theme(
        data: Theme.of(context).copyWith(
          brightness: brightness,
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: colors.action, brightness: brightness, surface: colors.surface),
          textSelectionTheme: TextSelectionThemeData(cursorColor: colors.action, selectionHandleColor: colors.action),
        ),
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !model.processing) model.close();
          },
          child: Material(
            color: colors.surface,
            child: Stack(
              children: [
                // Screen readers can't wander into the form the processing view covers.
                ExcludeSemantics(
                  excluding: model.processing,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // The header and Pay bar stay on screen, so they grow less with the text size than the form between.
                      MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: _header(colors)),
                      Divider(height: 1, color: colors.border),
                      Flexible(
                        child: Stack(
                          children: [
                            SingleChildScrollView(
                              controller: _scroll,
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: model.next != null
                                    ? [_NextStepView(model: model, next: model.next!)]
                                    : _formContent(colors),
                              ),
                            ),
                            // Just above the bar, however tall the bar has grown with its buttons and the text size.
                            if (model.toast != null)
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 16,
                                child: Center(
                                  child: Semantics(
                                    liveRegion: true,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: ShapeDecoration(color: colors.text, shape: const StadiumBorder()),
                                      child: Text(model.toast!, style: synqtFont(16, color: colors.surface)),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: colors.border),
                      MediaQuery.withClampedTextScaling(maxScaleFactor: 1.6, child: _bottomBar(colors)),
                      // Keeps the Pay button above the keyboard, or else above the home indicator or navigation bar
                      // (padding is 0 while the keyboard covers it). useSafeArea leaves the bottom to the sheet.
                      SizedBox(height: MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom),
                    ],
                  ),
                ),
                if (model.processing) Positioned.fill(child: _processing(colors)),
                if (_covered) Positioned.fill(child: ColoredBox(color: colors.surface)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Wordmark on the left, close button on the right.
  Widget _header(SynqtColors colors) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 6, 8),
    child: Row(
      children: [
        const SynqtLogo(),
        const Spacer(),
        Semantics(
          button: true,
          label: text('synqt_sheet_close'),
          child: InkResponse(
            onTap: model.close,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Center(child: SynqtIconView(SynqtIcon.close, color: colors.text)),
            ),
          ),
        ),
      ],
    ),
  );

  List<Widget> _formContent(SynqtColors colors) => [
    _SummaryCard(summary: model.summary, secure: true),
    if (!model.allFilledIn) ...[
      Padding(
        padding: EdgeInsets.only(top: 24, bottom: model.intro == null ? 16 : 8),
        child: Semantics(
          header: true,
          child: Text(text('synqt_sheet_your_details'), style: synqtFont(20, weight: FontWeight.w600, color: colors.text)),
        ),
      ),
      if (model.intro case final intro?)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(intro, style: synqtFont(16, color: colors.textMuted)),
        ),
    ],
    for (final row in _rows()) _row(row, colors),
    ?model.section?.build(context),
    if (model.banner != null)
      Padding(key: _bannerKey, padding: const EdgeInsets.only(bottom: 16), child: SynqtErrorBanner(model.banner!)),
  ];

  Widget _row((String?, int?, FormInput?) row, SynqtColors colors) => switch (row) {
    (final String section, null, null)
        when model.inputs.any((field) => field.section == section && model.visible(field.path)) =>
      _heading(text(section), colors),
    (null, final int questionIndex, null) when model.questionVisible(questionIndex) => _question(questionIndex, colors),
    (null, null, final FormInput field) when model.visible(field.path) => _field(field, colors),
    _ => const SizedBox.shrink(),
  };

  /// The form in order, as (section heading, question, field) with one set: a question's tiles and all its fields go
  /// where the first of those fields would have been, and a section heading goes before the first field of each section.
  List<(String?, int?, FormInput?)> _rows() {
    final rows = <(String?, int?, FormInput?)>[];
    String? section;
    for (final field in model.inputs) {
      final questionIndex = model.form.oneOfs.indexWhere(
        (oneOf) => oneOf.choices.any((choice) => choice.paths.contains(field.path)),
      );
      if (questionIndex >= 0) {
        final paths = model.form.oneOfs[questionIndex].choices.expand((choice) => choice.paths);
        if (field.path == paths.where((path) => model.inputs.any((input) => input.path == path)).firstOrNull) {
          rows.add((null, questionIndex, null));
        }
        continue;
      }
      if (field.section != null && field.section != section) rows.add((field.section, null, null));
      section = field.section;
      rows.add((null, null, field));
    }
    return rows;
  }

  Widget _heading(String label, SynqtColors colors) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 16),
    child: Semantics(
      header: true,
      child: Text(
        label,
        style: synqtFont(17, weight: FontWeight.w600, color: colors.text),
      ),
    ),
  );

  Widget _question(int questionIndex, SynqtColors colors) {
    final oneOf = model.form.oneOfs[questionIndex];
    final paths = oneOf.choices.expand((ch) => ch.paths).toSet();
    final selected = oneOf.choices.indexOf(model.chosen[questionIndex]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(text(oneOf.question), colors),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ChoiceTiles(
            labels: [for (final ch in oneOf.choices) text(ch.label)],
            selected: selected < 0 ? 0 : selected,
            onSelect: (index) => model.choose(questionIndex, oneOf.choices[index]),
          ),
        ),
        for (final field in model.inputs)
          if (paths.contains(field.path) && model.visible(field.path)) _field(field, colors),
      ],
    );
  }

  Widget _field(FormInput field, SynqtColors colors) {
    if (model.banksMissing(field)) return _banksFailed(field, colors);
    _banksFailedKeys.remove(field.path);
    final options = model.options(field);
    final value = model.values[field.path] ?? '';
    if (options != null) {
      return SynqtDropdown(
        key: ValueKey(field.path),
        label: text(field.label),
        value: value,
        options: options,
        onChanged: (value) => model.setValue(field, value),
        helper: model.hint(field),
        error: model.marks[field.path],
      );
    }
    final request = model.focusRequest;
    return SynqtTextField(
      key: ValueKey(field.path),
      label: text(field.label),
      value: value,
      onChanged: (value) => model.setValue(field, value),
      helper: model.hint(field),
      placeholder: field.placeholder == null ? '' : text(field.placeholder!),
      error: model.marks[field.path],
      keyboard: switch (field.kind) {
        FieldKind.email => SynqtKeyboard.email,
        FieldKind.phone => SynqtKeyboard.phone,
        FieldKind.number => SynqtKeyboard.number,
        _ => field.path.endsWith('Name') ? SynqtKeyboard.name : SynqtKeyboard.text,
      },
      focusRequest: request != null && request.path == field.path ? request.count : 0,
      onFocusChange: (focused) => model.focus(field.path, focused),
      autofillHints: _autofillHints[field.path],
    );
  }

  /// In place of a bank or provider field whose list didn't load: the label, why, and Try again.
  Widget _banksFailed(FormInput field, SynqtColors colors) {
    return Padding(
      key: _banksFailedKeys.putIfAbsent(field.path, GlobalKey.new),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        key: ValueKey(field.path),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text(field.label),
            style: synqtFont(16, weight: FontWeight.w500, color: colors.text),
          ),
          const SizedBox(height: 8),
          SynqtErrorBanner(text('synqt_sheet_banks_failed')),
          const SizedBox(height: 8),
          SynqtButton(
            label: text('synqt_sheet_try_again'),
            onPressed: model.retryBanks,
            kind: SynqtButtonKind.outline,
            loading: model.loadingBanks,
          ),
        ],
      ),
    );
  }

  /// What the platform may offer from the payer's contact card for a field; email and phone get theirs from the keyboard.
  static const _autofillHints = {
    'customerName.titleBefore': [AutofillHints.namePrefix],
    'customerName.firstName': [AutofillHints.givenName],
    'customerName.middleName': [AutofillHints.middleName],
    'customerName.lastName': [AutofillHints.familyName],
    'customerName.titleAfter': [AutofillHints.nameSuffix],
    'account.accountName': [AutofillHints.name],
    'paymentLocation.postalCode': [AutofillHints.postalCode],
    'paymentLocation.city': [AutofillHints.addressCity],
  };

  Widget _bottomBar(SynqtColors colors) {
    final next = model.next;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (next != null) ...[
            if (next.appLink != null) ...[
              SynqtButton(label: text('synqt_next_open_app', [model.methodName]), onPressed: model.openApp),
              const SizedBox(height: 8),
            ],
            SynqtButton(
              label: text('synqt_next_done'),
              onPressed: model.close,
              kind: next.appLink != null ? SynqtButtonKind.outline : SynqtButtonKind.primary,
            ),
          ] else ...[
            SynqtButton(label: text('synqt_sheet_pay', [model.summary.amount]), onPressed: model.pay),
          ],
        ],
      ),
    );
  }

  /// Covers the whole sheet, close button included, so taps never reach the form underneath.
  Widget _processing(SynqtColors colors) => ColoredBox(
    color: colors.surface,
    child: Semantics(
      liveRegion: true, // read out as it appears
      child: MergeSemantics(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const OrbitLoader(),
              const SizedBox(height: 24),
              Text(
                text('synqt_sheet_processing'),
                textAlign: TextAlign.center,
                style: synqtFont(20, weight: FontWeight.w600, color: colors.text),
              ),
              const SizedBox(height: 8),
              Text(
                text('synqt_sheet_processing_detail'),
                textAlign: TextAlign.center,
                style: synqtFont(16, color: colors.textMuted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// One of several answers, as tiles: the chosen tile on action-tint with its border and radio dot in the action
/// colour. Screen readers read each as a selectable button.
class _ChoiceTiles extends StatelessWidget {
  const _ChoiceTiles({required this.labels, required this.selected, required this.onSelect});

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = SynqtColors.of(context);
    return Column(
      children: [
        for (var index = 0; index < labels.length; index++)
          Padding(
            padding: EdgeInsets.only(bottom: index == labels.length - 1 ? 0 : 8),
            child: Semantics(
              button: true,
              selected: index == selected,
              inMutuallyExclusiveGroup: true,
              child: Material(
                color: index == selected ? colors.actionTint : colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: index == selected ? colors.action : colors.borderControl,
                    width: index == selected ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onSelect(index),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: index == selected ? colors.action : colors.textMuted, width: 2),
                          ),
                          child: index == selected
                              ? DecoratedBox(
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: colors.action),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            labels[index],
                            style: synqtFont(16, weight: FontWeight.w500, color: colors.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The checkout's order summary: amount due in large type, then who, how and which order.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, this.showReference = true, this.secure = false});

  final PaymentSummary summary;
  final bool showReference;

  /// The form's card ends with the secure checkout line; the next step's doesn't.
  final bool secure;

  @override
  Widget build(BuildContext context) {
    final colors = SynqtColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.surfacePanel, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow, not brand magenta: magenta on the light panel is 2.89:1.
          _Eyebrow(text('synqt_sheet_amount_due')),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Text(
              summary.amount,
              style: synqtFont(28, weight: FontWeight.w600, color: colors.text, tabular: true),
            ),
          ),
          Divider(height: 1, color: colors.border),
          if (summary.merchant != null) _DetailRow(label: text('synqt_sheet_paying'), value: summary.merchant!),
          _DetailRow(label: text('synqt_sheet_payment_method'), value: summary.method),
          if (showReference) _DetailRow(label: text('synqt_sheet_reference'), value: summary.reference),
          if (secure)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: MergeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SynqtIconView(SynqtIcon.lock, size: 16, color: colors.textMuted),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(text('synqt_sheet_secure_checkout'), textAlign: TextAlign.center, style: synqtFont(13, color: colors.textMuted)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.value);

  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value.toUpperCase(),
    style: synqtFont(13, weight: FontWeight.w500, color: SynqtColors.of(context).eyebrow).copyWith(letterSpacing: 1),
  );
}

/// A label and value; with [copy], a button that copies that text. In a card with copy buttons every row keeps the
/// button's column, so values line up.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.copy,
    this.copyColumn = false,
    this.onCopy,
    this.tabular = false,
  });

  final String label;
  final String value;
  final String? copy;
  final bool copyColumn;
  final bool tabular;
  final void Function(String label, String value)? onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = SynqtColors.of(context);
    final labelText = Text(label, style: synqtFont(16, color: colors.textMuted));
    final valueText = Text(
      value,
      textAlign: TextAlign.end,
      style: synqtFont(16, weight: FontWeight.w500, color: colors.text, tabular: tabular),
    );
    // Side by side, the largest text sizes break words mid-word, so label and value stack instead.
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    final icon = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: Center(child: SynqtIconView(SynqtIcon.copy, size: 20, color: colors.textMuted)),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: MergeSemantics(
              child: stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        labelText,
                        const SizedBox(height: 4),
                        Text(value, style: valueText.style),
                      ],
                    )
                  : Row(
                      children: [
                        labelText,
                        const SizedBox(width: 16),
                        Expanded(child: valueText),
                      ],
                    ),
            ),
          ),
          if (copyColumn)
            copy == null
                ? ExcludeSemantics(child: Opacity(opacity: 0, child: icon)) // keeps the copy column, so values line up
                : Semantics(
                    button: true,
                    label: text('synqt_next_copy', [label]),
                    child: InkResponse(onTap: () => onCopy?.call(label, copy!), child: icon),
                  ),
        ],
      ),
    );
  }
}

/// What the payer does after SYNQT accepted the payment, for methods finished in another app or by bank transfer.
class _NextStepView extends StatelessWidget {
  const _NextStepView({required this.model, required this.next});

  final PaymentSheetModel model;
  final NextStep next;

  @override
  Widget build(BuildContext context) {
    final colors = SynqtColors.of(context);
    final transfer = next.payInto;
    final amount = next.amountToPay?.toString() ?? model.summary.amount;
    final name = model.methodName;
    final how = transfer != null
        ? text('synqt_next_transfer')
        : next.appLink != null && next.qrCodeImageUrl != null
        ? text('synqt_next_open_or_scan', [name])
        : next.appLink != null
        ? text('synqt_next_open', [name])
        : text('synqt_next_scan', [name]);
    // A transfer reference that contains the order ID would read as a second, near-identical "Reference", so the order ID goes.
    final orderIdInReference = transfer != null && (next.reference?.contains(model.summary.reference) ?? false);
    final reference = transfer != null ? next.reference : null;
    final exact = next.amountToPay;
    final qr = next.qrCodeImageUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryCard(summary: model.summary.withAmount(amount), showReference: !orderIdInReference),
        // The countdown (with a transfer's reference) sits in one card above the instructions, the same for every method.
        if (reference != null || next.expiresAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: _ReferenceCard(
              reference: reference,
              expiresAt: next.expiresAt,
              onCopy: (value) => model.copyValue(text('synqt_sheet_reference'), value),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Semantics(
            header: true,
            child: Text(
              transfer != null ? text('synqt_next_transfer_title') : text('synqt_next_title', [name]),
              style: synqtFont(20, weight: FontWeight.w600, color: colors.text),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(how, style: synqtFont(16, color: colors.textMuted)),
        ),
        if (exact != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              text('synqt_next_pay_exactly', [exact.toString()]),
              style: synqtFont(16, weight: FontWeight.w500, color: colors.text, tabular: true),
            ),
          ),
        if (transfer != null) ...[
          // A banking app wants the number alone, not "R100.00".
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _transferCard(
              transfer,
              amount,
              exact?.plainAmount ?? model.summary.amount.replaceAll(RegExp(r'[^0-9.]'), ''),
              colors,
            ),
          ),
          _notice(colors),
        ] else if (next.reference != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              text('synqt_next_reference', [next.reference!]),
              style: synqtFont(16, weight: FontWeight.w500, color: colors.text),
            ),
          ),
        if (qr != null && Uri.tryParse(qr) != null) _qrCode(qr, colors),
        if (model.appProblem != null)
          Padding(padding: const EdgeInsets.only(bottom: 16), child: SynqtErrorBanner(model.appProblem!)),
      ],
    );
  }

  /// The bank details an OFFLINE payer types into their own banking app, each with a copy button.
  Widget _transferCard(AccountResponse account, String amount, String copyAmount, SynqtColors colors) {
    // Branch is the primary detail and often repeats the bank code, so the bank code only stands in when there is no branch.
    final branch = switch ((_shown(account.bankBranch), _shown(account.bankCode))) {
      (final branch?, _) => (text('synqt_next_branch'), branch, branch),
      (null, final code?) => (text('synqt_next_bank_code'), code, code),
      _ => null,
    };
    final rows = <(String, String, String?)>[
      if (_shown(account.accountName) case final value?) (text('synqt_next_account_name'), value, value),
      if (_shown(account.accountNumber) case final value?) (text('synqt_next_account_number'), value, value),
      if (_shown(account.bankName) case final value?) (text('synqt_next_bank'), value, null),
      if (_shown(account.accountType) case final value?) (text('synqt_next_account_type'), value, null),
      ?branch,
      (text('synqt_sheet_amount_due'), amount, copyAmount),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(color: colors.surfacePanel, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          for (final (index, detail) in rows.indexed)
            _DetailRow(
              label: detail.$1,
              value: detail.$2,
              copy: detail.$3,
              copyColumn: true,
              onCopy: model.copyValue,
              tabular: index == rows.length - 1, // the amount
            ),
        ],
      ),
    );
  }

  /// What the payer must know before transferring. Draft wording, based on the Payment Web App's notice.
  Widget _notice(SynqtColors colors) {
    const items = [
      'synqt_next_notice_exact',
      'synqt_next_notice_once',
      'synqt_next_notice_fees',
      'synqt_next_notice_own_account',
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              text('synqt_next_notice_title'),
              style: synqtFont(16, weight: FontWeight.w500, color: colors.text),
            ),
          ),
          for (var index = 0; index < items.length; index++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                text('synqt_next_notice_item', [index + 1, text(items[index])]),
                style: synqtFont(16, color: colors.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  /// SYNQT's QR image, on white in both themes because scanners need a light ground.
  Widget _qrCode(String url, SynqtColors colors) {
    Widget box(Widget? child) => Container(
      width: 240,
      height: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
    Widget caption(String key) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text(key, [model.methodName]),
        textAlign: TextAlign.center,
        style: synqtFont(13, color: colors.textMuted),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Image.network(
          url,
          filterQuality: FilterQuality.none,
          semanticLabel: text('synqt_next_qr_description', [model.methodName]),
          frameBuilder: (context, child, frame, _) => frame == null
              ? Column(children: [box(null), caption('synqt_next_qr_loading')])
              : Column(children: [box(child), caption('synqt_next_qr_caption')]),
          errorBuilder: (_, _, _) => Text(text('synqt_next_qr_failed'), style: synqtFont(13, color: colors.textMuted)),
        ),
      ),
    );
  }
}

/// The countdown card at the top of every next step; for OFFLINE it leads with the reference the payer must quote, as
/// a missing one fails the payment.
class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({required this.reference, required this.expiresAt, required this.onCopy});

  final String? reference;
  final String? expiresAt;
  final ValueChanged<String> onCopy;

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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (reference != null) ...[
            _Eyebrow(text('synqt_next_reference_title')),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    reference!,
                    textAlign: TextAlign.end,
                    style: synqtFont(24, weight: FontWeight.w600, color: colors.text),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(12, 0), // the icon itself ends on the card's edge, like the time below
                  child: Semantics(
                    button: true,
                    label: text('synqt_next_copy', [text('synqt_sheet_reference')]),
                    child: InkResponse(
                      onTap: () => onCopy(reference!),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        child: Center(child: SynqtIconView(SynqtIcon.copy, size: 20, color: colors.textMuted)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              text('synqt_next_reference_needed'),
              textAlign: TextAlign.end,
              style: synqtFont(14, color: colors.textMuted),
            ),
          ],
          if (expiresAt != null) ...[
            if (reference != null)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Divider(height: 1, color: colors.border),
              ),
            _Countdown(expiresAt: expiresAt!),
          ],
        ],
      ),
    );
  }
}

/// "Time left to pay" over a large "01:59:17", ticking every second until [expiresAt], then a line saying time ran out.
class _Countdown extends StatefulWidget {
  const _Countdown({required this.expiresAt});

  final String expiresAt;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SynqtColors.of(context);
    final left = timeLeft(widget.expiresAt, DateTime.now());
    if (left == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: left.isEmpty
          ? Text(
              text('synqt_next_expired'),
              textAlign: TextAlign.end,
              style: synqtFont(16, color: colors.danger),
            )
          : Semantics(
              label: '${text('synqt_next_time_left')} $left',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Eyebrow(text('synqt_next_time_left')),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SynqtIconView(SynqtIcon.timer, size: 28, color: colors.text),
                      const SizedBox(width: 8),
                      Text(
                        left,
                        style: synqtFont(28, weight: FontWeight.w600, color: colors.text, tabular: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
