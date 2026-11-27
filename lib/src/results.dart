import 'dart:convert';

import 'addon.dart';
import 'method_forms.dart';
import 'payment_methods.dart';
import 'strings.dart';

final _decimal = RegExp(r'^-?\d+(\.\d+)?$');

/// An amount in major units (12.34, not 1234) and its ISO 4217 currency. IDR and INR take whole numbers only.
///
/// [amount] is decimal text such as `'1250.00'`, so it is never rounded through a double inside the app.
final class Money {
  Money({required this.amount, required this.currencyCode}) {
    if (!_decimal.hasMatch(amount)) {
      throw SynqtArgumentException('amount must be a decimal number such as 1250.00, not "$amount"');
    }
  }

  final String amount;
  final String currencyCode;

  /// The amount without trailing zeros, such as `12.3` for `12.30`, as written into links.
  String get plainAmount => _plain(amount);

  // shortcut: JSON numbers are written through a double, exact to 15 significant digits; send raw JSON if SYNQT ever takes longer amounts.
  Map<String, Object?> toJson() => {'amount': num.parse(amount), 'currencyCode': currencyCode};

  @override
  bool operator ==(Object other) =>
      other is Money && other.plainAmount == plainAmount && other.currencyCode == currencyCode;

  @override
  int get hashCode => Object.hash(plainAmount, currencyCode);

  /// R1,250.00 for rand, "USD 1,250.00" otherwise.
  @override
  String toString() => formatMoney(amount, currencyCode);
}

String _plain(String amount) => amount.contains('.') ? amount.replaceFirst(RegExp(r'\.?0+$'), '') : amount;

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

/// A method SYNQT offers this merchant, with the banks or providers to choose from.
final class PaymentOption {
  const PaymentOption({required this.code, this.operators = const [], this.segmentCode});

  final String code;
  final List<PaymentOperator> operators;
  final String? segmentCode;

  /// The payer-facing name in the phone's language, or null for methods the sheet does not support.
  String? get name => methodName(code);

  @override
  bool operator ==(Object other) =>
      other is PaymentOption &&
      other.code == code &&
      _listEq(other.operators, operators) &&
      other.segmentCode == segmentCode;

  @override
  int get hashCode => Object.hash(code, Object.hashAll(operators), segmentCode);

  @override
  String toString() =>
      'PaymentOption($code, ${operators.length} operators${segmentCode == null ? '' : ', $segmentCode'})';
}

/// The payer-facing name of [code] in the phone's language, or null if the sheet does not support it.
String? methodName(String code) => switch (methodForms.where((form) => form.code == code).firstOrNull) {
  final form? => text(form.name),
  null => addonMethods.where((method) => method.code == code).firstOrNull?.name,
};

/// A bank or provider: send [code], show [name]. [externalProviders] are the providers it routes through, where SYNQT
/// lists any.
final class PaymentOperator {
  const PaymentOperator({required this.code, required this.name, this.externalProviders = const []});

  final String code;
  final String name;
  final List<ExternalProvider> externalProviders;

  @override
  bool operator ==(Object other) =>
      other is PaymentOperator &&
      other.code == code &&
      other.name == name &&
      _listEq(other.externalProviders, externalProviders);

  @override
  int get hashCode => Object.hash(code, name, Object.hashAll(externalProviders));

  @override
  String toString() => 'PaymentOperator($code, $name)';
}

/// A provider behind a [PaymentOperator]: send [code] (for example as PayShap's `externalProviderCode`), show [name].
final class ExternalProvider {
  const ExternalProvider({required this.code, required this.name});

  final String code;
  final String name;

  @override
  bool operator ==(Object other) => other is ExternalProvider && other.code == code && other.name == name;

  @override
  int get hashCode => Object.hash(code, name);

  @override
  String toString() => 'ExternalProvider($code, $name)';
}

/// What happened when a payin was created. Not proof of payment: check `Payin.status()` (and your backend) for that.
sealed class CreatePayinResult {
  const CreatePayinResult();
}

/// Send the payer to [url]. GET: open it. POST: submit a form to it with one field per [formData] entry (in a web view).
final class RedirectResult extends CreatePayinResult {
  const RedirectResult({required this.httpMethod, required this.url, this.formData = const {}});

  final String httpMethod;
  final String url;
  final Map<String, String> formData;

  @override
  bool operator ==(Object other) =>
      other is RedirectResult &&
      other.httpMethod == httpMethod &&
      other.url == url &&
      jsonEncode(other.formData) == jsonEncode(formData);

  @override
  int get hashCode => Object.hash(httpMethod, url);

  @override
  String toString() => 'RedirectResult($httpMethod $url)';
}

/// Show these instructions yourself: QR code, deep link, account, reference, expiry, and moneyRequired if present (the
/// payer must pay exactly that amount, so show it prominently). [nextStep] gathers the common ones;
/// `Payin.presentPaymentSheet` already shows them.
final class InstructionsResult extends CreatePayinResult {
  const InstructionsResult({required this.paymentMethod, required this.nextStep});

  final PaymentMethodResponse paymentMethod;
  final NextStep nextStep;

  @override
  String toString() => 'InstructionsResult(${paymentMethod.paymentMethodCode})';
}

/// What the payer does next, from whichever of these fields the method returned. On this phone, open [appLink]; from
/// another phone, scan the image at [qrCodeImageUrl] (a temporary link) or a QR code you draw from [qrCodeData].
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
  final Money? amountToPay;
  final String? reference;

  /// ISO 8601. After this the payment fails and SYNQT sends a callback.
  final String? expiresAt;

  /// For OFFLINE: the account the payer transfers to from their own banking app, quoting [reference].
  final AccountResponse? payInto;
}

/// A payin's state, from `process.status`.
enum PayinState {
  processing('PROCESSING'),
  success('SUCCESS'),
  failed('FAILED'),
  refused('REFUSED'),

  /// A status this SDK version does not know yet. Treat it like processing.
  unknown('UNKNOWN');

  const PayinState(this.code);

  final String code;

  /// SUCCESS, FAILED and REFUSED do not change again.
  bool get isFinal => this == success || this == failed || this == refused;
}

/// A payin's state from GET /payins/{id}.
final class PayinStatus {
  const PayinStatus({
    required this.status,
    required this.requested,
    this.fee,
    this.isTest = false,
    this.failureReason,
    this.paymentMethod,
    this.createdAt,
    this.processedAt,
  });

  final PayinState status;

  /// Null only when SYNQT's response leaves it out.
  final Money? requested;
  final Money? fee;
  final bool isTest;
  final FailureReason? failureReason;
  final PaymentMethodResponse? paymentMethod;
  final String? createdAt;
  final String? processedAt;

  @override
  String toString() =>
      'PayinStatus(${status.code}, requested: $requested${failureReason == null ? '' : ', ${failureReason!.code}'})';
}

/// Why a payin failed or was refused. [code] is one of SYNQT's FailureReasonCode values, such as ENTITY_EXPIRED.
final class FailureReason {
  const FailureReason({required this.code, this.message, this.failedAt});

  final String code;

  /// SYNQT's own message, written for the merchant.
  final String? message;
  final String? failedAt;

  /// What to tell the payer, in the phone's language where the SDK has a translation.
  String get payerMessage => text(payerMessageKey(code) ?? 'synqt_failure_general');
}

/// Payer-facing wording (a string key) for SYNQT codes whose own description is meant for the merchant.
String? payerMessageKey(String code) => failureMessages[code];

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

/// The app passed something the SDK cannot send: a malformed payin ID or amount, an unknown method code, or a payment
/// method missing a field it needs ([path] names it when it is a form field).
final class SynqtArgumentException implements Exception {
  const SynqtArgumentException(this.message, {this.path});

  final String message;
  final String? path;

  @override
  String toString() => message;
}

// Loose JSON reading: a missing, null or empty value reads as null rather than failing.

/// The value as text, or null when it is missing, null, empty or not a scalar.
String? jsonText(Object? value) => switch (value) {
  final String text => text.isEmpty ? null : text,
  final num number => '$number',
  final bool flag => '$flag',
  _ => null,
};

Map<String, Object?>? jsonMap(Object? value) => value is Map<String, Object?> ? value : null;

/// The array's objects; anything else in it is skipped.
List<Map<String, Object?>> jsonObjects(Object? value) =>
    value is List ? value.whereType<Map<String, Object?>>().toList() : const [];

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
  final items = json is List ? jsonObjects(json) : [?jsonMap(json)];
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

CreatePayinResult parseCreatePayin(String body) {
  final json = jsonMap(jsonDecode(body)) ?? const {};
  final redirect = jsonMap(json['redirectTo']);
  final url = jsonText(redirect?['url']);
  if (redirect != null && url != null) {
    final form = switch (jsonText(redirect['data'])) {
      final data? => jsonMap(_decode(data)),
      null => null,
    };
    return RedirectResult(
      httpMethod: jsonText(redirect['method']) ?? 'GET',
      url: url,
      formData: {for (final entry in (form ?? const {}).entries) entry.key: jsonText(entry.value) ?? ''},
    );
  }
  final methodJson = jsonMap(json['paymentMethodResponse']) ?? const {};
  final method = parseMethodResponse(methodJson);
  // A card's 3-D Secure page (CARD comes from the card add-on); FORM, CONTENT and OTP_REQUIRED stay in instructions for
  // the app to show.
  if (method case CardResponse(userInteraction: RedirectInteraction(url: final url?))) {
    return RedirectResult(httpMethod: 'GET', url: url, formData: const {});
  }
  return InstructionsResult(paymentMethod: method, nextStep: parseNextStep(methodJson));
}

/// A response that does not fit its method's model (a field of an unexpected type) still reads as unknown, so a payin
/// SYNQT has created never surfaces as an error.
PaymentMethodResponse parseMethodResponse(Map<String, Object?> json) {
  try {
    return PaymentMethodResponse.fromJson(json);
  } catch (_) {
    // A TypeError from a field of the wrong type: the whole method reads as unknown.
    return UnknownPaymentMethodResponse(jsonText(json['paymentMethodCode']) ?? '');
  }
}

// Every deep link field in the spec; a method returns at most one.
const _appLinkFields = ['deepLink', 'zapperQrDeepLink', 'snapscanQrDeepLink', 'upiQrDeepLink', 'payMeDeepLink'];

NextStep parseNextStep(Map<String, Object?> json) {
  AccountResponse? payInto;
  // shortcut: OFFLINE only, as some methods' `account` is the payer's own; add others (such as VAPAY) once checked.
  if (jsonText(json['paymentMethodCode']) == 'OFFLINE' && jsonMap(json['account']) != null) {
    try {
      payInto = AccountResponse.fromJson(jsonMap(json['account'])!);
    } catch (_) {
      payInto = null; // a field of the wrong type: no account to show rather than a failed payin
    }
  }
  return NextStep(
    appLink: _appLinkFields.map((key) => jsonText(json[key])).nonNulls.firstOrNull,
    qrCodeImageUrl: jsonText(json['qrCode']),
    qrCodeData: jsonText(json['qrRawData']),
    amountToPay: parseMoney(json['moneyRequired']),
    reference: jsonText(json['reference']),
    expiresAt: jsonText(json['expireAt']),
    payInto: payInto,
  );
}

PayinStatus parsePayinStatus(Map<String, Object?> json) {
  final process = jsonMap(json['process']) ?? const {};
  final failure = jsonMap(process['failureReasons']);
  final code = jsonText(failure?['failureReasonCode']);
  final status = jsonText(process['status']);
  return PayinStatus(
    status:
        PayinState.values.where((state) => state.code == status && state != PayinState.unknown).firstOrNull ??
        PayinState.unknown,
    requested: parseMoney(jsonMap(json['paymentRequested'])?['money']),
    fee: parseMoney(json['fee']),
    isTest: process['isTest'] == true || jsonText(process['isTest']) == 'true',
    failureReason: code == null
        ? null
        : FailureReason(code: code, message: jsonText(failure?['message']), failedAt: jsonText(failure?['failedAt'])),
    paymentMethod: switch (jsonMap(json['paymentMethodResponse'])) {
      final methodJson? => parseMethodResponse(methodJson),
      null => null,
    },
    createdAt: jsonText(process['createdAt']),
    processedAt: jsonText(process['processedAt']),
  );
}

List<PaymentOption> parsePaymentOptions(Map<String, Object?> json) => [
  for (final option in jsonObjects(json['data']))
    if (jsonText(option['paymentMethodCode']) case final code?)
      PaymentOption(
        code: code,
        operators: parseOperators(option['paymentOperators']),
        segmentCode: jsonText(option['segmentCode']),
      ),
];

/// Operators from availablePaymentOptions or GET /payment-operators; entries without a code are skipped, a missing
/// name shows the code.
List<PaymentOperator> parseOperators(Object? json) => [
  for (final op in jsonObjects(json))
    if (jsonText(op['code']) case final code?)
      PaymentOperator(
        code: code,
        name: jsonText(op['name']) ?? code,
        externalProviders: [
          for (final provider in jsonObjects(jsonMap(op['externalProviders'])?['providers']))
            if (jsonText(provider['code']) case final pc?)
              ExternalProvider(code: pc, name: jsonText(provider['name']) ?? pc),
        ],
      ),
];

Money? parseMoney(Object? json) {
  final map = jsonMap(json);
  final amount = jsonText(map?['amount']);
  if (amount == null || !_decimal.hasMatch(amount)) return null;
  return Money(amount: amount, currencyCode: jsonText(map!['currencyCode']) ?? '');
}

/// Rand as R1,250.00; other currencies as "USD 1,250.00". Keeps extra decimals
/// the amount really has, so nothing is rounded away.
String formatMoney(String amount, String currencyCode) {
  final negative = amount.startsWith('-');
  final parts = _plain(negative ? amount.substring(1) : amount).split('.');
  final whole = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',');
  final fraction = (parts.length > 1 ? parts[1] : '').padRight(2, '0');
  final digits = '${negative ? '-' : ''}$whole.$fraction';
  return currencyCode == 'ZAR' ? 'R$digits' : '$currencyCode $digits';
}

bool _listEq<T>(List<T> first, List<T> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
