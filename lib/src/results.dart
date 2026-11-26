import 'dart:convert';

import 'addon.dart';
import 'method_forms.dart';
import 'payin_models.dart';
import 'payment_methods.dart';
import 'strings.dart';

/// R1,250.00 for rand, "USD 1,250.00" otherwise.
extension MoneyPaymentRequestedFormat on MoneyPaymentRequested {
  String format() => formatMoney(amountText(amount), currencyCode);
}

/// R1,250.00 for rand, "USD 1,250.00" otherwise; null without an amount.
extension MoneyResponseFormat on MoneyResponse {
  String? format() => switch (amount) {
    final amount? => formatMoney(amountText(amount), currencyCode ?? ''),
    null => null,
  };
}

/// A payment method the SDK's payment sheet supports: [code] for the API, [name] to show the payer.
final class DirectPaymentMethod {
  const DirectPaymentMethod(this.code);

  final String code;

  /// The payer-facing name, in the phone's language where the SDK has a translation.
  String get name => methodName(code)!;

  @override
  bool operator ==(Object other) => other is DirectPaymentMethod && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// The payer-facing name of this option's method in the phone's language, or null for methods the sheet does not
/// support.
extension AvailablePayinOptionName on AvailablePayinOption {
  String? get name => methodName(paymentMethodCode);
}

/// The payer-facing name of [code] in the phone's language, or null if the sheet does not support it.
String? methodName(String? code) => switch (methodForms.where((form) => form.code == code).firstOrNull) {
  final form? => text(form.name),
  null => addonMethods.where((method) => method.code == code).firstOrNull?.name,
};

/// What the payer does next, from whichever of these fields the method returned. On this phone, open [appLink]; from
/// another phone, scan the image at [qrCodeImageUrl] (a temporary link) or a QR code you draw from [qrCodeData]. Every
/// [PaymentMethodResponsePayin] gives one with `nextStep()`; `PayinCheckout.presentPaymentSheet` already shows it.
final class NextStep {
  const NextStep({
    this.appLink,
    this.qrCodeImageUrl,
    this.qrCodeData,
    this.amountToPay,
    this.reference,
    this.expiresAt,
    this.payInto,
  });

  final String? appLink;
  final String? qrCodeImageUrl;
  final String? qrCodeData;

  /// If set, the payer must pay exactly this instead of the requested amount.
  final MoneyResponse? amountToPay;
  final String? reference;

  /// ISO 8601. After this the payment fails and SYNQT sends a callback.
  final String? expiresAt;

  /// For OFFLINE: the account the payer transfers to from their own banking app, quoting [reference].
  final AccountResponse? payInto;
}

/// The next step and redirect of a payin SYNQT accepted.
extension PayinAcceptedResponseSteps on PayinAcceptedResponse {
  /// The next step of a payin SYNQT accepted with instructions, or null when it sent a redirect instead.
  NextStep? nextStep() => switch (this) {
    PayinAcceptedMethodResponse(:final paymentMethodResponse) => paymentMethodResponse?.nextStep(),
    PayinAcceptedRedirectResponse() => null,
  };

  /// Where to send the payer, if anywhere: SYNQT's `redirectTo`, or a card's 3-D Secure page (CARD comes from the card
  /// add-on). GET: open [Redirection.url]. POST: submit a form to it with `formData()`'s fields (in a web view).
  Redirection? redirect() => switch (this) {
    PayinAcceptedRedirectResponse(:final redirectTo) => redirectTo,
    // FORM, CONTENT and OTP_REQUIRED stay on the method response for the app to show.
    PayinAcceptedMethodResponse(
      paymentMethodResponse: CardMethodResponse(userInteraction: RedirectInteraction(url: final url?)),
    ) =>
      Redirection(method: 'GET', url: url),
    PayinAcceptedMethodResponse() => null,
  };
}

/// The fields to POST to [Redirection.url]: SYNQT sends them as a JSON string in `data`.
extension RedirectionFormData on Redirection {
  Map<String, String> formData() {
    final form = switch (data) {
      final data? => jsonMap(_decode(data)),
      null => null,
    };
    return {for (final entry in (form ?? const {}).entries) entry.key: jsonText(entry.value) ?? ''};
  }
}

/// SYNQT's payment statuses, as found in `PayinDetail.process.status`. New ones may come; treat an unknown status like
/// [processing].
abstract final class PaymentStatus {
  static const processing = 'PROCESSING';
  static const success = 'SUCCESS';
  static const failed = 'FAILED';
  static const refused = 'REFUSED';
}

extension PayinDetailIsFinal on PayinDetail {
  /// SUCCESS, FAILED and REFUSED, which do not change again. For display only: fulfil orders from your backend's own
  /// check.
  bool get isFinal =>
      const {PaymentStatus.success, PaymentStatus.failed, PaymentStatus.refused}.contains(process?.status);
}

extension FailureReasonsPayerMessage on FailureReasons {
  /// What to tell the payer, in the phone's language where the SDK has a translation. [FailureReasons.message] is
  /// SYNQT's own, written for the merchant.
  String get payerMessage => text(payerMessageKey(failureReasonCode) ?? 'synqt_failure_general');
}

/// Payer-facing wording (a string key) for SYNQT codes whose own description is meant for the merchant.
String? payerMessageKey(String? code) => failureMessages[code];

/// One reason SYNQT refused a request. [field] names the input it is about (SYNQT's attrCode), if any.
final class SynqtErrorReason {
  const SynqtErrorReason({required this.code, this.field, this.description});

  final String code;
  final String? field;
  final String? description;

  @override
  bool operator ==(Object other) =>
      other is SynqtErrorReason && other.code == code && other.field == field && other.description == description;

  @override
  int get hashCode => Object.hash(code, field, description);
}

/// SYNQT refused a request. [errors] holds its reasons (for 406, the business errors such as INVALID_PHONE_NUMBER).
/// The raw response is not kept: SYNQT echoes what the payer typed in it, which must not reach logs.
final class SynqtApiException implements Exception {
  const SynqtApiException(this.httpCode, [this.errors = const []]);

  final int httpCode;
  final List<SynqtErrorReason> errors;

  @override
  String toString() =>
      'SYNQT HTTP $httpCode${errors.isEmpty ? '' : ': ${errors.map((reason) => reason.code + (reason.field == null ? '' : ' (${reason.field})')).join(', ')}'}';
}

/// The app passed something the SDK cannot send: a malformed payin ID, an unknown method code, or a payment method
/// missing a field it needs ([path] names it when it is a form field).
final class SynqtArgumentException implements Exception {
  const SynqtArgumentException(this.message, {this.path});

  final String message;
  final String? path;

  @override
  String toString() => message;
}

// Loose JSON reading, as the other SDKs do: a missing, null or empty value reads as null rather than failing.

/// The value as text, or null when it is missing, null, empty or not a scalar.
String? jsonText(Object? value) => switch (value) {
  final String text => text.isEmpty ? null : text,
  final num number => '$number',
  final bool flag => '$flag',
  _ => null,
};

Map<String, Object?>? jsonMap(Object? value) => value is Map<String, Object?> ? value : null;

Object? _decode(String body) {
  try {
    return jsonDecode(body);
  } on FormatException {
    return null;
  }
}

/// SYNQT error bodies, as a list or a single object. attrValue is dropped on purpose.
List<SynqtErrorReason> parseErrors(String body) {
  final json = _decode(body);
  final items = json is List ? json.whereType<Map<String, Object?>>().toList() : [?jsonMap(json)];
  return [
    for (final item in items)
      if (jsonText(item['code']) case final code?)
        SynqtErrorReason(code: code, field: jsonText(item['attrCode']), description: jsonText(item['description'])),
  ];
}

/// After a 409, the payin [existing] must be the same payment being retried, not an earlier attempt with another method.
void requireSameMethod(String existing, String requested) {
  final used = jsonText(jsonMap(jsonMap(_decode(existing))?['paymentMethodResponse'])?['paymentMethodCode']);
  if (used == null || used == requested) return;
  // The description is for developers; the sheet shows its own translatable message for this code.
  throw SynqtApiException(409, [
    SynqtErrorReason(
      code: 'PAYIN_ALREADY_STARTED',
      description: 'This payin was already started with $used. Start a new payin to pay another way.',
    ),
  ]);
}

// Every deep link field in the spec; a method returns at most one.
const _appLinkFields = ['deepLink', 'zapperQrDeepLink', 'snapscanQrDeepLink', 'upiQrDeepLink', 'payMeDeepLink'];

/// The next step of a method this SDK version doesn't know, from the field names every method uses. No payInto: only
/// OFFLINE's account is one to pay into, and OFFLINE is never unknown.
NextStep parseNextStep(Map<String, Object?> json) {
  MoneyResponse? amountToPay;
  if (jsonMap(json['moneyRequired']) case final money?) {
    try {
      amountToPay = MoneyResponse.fromJson(money);
    } on TypeError {
      amountToPay = null; // a field of the wrong type: no amount to show rather than a failed payin
    }
  }
  return NextStep(
    appLink: _appLinkFields.map((key) => jsonText(json[key])).nonNulls.firstOrNull,
    qrCodeImageUrl: jsonText(json['qrCode']),
    qrCodeData: jsonText(json['qrRawData']),
    amountToPay: amountToPay,
    reference: jsonText(json['reference']),
    expiresAt: jsonText(json['expireAt']),
  );
}

/// [amount] as decimal text without trailing zeros, such as `12.3` for 12.30, as the Payment Web App link takes it.
String amountText(num amount) {
  final text = amount.toString();
  return text.contains('.') && !text.contains('e') ? text.replaceFirst(RegExp(r'\.?0+$'), '') : text;
}

/// Rand as R1,250.00 (the synqt-output-format convention); other currencies as "USD 1,250.00". Keeps extra decimals
/// the amount really has, so nothing is rounded away.
String formatMoney(String amount, String currencyCode) {
  final negative = amount.startsWith('-');
  final digits = negative ? amount.substring(1) : amount;
  final parts = (digits.contains('.') ? digits.replaceFirst(RegExp(r'\.?0+$'), '') : digits).split('.');
  final whole = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',');
  final fraction = (parts.length > 1 ? parts[1] : '').padRight(2, '0');
  final text = '${negative ? '-' : ''}$whole.$fraction';
  return currencyCode == 'ZAR' ? 'R$text' : '$currencyCode $text';
}
