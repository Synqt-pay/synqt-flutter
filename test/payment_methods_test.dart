import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:synqt/src/payin_models.dart';
import 'package:synqt/src/payment_methods.dart';
import 'package:synqt/src/payment_sheet_model.dart';
import 'package:synqt/src/results.dart';

PaymentMethodResponsePayin decode(String text) =>
    PaymentMethodResponsePayin.fromJson(jsonDecode(text) as Map<String, Object?>);

PayinAcceptedMethodResponse accepted(String text) =>
    PayinAcceptedResponse.fromJson(jsonDecode(text) as Map<String, Object?>) as PayinAcceptedMethodResponse;

void main() {
  test('request writes code and only set fields', () {
    final json = const CapitecPayMethod(
      phoneNumber: '0821234567',
      customerName: PersonName(firstName: 'Jane', lastName: 'Doe'),
    ).toJson();
    expect(json['paymentMethodCode'], 'CAPITEC_PAY');
    expect(json['phoneNumber'], '0821234567');
    expect((json['customerName'] as Map)['lastName'], 'Doe');
    expect(json.containsKey('said'), isFalse);
    expect((json['customerName'] as Map).containsKey('middleName'), isFalse);
  });

  test('methods with no fields still send their code', () {
    expect(const MomoPayMethod().toJson(), {'paymentMethodCode': 'MOMOPAY'});
  });

  test('shared account is checked against each method\'s own fields', () {
    expect(
      () => validatePaymentMethod(
        const PseMethod(account: Account(), emailAddress: 'a@b.co', phoneNumber: '+27821234567'),
      ),
      throwsA(
        isA<SynqtArgumentException>().having(
          (error) => error.message,
          'message',
          'PseMethod needs account.accountName',
        ),
      ),
    );
    expect(
      () => validatePaymentMethod(
        const PseMethod(
          account: Account(accountName: 'A Payer', accountNumber: '1'),
          emailAddress: 'a@b.co',
          phoneNumber: '+27821234567',
        ),
      ),
      throwsA(
        isA<SynqtArgumentException>().having(
          (error) => error.message,
          'message',
          'PseMethod does not take account.accountNumber',
        ),
      ),
    );
    // The same type serves a method that needs only the number.
    const capitec = CapitecPayMethod(
      account: Account(accountNumber: '123'),
      phoneNumber: '0821234567',
    );
    expect(() => validatePaymentMethod(capitec), returnsNormally);
    expect(capitec.toJson()['account'], {'accountNumber': '123'});
  });

  test('response accounts share one type', () {
    final absa =
        decode('{"paymentMethodCode":"ABSA_PAY","accountCustomer":{"accountName":"A","accountNumber":"1"}}')
            as AbsaPayMethodResponse;
    final pse = decode('{"paymentMethodCode":"PSE","accountCustomer":{"accountName":"B"}}') as PseMethodResponse;
    expect(absa.accountCustomer?.accountNumber, '1');
    expect(pse.accountCustomer?.accountName, 'B');
    expect(pse.accountCustomer?.accountNumber, isNull);
  });

  test('card request has no raw card field', () {
    final json = const CardMethod(
      card: CardData(cardDataVault: CardDataVault(vaultToken: 'vt_1')),
    ).toJson();
    expect(((json['card'] as Map)['cardDataVault'] as Map)['vaultToken'], 'vt_1');
    expect((json['card'] as Map).containsKey('cardDataRaw'), isFalse);
  });

  test('parses a known response with its amounts', () {
    final response =
        decode(
              '{"paymentMethodCode":"CAPITEC_PAY","idPayin":"o-1","reference":"REF1","money":{"amount":100.10,"currencyCode":"ZAR"}}',
            )
            as CapitecPayMethodResponse;
    expect(response.reference, 'REF1');
    expect(response.money?.amount, 100.1);
    expect(response.phoneNumber, isNull);
  });

  test('a retry must be the same method as the existing payin', () {
    const existing = '{"paymentMethodResponse":{"paymentMethodCode":"CAPITEC_PAY"}}';
    requireSameMethod(existing, 'CAPITEC_PAY'); // a real retry passes
    requireSameMethod(
      '{"redirectTo":{"method":"GET","url":"https://example.com"}}',
      'FNB_DIRECT_EFT',
    ); // nothing to compare
    try {
      requireSameMethod(existing, 'FNB_DIRECT_EFT');
      fail('expected a 409');
    } on SynqtApiException catch (error) {
      expect(error.httpCode, 409);
      expect(
        error.errors[0].description,
        'This payin was already started with CAPITEC_PAY. Start a new payin to pay another way.',
      );
      expect(payinErrors(error).map((payinError) => payinError.text), [
        'This payment was already started with another payment method. Start a new payment to pay another way.',
      ]);
    }
  });

  test('Zapper instructions carry the next step', () {
    final result = accepted('''
      {"paymentMethodResponse":{"paymentMethodCode":"ZAPPER_QR","qrCode":"https://example.com/qr.png",
         "qrRawData":"https://example.com/pay?qr=1","zapperQrDeepLink":"https://example.com/pay?qr=1","reference":"",
         "expireAt":"2026-10-27T15:15:49.725253752Z"}}''');
    expect(result.paymentMethodResponse, isA<ZapperQrMethodResponse>());
    final next = result.nextStep()!;
    expect(next.appLink, 'https://example.com/pay?qr=1');
    expect(next.qrCodeImageUrl, 'https://example.com/qr.png');
    expect(next.qrCodeData, 'https://example.com/pay?qr=1');
    expect(next.expiresAt, '2026-10-27T15:15:49.725253752Z');
    expect(next.reference, isNull); // the empty reference is left out
    expect(next.payInto, isNull);
  });

  test('offline instructions carry the account to pay into', () {
    final next = accepted('''
      {"paymentMethodResponse":{"paymentMethodCode":"OFFLINE","reference":"REF123",
         "account":{"accountName":"Test Payee","accountNumber":"0000000000","bankName":"Test Bank","bankCode":"000000"},
         "accountCustomer":{"accountName":"Test Payer"}}}''').nextStep()!;
    expect(next.payInto?.accountName, 'Test Payee');
    expect(next.payInto?.bankCode, '000000');
    expect(next.reference, 'REF123');
    // Other methods' `account` is not shown as somewhere to pay.
    final other = accepted(
      '{"paymentMethodResponse":{"paymentMethodCode":"PAYSHAP","account":{"accountNumber":"0000000000"}}}',
    );
    expect(other.nextStep()?.payInto, isNull);
  });

  test('app links fall back to the app\'s own scheme', () {
    expect(appLinks('https://pos.snapscan.io/qr/abc?id=1', 'snapscan'), [
      'https://pos.snapscan.io/qr/abc?id=1',
      'snapscan://pos.snapscan.io/qr/abc?id=1',
    ]);
    expect(appLinks('https://www.zapper.com/payWithZapper?qr=1', null), ['https://www.zapper.com/payWithZapper?qr=1']);
  });

  test('time left counts down to the expiry', () {
    final now = DateTime.parse('2026-10-27T13:16:32Z');
    expect(timeLeft('2026-10-27T15:15:49.725253752Z', now), '01:59:17');
    expect(timeLeft('2026-10-27T13:00:00Z', now), '');
    expect(timeLeft('not a time', now), isNull);
  });

  test('failure reasons have a payer message', () {
    expect(
      const FailureReasons(failureReasonCode: 'PAYMENT_PROCESS_ERROR').payerMessage,
      startsWith('Something went wrong while processing your payment.'),
    );
    expect(
      const FailureReasons(failureReasonCode: 'NEW_CODE').payerMessage,
      'Your payment could not be completed. Please try again, or choose another payment method.',
    );
  });

  test('an unknown or malformed method does not throw', () {
    final unknown = decode(
      '{"paymentMethodCode":"NEW_METHOD","x":1,"deepLink":"https://example.com/pay","reference":""}',
    );
    expect(unknown, isA<UnknownPaymentMethodResponsePayin>());
    expect((unknown as UnknownPaymentMethodResponsePayin).paymentMethodCode, 'NEW_METHOD');
    expect(unknown.json['x'], 1); // kept as SYNQT sent it
    expect(unknown.nextStep().appLink, 'https://example.com/pay');
    expect(unknown.nextStep().reference, isNull);
    // A known method whose fields have unexpected types must not turn a created payin into an error.
    final result = accepted(
      '{"paymentMethodResponse":{"paymentMethodCode":"PAYSHAP","reference":"R9","money":"oops"}}',
    );
    expect(result.paymentMethodResponse, isA<UnknownPaymentMethodResponsePayin>());
    expect((result.paymentMethodResponse as UnknownPaymentMethodResponsePayin).paymentMethodCode, 'PAYSHAP');
    expect(result.nextStep()?.reference, 'R9');
    // CODE_PAYMENT's paymentLocationCustomer needs all three fields.
    expect(
      decode('{"paymentMethodCode":"CODE_PAYMENT","paymentLocationCustomer":{"city":"X"}}'),
      isA<UnknownPaymentMethodResponsePayin>(),
    );
    expect(SettlementMethod.fromJson(const {'paymentMethodCode': 'NEW_SETTLEMENT'}), isA<UnknownSettlementMethod>());
  });

  test('instructions expose the typed method', () {
    final result = accepted('{"paymentMethodResponse":{"paymentMethodCode":"PAYSHAP","reference":"R9"}}');
    expect((result.paymentMethodResponse as PayShapMethodResponse).reference, 'R9');
  });
}
