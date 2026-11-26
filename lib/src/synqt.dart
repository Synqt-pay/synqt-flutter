import 'dart:convert';

import 'package:http/http.dart' as http;

import 'addon.dart';
import 'incoming_payments_api.dart';
import 'method_forms.dart';
import 'payin_checkout.dart';
import 'payin_models.dart';
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

/// Entry point of the SYNQT payins SDK. Create one per environment. For the ready-made payment sheet or Payment Web
/// App, make one [PayinCheckout] per order:
///
/// ```dart
/// final checkout = Synqt(SynqtEnvironment.sandbox).checkout(token: token, payinId: payinId,
///     money: MoneyPaymentRequested(amount: 100, currencyCode: 'ZAR'), returnUrl: returnUrl, callbackUrl: callbackUrl);
/// final accepted = await checkout.presentPaymentSheet(context, paymentMethodCode: 'CAPITEC_PAY');
/// ```
///
/// To call the API yourself, as with the Carpentum Java SDK, use [IncomingPaymentsApi.create].
///
/// The token is minted per order by YOUR backend (POST /auth-tokens-by-action, action PAYIN_CREATE, with `money` set).
/// The merchant private key and Secret key must never ship in the app. A payment is only paid when your backend's own
/// GET /payins/{id} says SUCCESS; nothing the app sees is proof.
final class Synqt {
  /// Pass your own [client] to control timeouts, proxies or certificate pinning.
  Synqt(this.environment, {http.Client? client}) : _client = client ?? http.Client();

  final SynqtEnvironment environment;
  final http.Client _client;

  /// Methods `PayinCheckout.presentPaymentSheet` can collect details for. Offer only those
  /// `IncomingPaymentsApi.payinAvailablePaymentOptions` also returns.
  static List<DirectPaymentMethod> get directPaymentMethods => [
    for (final form in methodForms) DirectPaymentMethod(form.code),
    for (final method in addonMethods) DirectPaymentMethod(method.code),
  ];

  /// One order's payin for the payment sheet or Payment Web App. [payinId] is your own ID for it (letters, digits, `_`
  /// and `-`, at most 250) and must match the token. [returnUrl] must be https: the Payment Web App rejects other
  /// schemes. [callbackUrl] is where SYNQT sends your backend the final status. Throws [SynqtArgumentException] for a
  /// malformed ID or a [returnUrl] that is not https.
  PayinCheckout checkout({
    required String token,
    required String payinId,
    required MoneyPaymentRequested money,
    required String returnUrl,
    String? callbackUrl,
  }) {
    requirePayinId(payinId);
    requireHttps(returnUrl);
    return newPayinCheckout(
      this,
      token: token,
      id: payinId,
      money: money,
      returnUrl: returnUrl,
      callbackUrl: callbackUrl,
    );
  }

  /// Every bank and provider SYNQT knows, with the providers behind each. SYNQT may add codes at any time, so treat
  /// unknown ones as normal. For what this merchant can use on a payin, use
  /// `IncomingPaymentsApi.payinAvailablePaymentOptions` instead.
  ///
  /// [token] must allow `GET /payment-operators`. PAYIN_CREATE tokens do not, so mint one on your backend with
  /// `POST /auth-tokens` and that operation.
  Future<List<PaymentOperatorIncoming>> paymentOperators({required String token}) async {
    final data = jsonMap(jsonDecode(await _call('GET', '/payment-operators', token)))?['data'];
    return [if (data is List) ...data.whereType<Map<String, Object?>>().map(PaymentOperatorIncoming.fromJson)];
  }

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

/// [Synqt]'s one API call, for [IncomingPaymentsApi] and [PayinCheckout]. Not exported: it returns raw bodies, which can hold what the payer typed.
Future<String> synqtCall(Synqt synqt, String method, String path, String token, [Object? body]) =>
    synqt._call(method, path, token, body);
