import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'addon.dart';
import 'incoming_payments_api.dart';
import 'method_form.dart';
import 'method_forms.dart';
import 'payin_models.dart';
import 'payment_app.dart';
import 'payment_methods.dart';
import 'payment_sheet.dart';
import 'results.dart';
import 'synqt.dart';

/// One order's payin for the ready-made screens, from `Synqt.checkout`: the payment sheet and SYNQT's hosted Payment
/// Web App. To call the API yourself, use [IncomingPaymentsApi]. Calls throw [SynqtApiException] when SYNQT refuses
/// them, and `http.ClientException` or a `TimeoutException` when it cannot be reached.
final class PayinCheckout {
  PayinCheckout._(
    Synqt synqt, {
    required String token,
    required this.id,
    required this.money,
    required this.returnUrl,
    required this.callbackUrl,
  }) : _synqt = synqt,
       _token = token,
       _api = IncomingPaymentsApi.create(synqt, token);

  final Synqt _synqt;
  final String _token;
  final IncomingPaymentsApi _api;
  final String id;
  final MoneyPaymentRequested money;
  final String returnUrl;
  final String? callbackUrl;

  /// What the sheet sends: this checkout's payin with the payer's [paymentMethod].
  Future<PayinAcceptedResponse> _createPayin(PaymentMethodPayin paymentMethod, String? customerIp) => _api.createPayin(
    id,
    Payin(
      paymentRequested: PaymentRequested(money: money),
      paymentMethod: paymentMethod,
      returnUrl: returnUrl,
      callbackUrl: callbackUrl,
      customerIp: customerIp,
    ),
  );

  /// Link to SYNQT's hosted Payment Web App for this payin. [paymentMethodCode] opens it on that method (one
  /// [IncomingPaymentsApi.payinAvailablePaymentOptions] returns) while still letting the payer pick another. [prefill] takes the Payment Web
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
      ('amount', amountText(money.amount)),
      ('currencyCode', money.currencyCode),
      if (callbackUrl case final callbackUrl?) ('callbackUrl', callbackUrl),
      ('returnUrl', returnUrl),
      if (paymentMethodCode != null) ...[('paymentMethodCode', paymentMethodCode), ('optionsAvailable', 'true')],
      for (final entry in prefill.entries) (entry.key, entry.value),
      if (prefill.isNotEmpty) ('allowCustomerDataChange', 'true'),
      for (final entry in extra.entries) (entry.key, entry.value),
    ];
    return '${_synqt.environment.paymentAppBaseUrl}?${params.map((param) => '${_enc(param.$1)}=${_enc(param.$2)}').join('&')}';
  }

  /// Collects the payer's details for [paymentMethodCode] (one of `Synqt.directPaymentMethods`) in a Synqt-branded
  /// bottom sheet over [context], then creates the payin with [IncomingPaymentsApi.createPayin] and returns what SYNQT
  /// accepted. Errors, including SYNQT's field errors, stay in the sheet so the payer can correct them. Returns null if
  /// the payer closes it.
  ///
  /// The bank or provider field lists the banks [IncomingPaymentsApi.payinAvailablePaymentOptions] returns for this
  /// payin and
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
  Future<PayinAcceptedResponse?> presentPaymentSheet(
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
      amount: money.format(),
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
      submit: (method) => _createPayin(method, customerIp),
    )..onPaymentStarted = onPaymentStarted ?? () {};
    model.reloadOperators = () => sheetOperators(form);
    return showPaymentSheet(context, model, onPresented: onPresented);
  }

  /// Shows SYNQT's hosted Payment Web App full screen over [context], and completes once the payer reaches
  /// [returnUrl] or closes it. [onPresented] runs once it is on screen. Links to other apps (bank apps, UPI) open
  /// outside it. [paymentMethodCode], [prefill] and [extra] are as for [paymentAppUrl]. Either way, ask
  /// [IncomingPaymentsApi.getPayin] where the payment stands.
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
  Future<(List<PaymentOperatorIncoming>?, String?)> _sheetContext(MethodForm form) async {
    final needsOperators = form.fields.any(
      (field) => field.kind == FieldKind.paymentOperator || field.kind == FieldKind.provider,
    );
    final operators = needsOperators ? sheetOperators(form) : Future.value(const <PaymentOperatorIncoming>[]);
    final merchant = _orNull(
      () async => jsonText(
        jsonMap(jsonMap(jsonDecode(await synqtCall(_synqt, 'GET', '/merchant-info', _token)))?['channelInfo'])?['name'],
      ),
    );
    return (await operators, await merchant);
  }
}

/// For the payment sheet only; not exported.
extension SheetCheckout on PayinCheckout {
  /// SYNQT's banks and providers for [form], empty if it lists none, or null if they could not be loaded. A failed
  /// connection or a SYNQT server error is tried twice more, [retryAfter] apart; a refusal such as 403 is not.
  Future<List<PaymentOperatorIncoming>?> sheetOperators(
    MethodForm form, {
    Duration retryAfter = const Duration(seconds: 2),
  }) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) await Future<void>.delayed(retryAfter);
      try {
        final options = await _api.payinAvailablePaymentOptions(PaymentRequested(money: money));
        return (options.data ?? const [])
                .where((option) => option.paymentMethodCode == form.code)
                .firstOrNull
                ?.paymentOperators ??
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

/// For SYNQT add-ons only (`package:synqt/addon.dart`).
extension SynqtAddonCheckout on PayinCheckout {
  /// The API for this checkout's token, for add-ons that need more from SYNQT.
  IncomingPaymentsApi get api => _api;
}

Future<T?> _orNull<T>(Future<T?> Function() block) async {
  try {
    return await block();
  } on Exception {
    return null;
  }
}

/// As Java's URLEncoder leaves them, so the link matches the Android and iOS SDKs': letters, digits and `-._*`.
String _enc(String value) => [
  for (final byte in utf8.encode(value))
    RegExp(r'[A-Za-z0-9\-._*]').hasMatch(String.fromCharCode(byte)) && byte < 128
        ? String.fromCharCode(byte)
        : '%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}',
].join();

/// [PayinCheckout]'s constructor, for `Synqt.checkout`. Not exported, so every checkout goes through its ID check.
PayinCheckout newPayinCheckout(
  Synqt synqt, {
  required String token,
  required String id,
  required MoneyPaymentRequested money,
  required String returnUrl,
  String? callbackUrl,
}) => PayinCheckout._(synqt, token: token, id: id, money: money, returnUrl: returnUrl, callbackUrl: callbackUrl);
