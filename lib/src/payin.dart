import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'addon.dart';
import 'method_form.dart';
import 'method_forms.dart';
import 'payment_app.dart';
import 'payment_methods.dart';
import 'payment_sheet.dart';
import 'results.dart';
import 'synqt.dart';

/// One order's payin, from `Synqt.payin`. Holds the token, ID, amount and URLs so each call needs only what is new.
/// Calls throw [SynqtApiException] when SYNQT refuses them, and `http.ClientException` or a `TimeoutException` when it
/// cannot be reached.
final class Payin {
  Payin._(
    this._synqt, {
    required String token,
    required this.id,
    required this.money,
    required this.returnUrl,
    required this.callbackUrl,
  }) : _token = token;

  final Synqt _synqt;
  final String _token;
  final String id;
  final Money money;
  final String returnUrl;
  final String callbackUrl;

  /// Creates the payin with a payment method you built yourself. [customerIp] is checked against the merchant's IP
  /// allow and deny lists, so pass the payer's real IP if you have it. A retry after a network failure is safe: if
  /// SYNQT already accepted this payin ID, the existing payin is fetched instead. If that payin was made with a
  /// different method, this throws [SynqtApiException] (409, PAYIN_ALREADY_STARTED): start a new payin to pay another way.
  ///
  /// Throws [SynqtArgumentException] before sending if a shared type such as [Account] lacks a field this method
  /// needs, or has one it does not take.
  Future<CreatePayinResult> create(PaymentMethod paymentMethod, {String? customerIp}) {
    validatePaymentMethod(paymentMethod);
    return _create(paymentMethod.toJson(), paymentMethod.paymentMethodCode, customerIp);
  }

  Future<CreatePayinResult> _create(Map<String, Object?> paymentMethod, String code, String? customerIp) async {
    final body = {
      'paymentRequested': {'money': money.toJson()},
      'paymentMethod': paymentMethod,
      'returnUrl': returnUrl,
      'callbackUrl': callbackUrl,
      'customerIp': ?customerIp,
    };
    String data;
    try {
      data = await synqtCall(_synqt, 'POST', '/payins/$id', _token, body);
    } on SynqtApiException catch (error) {
      if (error.httpCode != 409) rethrow;
      data = await synqtCall(_synqt, 'GET', '/payins/$id', _token);
      requireSameMethod(data, code);
    }
    return parseCreatePayin(data);
  }

  /// Methods, banks and providers SYNQT offers this merchant for [money]. Send the same [segmentCode] when paying.
  Future<List<PaymentOption>> availablePaymentOptions({String? segmentCode}) async {
    final body = {'money': money.toJson(), 'segmentCode': ?segmentCode};
    return parsePaymentOptions(
      jsonMap(jsonDecode(await synqtCall(_synqt, 'POST', '/payins/!availablePaymentOptions', _token, body))) ??
          const {},
    );
  }

  /// For display only. Fulfil orders from your backend's own status check, never from this. Before a payment is sent,
  /// SYNQT answers HTTP 410.
  Future<PayinStatus> status() async =>
      parsePayinStatus(jsonMap(jsonDecode(await synqtCall(_synqt, 'GET', '/payins/$id', _token))) ?? const {});

  /// The payer's bank or UTR reference, for methods that need it. The token must allow
  /// `POST /payins/{id}/!setExternalReference`.
  Future<void> setExternalReference(String reference) async {
    if (reference.isEmpty || reference.length > 512) {
      throw const SynqtArgumentException('reference must be 1 to 512 characters');
    }
    await synqtCall(_synqt, 'POST', '/payins/$id/!setExternalReference', _token, {'reference': reference});
  }

  /// Link to SYNQT's hosted Payment Web App for this payin. [paymentMethodCode] opens it on that method (one
  /// [availablePaymentOptions] returns) while still letting the payer pick another. [prefill] takes the Payment Web
  /// App's own parameter names, such as `phoneNumber` or `emailAddress`, and the payer can still change them. [extra]
  /// adds any other parameter as given, after these.
  String paymentAppUrl({
    required String merchantCode,
    String? paymentMethodCode,
    Map<String, String> prefill = const {},
    Map<String, String> extra = const {},
  }) {
    final params = [
      ('merchantCode', merchantCode),
      ('idPayin', id),
      ('token', _token),
      ('amount', money.plainAmount),
      ('currencyCode', money.currencyCode),
      ('callbackUrl', callbackUrl),
      ('returnUrl', returnUrl),
      if (paymentMethodCode != null) ...[('paymentMethodCode', paymentMethodCode), ('optionsAvailable', 'true')],
      for (final entry in prefill.entries) (entry.key, entry.value),
      if (prefill.isNotEmpty) ('allowCustomerDataChange', 'true'),
      for (final entry in extra.entries) (entry.key, entry.value),
    ];
    return '${_synqt.environment.paymentAppBaseUrl}?${params.map((param) => '${_enc(param.$1)}=${_enc(param.$2)}').join('&')}';
  }

  /// Collects the payer's details for [paymentMethodCode] (one of `Synqt.directPaymentMethods`) in a Synqt-branded
  /// bottom sheet over [context], then creates the payin as [create] does. Errors, including SYNQT's field errors, stay
  /// in the sheet so the payer can correct them. Returns null if the payer closes it.
  ///
  /// The bank or provider field lists the banks [availablePaymentOptions] returns for this payin and
  /// [paymentMethodCode] (PAYIN_CREATE allows that call); an optional one is hidden when SYNQT lists none. The summary
  /// names the merchant when the token also allows `GET /merchant-info`. [prefill] is keyed by field path, such as
  /// `emailAddress` or `customerName.lastName`. CARD is offered only with SYNQT's card add-on, for PCI DSS compliant
  /// merchants.
  ///
  /// [onPresented] runs once the sheet is on screen, and [onPaymentStarted] each time a payment is sent to SYNQT (the
  /// details passed the sheet's checks; SYNQT may still refuse them, and then there may be no payin). The future
  /// completes once the sheet has closed.
  ///
  /// Throws [SynqtArgumentException] only for a [paymentMethodCode] the sheet does not support.
  Future<CreatePayinResult?> presentPaymentSheet(
    BuildContext context, {
    required String paymentMethodCode,
    Map<String, String> prefill = const {},
    String? customerIp,
    VoidCallback? onPresented,
    VoidCallback? onPaymentStarted,
  }) async {
    final addon = addonMethods.where((method) => method.code == paymentMethodCode).firstOrNull;
    final form =
        methodForms.where((form) => form.code == paymentMethodCode).firstOrNull ??
        // An add-on's method draws its own fields, so the sheet gets an empty form for it.
        (addon == null
            ? null
            : MethodForm(addon.code, '', const [], build: (_) => throw StateError('built by the add-on'))) ??
        (throw SynqtArgumentException('Unknown paymentMethodCode $paymentMethodCode'));
    final (operators, merchant) = await _sheetContext(form);
    if (!context.mounted) return null;
    final summary = PaymentSummary(
      amount: money.toString(),
      merchant: merchant,
      method: methodName(form.code)!,
      reference: id,
    );
    final model = PaymentSheetModel(
      form: form,
      prefill: prefill,
      operators: operators,
      summary: summary,
      section: addon?.section(this, prefill),
      submit: (method) => create(method, customerIp: customerIp),
      submitJson: (json) => _create(json, form.code, customerIp),
    )..onPaymentStarted = onPaymentStarted ?? () {};
    model.reloadOperators = () => sheetOperators(form);
    return showPaymentSheet(context, model, onPresented: onPresented);
  }

  /// Shows SYNQT's hosted Payment Web App full screen over [context], and completes once the payer reaches
  /// [returnUrl] or closes it. [onPresented] runs once it is on screen. Links to other apps (bank apps, UPI) open
  /// outside it. [paymentMethodCode], [prefill] and [extra] are as for [paymentAppUrl]. Either way, ask [status] where
  /// the payment stands.
  Future<PaymentAppResult> presentPaymentApp(
    BuildContext context, {
    required String merchantCode,
    String? paymentMethodCode,
    Map<String, String> prefill = const {},
    Map<String, String> extra = const {},
    VoidCallback? onPresented,
  }) {
    final url = paymentAppUrl(
      merchantCode: merchantCode,
      paymentMethodCode: paymentMethodCode,
      prefill: prefill,
      extra: extra,
    );
    return showPaymentApp(context, Uri.parse(url), Uri.parse(returnUrl), onPresented: onPresented);
  }

  /// Opens [paymentAppUrl] in the browser and returns whether it opened, not when the payer is done: the payer comes
  /// back through [returnUrl], which must then be a universal link (iOS) or verified App Link (Android) your app
  /// handles. To know when they are done in the app itself, use [presentPaymentApp].
  Future<bool> openPaymentApp({
    required String merchantCode,
    String? paymentMethodCode,
    Map<String, String> prefill = const {},
    Map<String, String> extra = const {},
  }) => launchUrl(
    Uri.parse(
      paymentAppUrl(merchantCode: merchantCode, paymentMethodCode: paymentMethodCode, prefill: prefill, extra: extra),
    ),
    mode: LaunchMode.externalApplication,
  );

  /// Banks and providers for [form]'s bank or provider field (null if they could not be loaded), and the merchant's
  /// name for the summary, which is a nicety: without it the summary leaves that row out.
  Future<(List<PaymentOperator>?, String?)> _sheetContext(MethodForm form) async {
    final needsOperators = form.fields.any(
      (field) => field.kind == FieldKind.paymentOperator || field.kind == FieldKind.provider,
    );
    final operators = needsOperators ? sheetOperators(form) : Future.value(const <PaymentOperator>[]);
    final merchant = _orNull(
      () async => jsonText(
        jsonMap(jsonMap(jsonDecode(await synqtCall(_synqt, 'GET', '/merchant-info', _token)))?['channelInfo'])?['name'],
      ),
    );
    return (await operators, await merchant);
  }
}

/// For the payment sheet only; not exported.
extension SheetPayin on Payin {
  /// SYNQT's banks and providers for [form], empty if it lists none, or null if they could not be loaded. A failed
  /// connection or a SYNQT server error is tried twice more, [retryAfter] apart; a refusal such as 403 is not.
  Future<List<PaymentOperator>?> sheetOperators(
    MethodForm form, {
    Duration retryAfter = const Duration(seconds: 2),
  }) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) await Future<void>.delayed(retryAfter);
      try {
        return (await availablePaymentOptions()).where((option) => option.code == form.code).firstOrNull?.operators ??
            const [];
      } on SynqtApiException catch (error) {
        if (error.httpCode < 500) return null;
      } on Exception {
        // unreachable or timed out: try again
      }
    }
    return null;
  }
}

/// For SYNQT add-ons only (`package:synqt/addon.dart`): calls for methods this SDK has no type for.
extension SynqtAddonPayin on Payin {
  /// [Payin.create] with a `paymentMethod` object an add-on built.
  Future<CreatePayinResult> createWithJson(Map<String, Object?> paymentMethod, {String? customerIp}) {
    final code = jsonText(paymentMethod['paymentMethodCode']);
    if (code == null) throw const SynqtArgumentException('paymentMethod needs a paymentMethodCode');
    return _create(paymentMethod, code, customerIp);
  }

  /// GET [path] with this payin's token, for add-ons that need more from SYNQT, such as the card encryption key.
  Future<Map<String, Object?>> get(String path) async =>
      jsonMap(jsonDecode(await synqtCall(_synqt, 'GET', path, _token))) ?? const {};
}

Future<T?> _orNull<T>(Future<T?> Function() block) async {
  try {
    return await block();
  } on Exception {
    return null;
  }
}

/// As Java's URLEncoder leaves them: letters, digits and `-._*`.
String _enc(String value) => [
  for (final byte in utf8.encode(value))
    RegExp(r'[A-Za-z0-9\-._*]').hasMatch(String.fromCharCode(byte)) && byte < 128
        ? String.fromCharCode(byte)
        : '%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}',
].join();

/// [Payin]'s constructor, for `Synqt.payin`. Not exported, so every payin goes through its ID check.
Payin newPayin(
  Synqt synqt, {
  required String token,
  required String id,
  required Money money,
  required String returnUrl,
  required String callbackUrl,
}) => Payin._(synqt, token: token, id: id, money: money, returnUrl: returnUrl, callbackUrl: callbackUrl);
