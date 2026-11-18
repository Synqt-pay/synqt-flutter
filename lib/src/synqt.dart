import 'dart:convert';

import 'package:http/http.dart' as http;

import 'addon.dart';
import 'method_forms.dart';
import 'payin.dart';
import 'results.dart';

/// Where each SYNQT environment lives. The base URLs are public for backend calls such as minting tokens.
enum SynqtEnvironment {
  sandbox('https://api.sandbox.synqt.io', 'https://payment.sandbox.synqt.io/'),

  /// SYNQT internal development platform, as in the WordPress plugin. Not for merchants.
  stable('https://api.stable.aopay.io', 'https://payment.stable.aopay.io/'),
  live('https://api.synqt.io', 'https://payment.synqt.io/');

  const SynqtEnvironment(this.apiBaseUrl, this.paymentAppBaseUrl);

  final String apiBaseUrl;
  final String paymentAppBaseUrl;
}

final _payinId = RegExp(r'^[A-Za-z0-9_-]+$');

/// Entry point of the SYNQT payins SDK. Create one per environment, then one [Payin] per order:
///
/// ```dart
/// final payin = Synqt(SynqtEnvironment.sandbox).payin(token: token, payinId: payinId,
///     money: Money(amount: '100.00', currencyCode: 'ZAR'), returnUrl: returnUrl, callbackUrl: callbackUrl);
/// final result = await payin.presentPaymentSheet(context, paymentMethodCode: 'CAPITEC_PAY');
/// ```
///
/// The token is minted per order by YOUR backend (POST /auth-tokens-by-action, action PAYIN_CREATE, with `money` set).
/// The merchant private key and Secret key must never ship in the app. A payment is only paid when your backend's own
/// GET /payins/{id} says SUCCESS; nothing the app sees is proof.
final class Synqt {
  /// Pass your own [client] to control timeouts, proxies or certificate pinning.
  Synqt(this.environment, {http.Client? client}) : _client = client ?? http.Client();

  final SynqtEnvironment environment;
  final http.Client _client;

  /// Methods `Payin.presentPaymentSheet` can collect details for. Offer only those `Payin.availablePaymentOptions`
  /// also returns.
  static List<DirectPaymentMethod> get directPaymentMethods => [
    for (final form in methodForms) DirectPaymentMethod(form.code),
    for (final method in addonMethods) DirectPaymentMethod(method.code),
  ];

  /// One order's payin. [payinId] is your own ID for it (letters, digits, `_` and `-`, at most 250) and must match the
  /// token. [returnUrl] must be https: the Payment Web App rejects other schemes. Throws [SynqtArgumentException] for
  /// a malformed ID or a [returnUrl] that is not https.
  Payin payin({
    required String token,
    required String payinId,
    required Money money,
    required String returnUrl,
    required String callbackUrl,
  }) {
    if (payinId.length > 250 || !_payinId.hasMatch(payinId)) {
      throw const SynqtArgumentException(r'payinId must match ^[A-Za-z0-9_-]+$, max 250');
    }
    if (Uri.tryParse(returnUrl)?.scheme != 'https') throw const SynqtArgumentException('returnUrl must be https');
    return newPayin(this, token: token, id: payinId, money: money, returnUrl: returnUrl, callbackUrl: callbackUrl);
  }

  /// Every bank and provider SYNQT knows, with the providers behind each. SYNQT may add codes at any time, so treat
  /// unknown ones as normal. For what this merchant can use on a payin, use `Payin.availablePaymentOptions` instead.
  ///
  /// [token] must allow `GET /payment-operators`. PAYIN_CREATE tokens do not, so mint one on your backend with
  /// `POST /auth-tokens` and that operation.
  Future<List<PaymentOperator>> paymentOperators({required String token}) async =>
      parseOperators(jsonMap(jsonDecode(await _call('GET', '/payment-operators', token)))?['data']);

  /// One API call; the response body as text. Throws [SynqtApiException] when SYNQT refuses it.
  Future<String> _call(String method, String path, String token, [Object? body]) async {
    final request = http.Request(method, Uri.parse(environment.apiBaseUrl + path))
      ..headers.addAll({
        'Accept': 'application/json',
        'X-API-Version': '2', // a missing header gives 404, not 400
        'Authorization': 'Bearer $token',
      });
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final response = await http.Response.fromStream(await _client.send(request).timeout(const Duration(seconds: 30)));
    // SYNQT does not always name a charset, and http would then read the body as Latin-1.
    final text = utf8.decode(response.bodyBytes, allowMalformed: true);
    // The body is parsed into codes here and then dropped: 406 attrValue echoes what the payer typed.
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw SynqtApiException(response.statusCode, parseErrors(text));
    }
    return text;
  }
}

/// [Synqt]'s one API call, for [Payin]. Not exported: it returns raw bodies, which can hold what the payer typed.
Future<String> synqtCall(Synqt synqt, String method, String path, String token, [Object? body]) =>
    synqt._call(method, path, token, body);
