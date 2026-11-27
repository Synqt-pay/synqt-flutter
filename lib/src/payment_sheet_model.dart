import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'addon.dart';
import 'method_form.dart';
import 'payment_methods.dart';
import 'results.dart';
import 'results.dart' as results show methodName;
import 'strings.dart';

/// What the sheet's order summary shows. [merchant] is null when the token cannot read GET /merchant-info.
final class PaymentSummary {
  const PaymentSummary({required this.amount, required this.merchant, required this.method, required this.reference});

  final String amount;
  final String? merchant;
  final String method;
  final String reference;

  PaymentSummary withAmount(String amount) =>
      PaymentSummary(amount: amount, merchant: merchant, method: method, reference: reference);
}

/// The payment sheet's state and behaviour, apart from the widgets: Pay checks the values, builds the typed method and
/// hands it to [submit]; a processing state covers the form meanwhile, and every error comes back next to its field.
/// The presenter supplies how to open links, copy text, announce errors and close the sheet. [operators] is null when
/// SYNQT's list of banks and providers could not be loaded.
class PaymentSheetModel extends ChangeNotifier {
  PaymentSheetModel({
    required this.form,
    required Map<String, String> prefill,
    required List<PaymentOperator>? operators,
    required this.summary,
    this.section,
    required Future<CreatePayinResult> Function(PaymentMethod) submit,
    Future<CreatePayinResult> Function(Map<String, Object?>)? submitJson,
  }) : _operators = operators ?? const [],
       banksFailed = operators == null,
       _submit = submit,
       _submitJson = submitJson,
       methodName = results.methodName(form.code) ?? text(form.name),
       inputs = form.fields
           .where((field) => !(field.kind == FieldKind.paymentOperator && (operators ?? []).isEmpty && !field.required))
           .toList() {
    // A dropdown prefill that is none of its options is cleared, but shown with the field's error below.
    final unlisted = <String>{};
    for (final field in inputs) {
      final value = prefill[field.path] ?? '';
      final choices = _options(field, operators ?? const []);
      final listed = choices == null || choices.any((option) => option.value == value);
      if (!listed && !value.isBlank) unlisted.add(field.path);
      values[field.path] = listed ? value : '';
    }
    chosen = [
      for (final oneOf in form.oneOfs)
        oneOf.choices.where((choice) => !(prefill[choice.paths[0]] ?? '').isBlank).firstOrNull ?? oneOf.choices[0],
    ];
    for (var questionIndex = 0; questionIndex < chosen.length; questionIndex++) {
      _clearOthers(questionIndex, chosen[questionIndex]);
    }
    filledIn = form.filledIn(effectiveValues(), prefill, chosen).toSet();
    // A prefill left in view because it fails its checks shows why from the start.
    for (final field in inputs) {
      if (!form.shows(field.path, chosen) || filledIn.contains(field.path)) continue;
      if (unlisted.contains(field.path)) {
        marks[field.path] = text('synqt_sheet_check_field');
        _invalid.add(field.path);
      } else if (!(prefill[field.path] ?? '').isBlank) {
        _check(field.path);
      }
    }
  }

  final MethodForm form;
  final PaymentSummary summary;
  final String methodName;
  List<PaymentOperator> _operators;

  /// SYNQT's list of banks and providers could not be loaded, so a mandatory bank or provider field can't be filled in.
  bool banksFailed;
  bool loadingBanks = false;
  final Future<CreatePayinResult> Function(PaymentMethod) _submit;

  /// An add-on method's own fields, which it draws, checks and builds itself.
  final MethodSection? section;

  /// Sends the `paymentMethod` object [section] built.
  final Future<CreatePayinResult> Function(Map<String, Object?>)? _submitJson;

  /// The fields the payer could fill in: an optional bank with no list from SYNQT has nothing to choose, so it goes.
  final List<FormInput> inputs;
  final Map<String, String> values = {};

  /// The tile picked for each question: the one the app prefilled, else the first.
  late List<Choice> chosen;
  final Map<String, String> marks = {};
  String? banner;

  /// Fields the app prefilled with a value that passes its checks: hidden, but still sent. Shown again if SYNQT refuses it.
  Set<String> filledIn = {};
  bool processing = false;
  NextStep? next;
  String? appProblem;
  String? toast;

  /// The field (or `banner`) to scroll to and focus, with a counter so asking for the same one twice still moves there.
  ({String path, int count})? focusRequest;

  // Fields are checked as the payer goes, but a field they have not typed in only shows "Required" after Pay.
  final _edited = <String>{};
  final _invalid = <String>{}; // showing a problem found here, rechecked on every change
  final _refused = <String>{}; // showing SYNQT's error, kept until the payer edits that field
  String? _focused;

  /// The payin result once SYNQT accepted it, returned however the payer closes the sheet afterwards.
  CreatePayinResult? accepted;
  bool _openedApp = false;
  bool _finished = false;

  // Set by the presenter.
  void Function(CreatePayinResult?) onFinish = (_) {};
  VoidCallback onPaymentStarted = () {};

  /// Opens a link in the method's own app if it is installed; false if nothing took it.
  Future<bool> Function(String) openInApp = (_) async => false;

  /// Opens a link wherever the system sends it (the browser if no app claims it); false if nothing can.
  Future<bool> Function(String) openLink = (_) async => false;
  void Function(String) copy = (_) {};

  /// Reads text out to screen reader users without moving their focus.
  void Function(String) announce = (_) {};

  /// Loads the banks and providers again, as the presenter first did; null if they still could not be loaded.
  Future<List<PaymentOperator>?> Function() reloadOperators = () async => null;

  /// Everything mandatory came from the app, so pay straight away; the processing view covers the form, and any
  /// refusal brings the form back with the error.
  void start() {
    if (section == null && form.readyToPay(effectiveValues(), filledIn.toList(), chosen)) pay();
  }

  /// Values as they are checked and sent: fields of tiles the payer did not pick read as blank.
  Map<String, String> effectiveValues() => {
    for (final field in inputs) field.path: form.shows(field.path, chosen) ? values[field.path] ?? '' : '',
  };

  /// The choices for a dropdown field, with "Choose one" or "No preference" first, or null for a typed field.
  List<({String value, String label})>? options(FormInput field) {
    final choices = _options(field, _operators);
    if (choices == null) return null;
    // A provider is only asked for when it is needed, so it never offers "No preference".
    final header = text(
      field.required || field.kind == FieldKind.provider ? 'synqt_sheet_choose_one' : 'synqt_sheet_no_preference',
    );
    return [(value: '', label: header), ...choices];
  }

  static List<({String value, String label})>? _options(FormInput field, List<PaymentOperator> operators) =>
      switch (field.kind) {
        FieldKind.choice => [for (final option in field.options) (value: option.value, label: text(option.label))],
        FieldKind.paymentOperator =>
          operators.isEmpty
              ? null
              : [for (final paymentOperator in operators) (value: paymentOperator.code, label: paymentOperator.name)],
        // Typed when SYNQT lists no providers.
        FieldKind.provider =>
          providers(operators).isEmpty
              ? null
              : [for (final provider in providers(operators)) (value: provider.code, label: provider.name)],
        _ => null,
      };

  /// A mandatory bank or provider field shown as "couldn't load" with Try again, as the payer can't fill it in. An
  /// optional one stays as it was without a list: a bank field is hidden, a provider field takes a typed code.
  bool banksMissing(FormInput field) =>
      banksFailed && field.required && (field.kind == FieldKind.paymentOperator || field.kind == FieldKind.provider);

  /// Try again: loads the banks and providers once more, with the same retries; the fields come back on success.
  Future<void> retryBanks() async {
    if (!banksFailed || loadingBanks) return;
    loadingBanks = true;
    _changed();
    final loaded = await reloadOperators();
    loadingBanks = false;
    if (loaded == null) {
      announce(text('synqt_sheet_banks_failed'));
    } else {
      _operators = loaded;
      banksFailed = false;
      for (final field in inputs) {
        if (field.kind != FieldKind.paymentOperator && field.kind != FieldKind.provider) continue;
        marks.remove(field.path);
        _invalid.remove(field.path);
      }
    }
    _changed();
  }

  /// The hint under a field. A bank or provider the payer types (SYNQT listed none) says what to type.
  String hint(FormInput field) {
    if (options(field) == null && field.kind == FieldKind.paymentOperator) return text('synqt_sheet_hint_bank_code');
    if (options(field) == null && field.kind == FieldKind.provider) return text('synqt_sheet_hint_provider_code');
    return field.hint == null ? '' : text(field.hint!);
  }

  bool visible(String path) => form.shows(path, chosen) && !filledIn.contains(path);

  /// A tile question is hidden once the app filled in every field of the chosen tile.
  bool questionVisible(int questionIndex) =>
      !chosen[questionIndex].paths.where((path) => inputs.any((field) => field.path == path)).every(filledIn.contains);

  /// Everything filled in by the app: the whole details section goes, leaving the summary and Pay.
  bool get allFilledIn => inputs.isNotEmpty && !inputs.any((field) => visible(field.path));

  /// Only a form with nothing to enter gets an intro line.
  String? get intro => inputs.isEmpty && section == null ? text('synqt_sheet_intro_nothing_to_enter') : null;

  /// The payer typed in a field. Input longer than the field's limit is cut off.
  void setValue(FormInput field, String value) {
    values[field.path] = field.maxLength != null && value.runes.length > field.maxLength!
        ? String.fromCharCodes(value.runes.take(field.maxLength!))
        : value;
    _edited.add(field.path);
    if (_refused.remove(field.path)) marks.remove(field.path);
    if (_invalid.contains(field.path)) _check(field.path);
    _changed();
  }

  /// Focus moved; the field it left is checked if the payer typed in it.
  void focus(String path, bool isFocused) {
    if (isFocused) {
      _focused = path;
      return;
    }
    if (_focused != path) return;
    _focused = null;
    if (_edited.contains(path) && !_refused.contains(path)) {
      final before = marks[path];
      _check(path);
      final now = marks[path];
      if (now != null && now != before) {
        announce(
          text('synqt_sheet_field_error', [text(form.fields.firstWhere((field) => field.path == path).label), now]),
        );
      }
      _changed();
    }
  }

  void _check(String path) {
    final field = form.fields.firstWhere((input) => input.path == path);
    final message = problem(
      field,
      effectiveValues(),
      mustFill: chosen.any((choice) => choice.required.contains(path)),
    )?.text;
    if (message == null) {
      marks.remove(path);
      _invalid.remove(path);
    } else {
      marks[path] = message;
      _invalid.add(path);
    }
  }

  /// Shows the picked tile's fields. The others are emptied, so a detail the payer switched away from is never sent.
  void choose(int questionIndex, Choice choice) {
    chosen = [...chosen]..[questionIndex] = choice;
    _clearOthers(questionIndex, choice);
    _changed();
  }

  void _clearOthers(int questionIndex, Choice choice) {
    for (final path in form.oneOfs[questionIndex].choices.expand((choice) => choice.paths)) {
      if (choice.paths.contains(path) || !values.containsKey(path)) continue;
      values[path] = '';
      marks.remove(path);
      _edited.remove(path);
      _invalid.remove(path);
      _refused.remove(path);
      filledIn.remove(path); // emptied, so the payer enters it if they come back to this tile
    }
  }

  void pay() {
    marks.clear();
    _invalid.clear();
    _refused.clear();
    banner = null;
    final current = effectiveValues();
    final problems = form.problems(current, chosen);
    if (problems.isNotEmpty) return _showErrors(problems);
    final section = this.section;
    if (section != null) {
      final spoken = section.check();
      if (spoken.isNotEmpty) return announce(spoken.join('\n'));
      // The add-on builds its method only now, so it can do slow work such as encrypting card details.
      return _startSending(() async {
        final json = await section.paymentMethod();
        onPaymentStarted();
        return _submitJson!(json);
      });
    }
    final PaymentMethod method;
    try {
      method = form.build(FormValues(current));
    } on SynqtArgumentException catch (error) {
      return _showErrors([PayinError(error.path, text('synqt_sheet_required'))]);
    }
    _startSending(() {
      onPaymentStarted();
      return _submit(method);
    });
  }

  /// While the request runs the form, close button included, is covered so the sheet cannot be closed half way through.
  void _startSending(Future<CreatePayinResult> Function() request) {
    processing = true;
    _changed();
    unawaited(_send(request));
  }

  Future<void> _send(Future<CreatePayinResult> Function() request) async {
    try {
      final result = await request();
      if (result is InstructionsResult &&
          (result.nextStep.appLink != null ||
              result.nextStep.qrCodeImageUrl != null ||
              result.nextStep.payInto != null)) {
        accepted = result;
        _showNextStep(result.nextStep);
      } else {
        finish(result);
      }
    } on MethodSectionException catch (error) {
      _showErrors([PayinError(null, error.payerMessage)]);
    } on SynqtApiException catch (error) {
      _showErrors(payinErrors(error), fromSynqt: true);
    } on http.ClientException {
      _showErrors([PayinError(null, text('synqt_error_unreachable'))]);
    } on TimeoutException {
      _showErrors([PayinError(null, text('synqt_error_unreachable'))]);
    } catch (_) {
      _showErrors([PayinError(null, text('synqt_failure_general'))]);
    } finally {
      processing = false;
      _changed();
    }
  }

  /// Completes the sheet once, however it is closed.
  void finish(CreatePayinResult? result) {
    if (_finished) return;
    _finished = true;
    onFinish(result);
  }

  /// Close or Done: the accepted result if SYNQT took the payment, else null.
  void close() => finish(accepted);

  /// For methods the payer finishes elsewhere: open the method's app on this phone, scan the QR code from another one,
  /// or (Pay offline) transfer to SYNQT's account from their banking app. The app opens once by itself; coming back
  /// shows this step, with the button to open it again.
  void _showNextStep(NextStep step) {
    next = step;
    final link = step.appLink ?? step.qrCodeData;
    if (_openedApp || link == null) return;
    _openedApp = true;
    unawaited(openInApp(link));
  }

  /// Checked again on each tap, as the payer may install the app while the sheet is open.
  Future<void> openApp() async {
    final link = next?.appLink;
    if (link == null) return;
    if (await openInApp(link)) return;
    final data = next?.qrCodeData;
    if (data != null && await openInApp(data)) return;
    if (!await openLink(link)) {
      appProblem = text('synqt_next_no_app', [methodName]);
      announce(appProblem!);
      _changed();
    }
  }

  void copyValue(String label, String value) {
    copy(value);
    final message = text('synqt_next_copied', [label]);
    toast = message;
    _changed();
    Timer(const Duration(seconds: 2), () {
      if (toast == message) {
        toast = null;
        _changed();
      }
    });
  }

  /// Errors for a shown field go under it; the rest go in the banner above the Pay button, named by label, not JSON
  /// path. The first field with an error is scrolled to and focused, and screen readers read every error out.
  void _showErrors(List<PayinError> errors, {bool fromSynqt = false}) {
    final general = <String>[];
    final spoken = <String>[];
    String? first;
    for (final error in errors) {
      final attr = error.attr;
      final said = attr == null ? null : section?.showError(attr, error.text);
      if (said != null) {
        spoken.add(said);
        first ??= 'section'; // the section focuses its own field
        continue;
      }
      final path = attr == null
          ? null
          : form.fields.where((field) => attr == field.path || attr.endsWith('.${field.path}')).firstOrNull?.path;
      final input = inputs.where((field) => field.path == path).firstOrNull;
      if (path != null && form.shows(path, chosen) && input != null) {
        filledIn.remove(path); // a prefilled value was refused: let the payer correct it
        marks[path] = error.text;
        spoken.add(text('synqt_sheet_field_error', [text(input.label), error.text]));
        (fromSynqt ? _refused : _invalid).add(path);
        first ??= path;
      } else if (form.fields.where((candidate) => candidate.path == path).firstOrNull case final field?) {
        general.add(text('synqt_sheet_field_error', [text(field.label), error.text]));
      } else {
        general.add(error.text);
      }
    }
    if (general.isNotEmpty) banner = general.join('\n');
    announce([...spoken, ...general].join('\n'));
    final target = first ?? (general.isEmpty ? null : 'banner');
    if (target != null) focusRequest = (path: target, count: (focusRequest?.count ?? 0) + 1);
    _changed();
  }

  // The sheet's widget listens; once it is gone, nobody does, so a late reply from SYNQT changes nothing on screen.
  void _changed() => notifyListeners();
}

/// Payer-facing messages for a refused POST /payins.
List<PayinError> payinErrors(SynqtApiException error) {
  final messages = [
    for (final err in error.errors)
      if (err.code == 'SYSTEM')
        PayinError(err.field, text('synqt_error_system'))
      else if (err.code == 'PAYIN_ALREADY_STARTED')
        PayinError(err.field, text('synqt_error_already_started'))
      else
        // SYNQT's description is written for the merchant, so a code without payer wording gets a generic one.
        PayinError(
          err.field,
          text('synqt_error_with_code', [
            text(
              payerMessageKey(err.code) ?? (err.field != null ? 'synqt_sheet_check_field' : 'synqt_failure_general'),
            ),
            err.code,
          ]),
        ),
  ];
  if (messages.isNotEmpty) return messages;
  return switch (error.httpCode) {
    401 => [PayinError(null, text('synqt_error_session_expired'))],
    403 => [PayinError(null, text('synqt_error_not_allowed'))],
    _ => [
      PayinError(null, text('synqt_error_http', [error.httpCode])),
    ],
  };
}

/// Time from [now] to [iso] as "01:59:17", or "" once it has passed. Null if [iso] is unreadable.
String? timeLeft(String iso, DateTime now) {
  final at = DateTime.tryParse(iso);
  if (at == null) return null;
  final secs = at.difference(now).inSeconds;
  String two(int number) => number.toString().padLeft(2, '0');
  return secs <= 0 ? '' : '${two(secs ~/ 3600)}:${two(secs % 3600 ~/ 60)}:${two(secs % 60)}';
}

/// An app's own URL scheme, tried when it does not take SYNQT's https link as a universal link.
const appSchemes = {'SNAPSCAN_QR': 'snapscan'};

/// [link], then the same link on [scheme] if it is an https link.
List<String> appLinks(String link, String? scheme) =>
    scheme == null || !link.startsWith('https://') ? [link] : [link, scheme + link.substring('https'.length)];
