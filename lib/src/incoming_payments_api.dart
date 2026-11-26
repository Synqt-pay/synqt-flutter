import 'dart:convert';

import 'payin_models.dart';
import 'payment_methods.dart';
import 'results.dart';
import 'synqt.dart';

/// SYNQT's incoming payments (payin) API, as in the Carpentum Java SDK's `IncomingPaymentsApi`: one instance per token,
/// each call naming the payin it is about.
///
/// ```dart
/// final api = IncomingPaymentsApi.create(Synqt(SynqtEnvironment.sandbox), token);
/// final requested = PaymentRequested(money: MoneyPaymentRequested(amount: 100, currencyCode: 'ZAR'));
/// final accepted = await api.createPayin(
///   payinId,
///   Payin(paymentRequested: requested, paymentMethod: CapitecPayMethod(phoneNumber: '0821234567'), returnUrl: returnUrl),
/// );
/// ```
///
/// The token is minted by YOUR backend, which holds the merchant's private key (POST /auth-tokens-by-action with action
/// PAYIN_CREATE and `money` set allows every call here for that payin). Calls throw [SynqtApiException] when SYNQT
/// refuses them, and `http.ClientException` or a `TimeoutException` when it cannot be reached.
final class IncomingPaymentsApi {
  IncomingPaymentsApi._(this._synqt, this._token);

  /// An API for [accessToken], on [synqt]'s environment. As the Java SDK's `IncomingPaymentsApi.create(context, token)`.
  factory IncomingPaymentsApi.create(Synqt synqt, String accessToken) => IncomingPaymentsApi._(synqt, accessToken);

  final Synqt _synqt;
  final String _token;

  /// Methods, banks and providers SYNQT offers this merchant for [paymentRequested]. Send the same `segmentCode` when
  /// paying.
  Future<AvailablePayinOptionList> payinAvailablePaymentOptions(PaymentRequested paymentRequested) async =>
      AvailablePayinOptionList.fromJson(
        await _json('POST', '/payins/!availablePaymentOptions', paymentRequested.toJson()),
      );

  /// Creates payin [idPayin] (your own ID for the order: letters, digits, `_` and `-`, at most 250, matching the token).
  /// Not proof of payment: see [getPayin] and your backend's own check.
  ///
  /// The payment method is checked before sending, and [Payin.returnUrl] must be https. A retry after a network failure
  /// is safe: if SYNQT already accepted [idPayin], the existing payin is returned. If that payin was made with a
  /// different method, this throws [SynqtApiException] (409, PAYIN_ALREADY_STARTED): start a new payin to pay another
  /// way.
  ///
  /// Throws [SynqtArgumentException] before sending for a malformed [idPayin], a [Payin.returnUrl] that is not https,
  /// or a shared type such as [Account] that lacks a field this method needs or has one it does not take.
  Future<PayinAcceptedResponse> createPayin(String idPayin, Payin payin) async {
    requirePayinId(idPayin);
    requireHttps(payin.returnUrl);
    validatePaymentMethod(payin.paymentMethod);
    String data;
    try {
      data = await synqtCall(_synqt, 'POST', '/payins/$idPayin', _token, payin.toJson());
    } on SynqtApiException catch (error) {
      if (error.httpCode != 409) rethrow;
      // GET /payins/{id} carries paymentRequested and paymentMethodResponse, as the accepted response does.
      data = await synqtCall(_synqt, 'GET', '/payins/$idPayin', _token);
      requireSameMethod(data, payin.paymentMethod.paymentMethodCode);
    }
    return PayinAcceptedResponse.fromJson(jsonMap(jsonDecode(data)) ?? const {});
  }

  /// The payer's bank or UTR reference, for methods that need it. The token must allow
  /// `POST /payins/{id}/!setExternalReference`.
  Future<void> setPayinExternalReference(String idPayin, String reference) async {
    requirePayinId(idPayin);
    if (reference.isEmpty || reference.length > 512) {
      throw const SynqtArgumentException('reference must be 1 to 512 characters');
    }
    await synqtCall(_synqt, 'POST', '/payins/$idPayin/!setExternalReference', _token, {'reference': reference});
  }

  /// Payin [idPayin] as SYNQT has it now. For display only: fulfil orders from your backend's own check, never from
  /// this. Before a payment is sent, SYNQT answers HTTP 410.
  Future<PayinDetail> getPayin(String idPayin) async {
    requirePayinId(idPayin);
    return PayinDetail.fromJson(await _json('GET', '/payins/$idPayin'));
  }

  /// The payer's account as they entered it and as the payment used it. The token must allow
  /// `GET /payins/{id}/accounts`.
  Future<PaymentAccountDetail> getPayinAccounts(String idPayin) async {
    requirePayinId(idPayin);
    return PaymentAccountDetail.fromJson(await _json('GET', '/payins/$idPayin/accounts'));
  }

  Future<Map<String, Object?>> _json(String method, String path, [Object? body]) async =>
      jsonMap(jsonDecode(await synqtCall(_synqt, method, path, _token, body))) ?? const {};
}

/// For SYNQT add-ons only (`package:synqt/addon.dart`).
extension SynqtAddonApi on IncomingPaymentsApi {
  /// GET [path] with this token, for add-ons that need more from SYNQT, such as the card encryption key.
  Future<Map<String, Object?>> get(String path) => _json('GET', path);
}

final _payinId = RegExp(r'^[A-Za-z0-9_-]+$');

/// Throws [SynqtArgumentException] unless [id] is a valid payin ID.
void requirePayinId(String id) {
  if (id.length > 250 || !_payinId.hasMatch(id)) {
    throw const SynqtArgumentException(r'idPayin must match ^[A-Za-z0-9_-]+$, max 250');
  }
}

/// Throws [SynqtArgumentException] unless [returnUrl] is https: the Payment Web App rejects other schemes.
void requireHttps(String returnUrl) {
  if (Uri.tryParse(returnUrl)?.scheme != 'https') throw const SynqtArgumentException('returnUrl must be https');
}
