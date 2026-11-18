import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:synqt/src/method_forms.dart';
import 'package:synqt/src/payment_app.dart';
import 'package:synqt/src/payment_sheet_model.dart';
import 'package:synqt/src/method_form.dart';
import 'package:synqt/src/results.dart';
import 'package:synqt/src/strings.dart';
import 'package:synqt/src/ui/widgets.dart';
import 'package:synqt/synqt.dart';

Payin payin([String id = 'order-1', http.Client? client]) => Synqt(SynqtEnvironment.sandbox, client: client).payin(
  token: 'a.b+c',
  payinId: id,
  money: Money(amount: '12.30', currencyCode: 'ZAR'),
  returnUrl: 'https://x.io/return',
  callbackUrl: 'https://x.io/cb',
);

Map<String, Object?> json(String text) => jsonDecode(text) as Map<String, Object?>;

void main() {
  test('payment app url encodes params', () {
    expect(
      payin().paymentAppUrl(merchantCode: 'MID', extra: {'emailAddress': 'a@b.co'}),
      'https://payment.sandbox.synqt.io/?merchantCode=MID&idPayin=order-1&token=a.b%2Bc&amount=12.3'
      '&currencyCode=ZAR&callbackUrl=https%3A%2F%2Fx.io%2Fcb&returnUrl=https%3A%2F%2Fx.io%2Freturn&emailAddress=a%40b.co',
    );
  });

  test('payment app offers a method and editable prefill', () {
    final url = payin().paymentAppUrl(
      merchantCode: 'MID',
      paymentMethodCode: 'CAPITEC_PAY',
      prefill: {'phoneNumber': '+27821234567'},
    );
    expect(
      url,
      endsWith(
        '&paymentMethodCode=CAPITEC_PAY&optionsAvailable=true&phoneNumber=%2B27821234567&allowCustomerDataChange=true',
      ),
    );
    expect(payin().paymentAppUrl(merchantCode: 'MID'), isNot(contains('optionsAvailable')));
  });

  test('rejects an unsafe payin ID and a malformed amount', () {
    expect(() => payin('../x'), throwsA(isA<SynqtArgumentException>()));
    expect(() => Money(amount: '12,30', currencyCode: 'ZAR'), throwsA(isA<SynqtArgumentException>()));
  });

  test('parses a redirect', () {
    expect(
      parseCreatePayin(r'{"redirectTo":{"method":"POST","url":"https://p.io","data":"{\"k\":\"v\",\"n\":1}"}}'),
      const RedirectResult(httpMethod: 'POST', url: 'https://p.io', formData: {'k': 'v', 'n': '1'}),
    );
  });

  test('parses status', () {
    final status = parsePayinStatus(
      json('''
      {"paymentRequested":{"money":{"amount":100.50,"currencyCode":"ZAR"}},"fee":{"amount":2,"currencyCode":"ZAR"},
       "process":{"status":"FAILED","isTest":true,"createdAt":"2026-10-26T10:00:00Z",
         "failureReasons":{"failureReasonCode":"ENTITY_EXPIRED","message":"Expired","failedAt":"2026-10-26T12:00:00Z"}},
       "paymentMethodResponse":{"paymentMethodCode":"CAPITEC_PAY"}}'''),
    );
    expect(status.status, PayinState.failed);
    expect(status.status.isFinal && status.isTest, isTrue);
    expect(status.requested, Money(amount: '100.5', currencyCode: 'ZAR'));
    expect(status.fee, Money(amount: '2', currencyCode: 'ZAR'));
    expect(status.failureReason?.code, 'ENTITY_EXPIRED');
    expect(status.paymentMethod, isA<CapitecPayResponse>());
  });

  test('unknown status is not final', () {
    final status = parsePayinStatus(json('{"process":{"status":"ON_HOLD"}}'));
    expect(status.status, PayinState.unknown);
    expect(status.status.isFinal, isFalse);
  });

  test('rand uses the house format', () {
    expect(formatMoney('1250', 'ZAR'), 'R1,250.00');
    expect(formatMoney('1250.5', 'USD'), 'USD 1,250.50');
    expect(formatMoney('0.00012345', 'BTC'), 'BTC 0.00012345'); // real decimals are never rounded away
    expect(formatMoney('1234567.10', 'ZAR'), 'R1,234,567.10');
    expect(Money(amount: '1250.00', currencyCode: 'ZAR').toString(), 'R1,250.00');
  });

  test('errors keep code and field but never the value', () {
    const body =
        '[{"code":"INVALID_ACCOUNT_NUMBER","description":"Bad account","attrCode":"account.accountNumber","attrValue":"1234567890"}]';
    final exception = SynqtApiException(406, parseErrors(body));
    expect(exception.errors, [
      const SynqtErrorReason(
        code: 'INVALID_ACCOUNT_NUMBER',
        field: 'account.accountNumber',
        description: 'Bad account',
      ),
    ]);
    expect(exception.toString(), 'SYNQT HTTP 406: INVALID_ACCOUNT_NUMBER (account.accountNumber)');
    expect(exception.toString(), isNot(contains('1234567890')));
    expect(payinErrors(exception), [
      const PayinError('account.accountNumber', 'Check the account number and try again. (INVALID_ACCOUNT_NUMBER)'),
    ]);
    // A code with no payer wording never shows SYNQT's description, which is written for the merchant.
    const unknown =
        '[{"code":"EMAIL_INVALID","description":"Bad email","attrCode":"emailAddress"},{"code":"NEW_CODE","description":"Merchant note"}]';
    final shown = payinErrors(SynqtApiException(406, parseErrors(unknown)));
    expect(shown, [
      const PayinError('emailAddress', 'Check this field (EMAIL_INVALID)'),
      const PayinError(
        null,
        'Your payment could not be completed. Please try again, or choose another payment method. (NEW_CODE)',
      ),
    ]);
    expect(shown.map((error) => error.text).join(), isNot(anyOf(contains('Bad email'), contains('Merchant note'))));
  });

  test('returnUrl must be https', () {
    final synqt = Synqt(SynqtEnvironment.sandbox);
    Payin make(String returnUrl) => synqt.payin(
      token: 'a.b+c',
      payinId: 'order-1',
      money: Money(amount: '12.30', currencyCode: 'ZAR'),
      returnUrl: returnUrl,
      callbackUrl: 'https://x.io/cb',
    );
    for (final bad in ['http://x.io/return', 'myapp://return', 'x.io/return', '']) {
      expect(() => make(bad), throwsA(isA<SynqtArgumentException>()), reason: bad);
    }
    expect(make('https://x.io/return'), isA<Payin>());
  });

  test('sheet messages for other errors', () {
    expect(payinErrors(SynqtApiException(406, parseErrors('{"code":"SYSTEM","description":null}'))), [
      const PayinError(
        null,
        'SYNQT could not process this payment (SYSTEM). Try again later or choose another method.',
      ),
    ]);
    expect(parseErrors('<html>'), isEmpty);
    expect(payinErrors(const SynqtApiException(406)).map((error) => error.text), [
      'The payment could not be created (HTTP 406).',
    ]);
    expect(const SynqtApiException(401).toString(), 'SYNQT HTTP 401');
    expect(
      payinErrors(
        const SynqtApiException(406, [
          SynqtErrorReason(code: 'PAYMENT_PROCESS_ERROR', description: 'For the merchant'),
        ]),
      ).map((error) => error.text),
      [
        'Something went wrong while processing your payment. Please try again, or choose another payment method. If it keeps happening, contact the merchant. (PAYMENT_PROCESS_ERROR)',
      ],
    );
    expect(payinErrors(const SynqtApiException(406, [SynqtErrorReason(code: 'NEW_CODE')])).map((error) => error.text), [
      'Your payment could not be completed. Please try again, or choose another payment method. (NEW_CODE)',
    ]);
  });

  test('every key the sheet uses has English text', () {
    // Keys passed to text('…') in the sources, so a typo shows up here rather than as a raw key in front of a payer.
    final keys = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .expand(
          (file) =>
              RegExp(r"""text\('(synqt_[a-z0-9_]+)'""").allMatches(file.readAsStringSync()).map((match) => match[1]!),
        )
        .toSet();
    expect(keys, isNotEmpty);
    expect(keys.where((key) => !hasText(key)), isEmpty);
  });

  PaymentSheetModel sheet(
    String code,
    Map<String, String> prefill, {
    required Future<CreatePayinResult> Function(PaymentMethod) submit,
  }) => PaymentSheetModel(
    form: methodForms.firstWhere((form) => form.code == code),
    prefill: prefill,
    operators: const [],
    summary: const PaymentSummary(amount: 'R1.00', merchant: null, method: 'x', reference: 'o-1'),
    submit: submit,
  );

  test('sheet errors are read out to screen readers', () {
    final model = sheet('CAPITEC_PAY', {}, submit: (_) => throw http.ClientException('offline'));
    final said = <String>[];
    var started = 0;
    model
      ..announce = said.add
      ..onPaymentStarted = (() => started++)
      ..pay();
    expect(said, ['Account number: Required\nLast name: Required']);
    expect(started, 0); // nothing went to SYNQT
  });

  test('payment started when the details go to SYNQT, and an offline failure says so', () async {
    const all = {'emailAddress': 'test@example.com', 'customerName.firstName': 'Jane', 'customerName.lastName': 'Doe'};
    final model = sheet('ZAPPER_QR', all, submit: (_) async => throw http.ClientException('offline'));
    var started = 0;
    model
      ..onPaymentStarted = (() => started++)
      ..start(); // everything mandatory is prefilled, so it pays straight away
    expect(started, 1);
    expect(model.processing, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(model.processing, isFalse);
    expect(model.banner, 'Could not reach SYNQT. Check the connection and try again.');
  });

  test('a refused prefilled value comes back into view under its field', () async {
    const all = {'emailAddress': 'test@example.com', 'customerName.firstName': 'Jane', 'customerName.lastName': 'Doe'};
    final model = sheet(
      'ZAPPER_QR',
      all,
      submit: (_) async => throw const SynqtApiException(406, [
        SynqtErrorReason(code: 'INVALID_EMAIL', field: 'emailAddress', description: 'Bad email'),
      ]),
    );
    expect(model.visible('emailAddress'), isFalse);
    model.start();
    await Future<void>.delayed(Duration.zero);
    expect(model.visible('emailAddress'), isTrue);
    expect(model.marks['emailAddress'], 'Check this field (INVALID_EMAIL)');
    expect(model.focusRequest?.path, 'emailAddress');
  });

  test('a prefill that fails its checks is shown with its error from the start', () {
    final model = sheet('ZAPPER_QR', {
      'emailAddress': 'not-an-email',
      'customerName.firstName': 'Jane',
      'customerName.lastName': 'Doe',
    }, submit: (_) async => throw StateError('not sent'));
    expect(model.visible('emailAddress'), isTrue);
    expect(model.marks['emailAddress'], isNotNull);
    expect(model.visible('customerName.firstName'), isFalse);
    expect(model.marks.keys, ['emailAddress']); // valid and blank fields show nothing yet

    // A dropdown prefill that is none of its options is shown, emptied, with the field's error.
    final fpx = sheet('FPX', {'account.accountType': 'gold'}, submit: (_) async => throw StateError('not sent'));
    expect(fpx.visible('account.accountType'), isTrue);
    expect(fpx.values['account.accountType'], '');
    expect(fpx.marks, {'account.accountType': 'Check this field'});
    expect(
      sheet('FPX', {
        'account.accountType': 'savings',
      }, submit: (_) async => throw StateError('not sent')).visible('account.accountType'),
      isFalse,
    );
  });

  test('a field error found on leaving the field is read out once', () {
    final model = sheet('ZAPPER_QR', {}, submit: (_) async => throw StateError('not sent'));
    final field = model.inputs.firstWhere((input) => input.path == 'emailAddress');
    final said = <String>[];
    model.announce = said.add;
    void leaveWith(String value) => model
      ..focus(field.path, true)
      ..setValue(field, value)
      ..focus(field.path, false);
    leaveWith('nope');
    leaveWith('still-nope'); // the same error again is not repeated
    expect(said, ['Email address: ${model.marks['emailAddress']}']);
    leaveWith('test@example.com');
    expect(said, hasLength(1));
  });

  test('closing after SYNQT accepted the payment returns that result', () async {
    const all = {'emailAddress': 'test@example.com', 'customerName.firstName': 'Jane', 'customerName.lastName': 'Doe'};
    final accepted = parseCreatePayin(
      '{"paymentMethodResponse":{"paymentMethodCode":"ZAPPER_QR","qrCode":"https://example.com/qr.png"}}',
    );
    final model = sheet('ZAPPER_QR', all, submit: (_) async => accepted);
    final results = <CreatePayinResult?>[];
    model
      ..onFinish = results.add
      ..start();
    await Future<void>.delayed(Duration.zero);
    expect(model.next?.qrCodeImageUrl, 'https://example.com/qr.png');
    model
      ..close()
      ..close();
    expect(results, [accepted]); // once
  });

  test('orbit dots follow the Lottie keyframes', () {
    expect(ease(0), closeTo(0, 0.001));
    expect(ease(0.5), closeTo(0.5, 0.001));
    expect(ease(1), closeTo(1, 0.001));
    expect(orbitDot(0).$1, closeTo(0, 0.001)); // magenta starts at the top
    expect(orbitDot(0).$2, closeTo(40, 0.001));
    expect(orbitDot(96.05).$1, closeTo(360, 0.01)); // one full turn
    expect(orbitDot(130).$2, closeTo(0, 0.001)); // resting in the hub
    expect(orbitDot(174).$2, closeTo(40, 0.001)); // back out, ready to loop
    // Aqua runs 7.2 frames behind; the file starts it at -35.51 on the y axis.
    expect(orbitDot(-orbitDelay).$2, closeTo(35.51, 0.05));
  });

  test('return url matches its path only', () {
    final back = Uri.parse('https://x.io/return');
    expect(isReturn(Uri.parse('https://x.io/return?idPayin=1'), back), isTrue);
    expect(isReturn(Uri.parse('https://x.io/returned'), back), isFalse);
    expect(isReturn(Uri.parse('https://evil.io/return'), back), isFalse);
  });

  test('intent links become the app link they stand for', () {
    expect(
      intentUrl('intent://pay?pa=m@bank&am=10#Intent;scheme=upi;package=com.bank;end').toString(),
      'upi://pay?pa=m@bank&am=10',
    );
    expect(intentUrl('intent://pay#Intent;package=com.bank;end'), isNull); // no scheme
    expect(intentUrl('intent://x#Intent;scheme=javascript;end'), isNull);
    expect(intentUrl('intent://x#Intent;scheme=https;end'), isNull);
    expect(intentUrl('upi://pay'), isNull);
  });

  group('over HTTP', () {
    test('create sends the method with SYNQT headers', () async {
      late http.Request sent;
      final client = MockClient((request) async {
        sent = request;
        return http.Response('{"paymentMethodResponse":{"paymentMethodCode":"CAPITEC_PAY","reference":"R1"}}', 200);
      });
      final result = await payin('order-1', client).create(
        const CapitecPayMethod(
          phoneNumber: '0821234567',
          customerName: PersonName(lastName: 'Doe'),
        ),
      );
      expect(sent.method, 'POST');
      expect(sent.url.toString(), 'https://api.sandbox.synqt.io/payins/order-1');
      expect(sent.headers['X-API-Version'], '2');
      expect(sent.headers['Authorization'], 'Bearer a.b+c');
      expect(json(sent.body)['paymentRequested'], {
        'money': {'amount': 12.3, 'currencyCode': 'ZAR'},
      });
      expect((json(sent.body)['paymentMethod'] as Map)['paymentMethodCode'], 'CAPITEC_PAY');
      expect(json(sent.body).containsKey('customerIp'), isFalse);
      expect(((result as InstructionsResult).paymentMethod as CapitecPayResponse).reference, 'R1');
    });

    test('a 409 retry fetches the existing payin, but only for the same method', () async {
      final client = MockClient(
        (request) async => request.method == 'POST'
            ? http.Response('[{"code":"PAYIN_ALREADY_EXISTS"}]', 409)
            : http.Response('{"paymentMethodResponse":{"paymentMethodCode":"CAPITEC_PAY"}}', 200),
      );
      final started = payin('order-1', client);
      expect(await started.create(const CapitecPayMethod(phoneNumber: '0821234567')), isA<InstructionsResult>());
      await expectLater(
        started.create(
          const ZapperQrMethod(
            emailAddress: 'a@b.co',
            customerName: PersonName(firstName: 'A', lastName: 'B'),
          ),
        ),
        throwsA(isA<SynqtApiException>().having((error) => error.errors.single.code, 'code', 'PAYIN_ALREADY_STARTED')),
      );
    });

    test('a refusal keeps its codes and a UTF-8 body reads correctly without a charset', () async {
      final client = MockClient(
        (request) async => request.url.path.endsWith('availablePaymentOptions')
            ? http.Response.bytes(
                utf8.encode(
                  '{"data":[{"paymentMethodCode":"PAYSHAP","paymentOperators":[{"code":"B","name":"Banco Ñ"}]}]}',
                ),
                200,
                headers: {'content-type': 'application/json'},
              )
            : http.Response('{"code":"TOKEN_EXPIRED"}', 401),
      );
      final started = payin('order-1', client);
      expect((await started.availablePaymentOptions()).single.operators.single.name, 'Banco Ñ');
      await expectLater(
        started.status(),
        throwsA(isA<SynqtApiException>().having((error) => error.httpCode, 'httpCode', 401)),
      );
    });
  });
}
