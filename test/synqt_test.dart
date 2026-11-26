import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:synqt/src/method_forms.dart';
import 'package:synqt/src/payin_checkout.dart' show SheetCheckout;
import 'package:synqt/src/payment_app.dart';
import 'package:synqt/src/payment_sheet_model.dart';
import 'package:synqt/src/method_form.dart';
import 'package:synqt/src/results.dart';
import 'package:synqt/src/strings.dart';
import 'package:synqt/src/ui/widgets.dart';
import 'package:synqt/synqt.dart';

const money = MoneyPaymentRequested(amount: 12.30, currencyCode: 'ZAR');

PayinCheckout checkout([String id = 'order-1', http.Client? client]) => Synqt(
  SynqtEnvironment.sandbox,
  client: client,
).checkout(token: 'a.b+c', payinId: id, money: money, returnUrl: 'https://x.io/return', callbackUrl: 'https://x.io/cb');

IncomingPaymentsApi api(http.Client client) =>
    IncomingPaymentsApi.create(Synqt(SynqtEnvironment.sandbox, client: client), 'a.b+c');

const capitec = Payin(
  paymentRequested: PaymentRequested(money: money),
  paymentMethod: CapitecPayMethod(phoneNumber: '0821234567'),
  returnUrl: 'https://x.io/return',
);

Map<String, Object?> json(String text) => jsonDecode(text) as Map<String, Object?>;

void main() {
  test('payment app url encodes params', () {
    expect(
      checkout().paymentAppUrl(merchantCode: 'MID', extra: {'emailAddress': 'a@b.co'}),
      'https://payment.sandbox.synqt.io/?merchantCode=MID&idPayin=order-1&token=a.b%2Bc&amount=12.3'
      '&currencyCode=ZAR&callbackUrl=https%3A%2F%2Fx.io%2Fcb&returnUrl=https%3A%2F%2Fx.io%2Freturn&emailAddress=a%40b.co',
    );
  });

  test('payment app offers a method and editable prefill', () {
    final url = checkout().paymentAppUrl(
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
    expect(checkout().paymentAppUrl(merchantCode: 'MID'), isNot(contains('optionsAvailable')));
  });

  test('rejects an unsafe payin ID', () {
    expect(() => checkout('../x'), throwsA(isA<SynqtArgumentException>()));
    expect(
      () => api(MockClient((_) async => http.Response('{}', 200))).getPayin('../x'),
      throwsA(isA<SynqtArgumentException>()),
    );
  });

  test('a payin request has the Java SDK\'s shape', () {
    const payin = Payin(
      paymentRequested: PaymentRequested(money: money, segmentCode: 'S1'),
      paymentMethod: CapitecPayMethod(phoneNumber: '0821234567'),
      returnUrl: 'https://x.io/return',
      customerIp: '10.0.0.1',
    );
    final body = payin.toJson();
    // callbackUrl is optional
    expect(body.keys.toSet(), {'paymentRequested', 'paymentMethod', 'returnUrl', 'customerIp'});
    expect(jsonDecode(jsonEncode(body)), {
      'paymentRequested': {
        'money': {'amount': 12.3, 'currencyCode': 'ZAR'},
        'segmentCode': 'S1',
      },
      'paymentMethod': {'paymentMethodCode': 'CAPITEC_PAY', 'phoneNumber': '0821234567'},
      'returnUrl': 'https://x.io/return',
      'customerIp': '10.0.0.1',
    });
  });

  test('the accepted response is chosen by the field SYNQT sent', () {
    final redirect = PayinAcceptedResponse.fromJson(
      json(r'''
      {"paymentRequested":{"money":{"amount":12.3,"currencyCode":"ZAR"}},
       "redirectTo":{"method":"POST","url":"https://p.io","data":"{\"k\":\"v\",\"n\":1}"}}'''),
    );
    expect(redirect, isA<PayinAcceptedRedirectResponse>());
    expect((redirect as PayinAcceptedRedirectResponse).paymentRequested?.money.currencyCode, 'ZAR');
    expect(redirect.redirect()?.formData(), {'k': 'v', 'n': '1'});
    expect(redirect.nextStep(), isNull);

    final method = PayinAcceptedResponse.fromJson(
      json('{"paymentMethodResponse":{"paymentMethodCode":"PAYSHAP","reference":"REF1"}}'),
    );
    expect(((method as PayinAcceptedMethodResponse).paymentMethodResponse as PayShapMethodResponse).reference, 'REF1');
    expect(method.nextStep()?.reference, 'REF1');
    expect(method.redirect(), isNull);
    expect(() => PayinAcceptedResponse.fromJson(const {}), throwsFormatException);
  });

  test('parses a payin detail', () {
    final detail = PayinDetail.fromJson(
      json('''
      {"paymentRequested":{"money":{"amount":100.50,"currencyCode":"ZAR"}},"fee":{"amount":2,"currencyCode":"ZAR"},
       "process":{"status":"FAILED","isTest":true,"createdAt":"2026-10-26T10:00:00Z",
         "failureReasons":{"failureReasonCode":"ENTITY_EXPIRED","message":"Expired","failedAt":"2026-10-26T12:00:00Z"}},
       "paymentMethodResponse":{"paymentMethodCode":"CAPITEC_PAY"},
       "settlement":{"paymentMethodCode":"CRYPTO_TRANSFER","paymentOperatorCode":"OP","account":{"accountNumber":"A1"}},
       "customer":{"idCustomer":"C1"}}'''),
    );
    expect(detail.process?.status, PaymentStatus.failed);
    expect(detail.isFinal && detail.process?.isTest == true, isTrue);
    expect(detail.paymentRequested?.money.amount, 100.5);
    expect(detail.fee?.amount, 2);
    expect(detail.process?.failureReasons?.failureReasonCode, 'ENTITY_EXPIRED');
    expect(detail.process?.failureReasons?.payerMessage, text('synqt_failure_expired'));
    expect(detail.paymentMethodResponse, isA<CapitecPayMethodResponse>());
    expect((detail.settlement as SettlementCryptoTransferMethod).paymentOperatorCode, 'OP');
    expect(detail.customer?.idCustomer, 'C1');
  });

  test('unknown status is not final', () {
    expect(PayinDetail.fromJson(json('{"process":{"status":"ON_HOLD"}}')).isFinal, isFalse);
  });

  test('rand uses the house format', () {
    expect(formatMoney('1250', 'ZAR'), 'R1,250.00');
    expect(formatMoney('1250.5', 'USD'), 'USD 1,250.50');
    expect(formatMoney('0.00012345', 'BTC'), 'BTC 0.00012345'); // real decimals are never rounded away
    expect(formatMoney('1234567.10', 'ZAR'), 'R1,234,567.10');
    expect(const MoneyPaymentRequested(amount: 1250.00, currencyCode: 'ZAR').format(), 'R1,250.00');
    expect(const MoneyResponse(amount: 0.5, currencyCode: 'USD').format(), 'USD 0.50');
    expect(const MoneyResponse(currencyCode: 'USD').format(), isNull);
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
    PayinCheckout make(String returnUrl) =>
        synqt.checkout(token: 'a.b+c', payinId: 'order-1', money: money, returnUrl: returnUrl);
    for (final bad in ['http://x.io/return', 'myapp://return', 'x.io/return', '']) {
      expect(() => make(bad), throwsA(isA<SynqtArgumentException>()), reason: bad);
    }
    expect(make('https://x.io/return'), isA<PayinCheckout>());
    // Without a callbackUrl, the Payment Web App link leaves it out.
    expect(make('https://x.io/return').paymentAppUrl(merchantCode: 'MID'), isNot(contains('callbackUrl')));
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
    required Future<PayinAcceptedResponse> Function(PaymentMethodPayin) submit,
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
    final accepted = PayinAcceptedResponse.fromJson(
      json('{"paymentMethodResponse":{"paymentMethodCode":"ZAPPER_QR","qrCode":"https://example.com/qr.png"}}'),
    );
    final model = sheet('ZAPPER_QR', all, submit: (_) async => accepted);
    final results = <PayinAcceptedResponse?>[];
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
    test('createPayin posts the payin with SYNQT headers and returns what SYNQT accepted', () async {
      late http.Request sent;
      final client = MockClient((request) async {
        sent = request;
        return http.Response(
          '{"paymentRequested":{"money":{"amount":12.3,"currencyCode":"ZAR"}},'
          '"paymentMethodResponse":{"paymentMethodCode":"CAPITEC_PAY","reference":"R1"}}',
          201,
        );
      });
      const payin = Payin(
        paymentRequested: PaymentRequested(money: money),
        paymentMethod: CapitecPayMethod(
          phoneNumber: '0821234567',
          customerName: PersonName(lastName: 'Doe'),
        ),
        returnUrl: 'https://x.io/return',
        callbackUrl: 'https://x.io/cb',
      );
      final accepted = await api(client).createPayin('order-1', payin);
      expect(sent.method, 'POST');
      expect(sent.url.toString(), 'https://api.sandbox.synqt.io/payins/order-1');
      expect(sent.headers['X-API-Version'], '2');
      expect(sent.headers['Authorization'], 'Bearer a.b+c');
      expect(json(sent.body), jsonDecode(jsonEncode(payin.toJson())));
      expect(json(sent.body).containsKey('customerIp'), isFalse);
      final method = (accepted as PayinAcceptedMethodResponse).paymentMethodResponse;
      expect((method as CapitecPayMethodResponse).reference, 'R1');
    });

    test('createPayin checks the request before sending', () async {
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      });
      const insecure = Payin(
        paymentRequested: PaymentRequested(money: money),
        paymentMethod: CapitecPayMethod(phoneNumber: '0821234567'),
        returnUrl: 'http://x.io/return',
      );
      await expectLater(api(client).createPayin('order-1', insecure), throwsA(isA<SynqtArgumentException>()));
      await expectLater(api(client).createPayin('../x', capitec), throwsA(isA<SynqtArgumentException>()));
      expect(requests, 0);
    });

    test('a retry of the same payin returns the existing one', () async {
      final sent = <String>[];
      final client = MockClient((request) async {
        sent.add('${request.method} ${request.url.path}');
        return request.method == 'POST'
            ? http.Response('[]', 409)
            : http.Response(
                '{"paymentRequested":{"money":{"amount":12.3,"currencyCode":"ZAR"}},'
                '"paymentMethodResponse":{"paymentMethodCode":"CAPITEC_PAY","reference":"R1"}}',
                200,
              );
      });
      final accepted = await api(client).createPayin('order-1', capitec);
      expect(accepted.nextStep()?.reference, 'R1');
      expect(sent, ['POST /payins/order-1', 'GET /payins/order-1']);
    });

    test('a retry with another method is refused', () async {
      final client = MockClient(
        (request) async => request.method == 'POST'
            ? http.Response('[{"code":"PAYIN_ALREADY_EXISTS"}]', 409)
            : http.Response('{"paymentMethodResponse":{"paymentMethodCode":"FNB_DIRECT_EFT"}}', 200),
      );
      await expectLater(
        api(client).createPayin('order-1', capitec),
        throwsA(
          isA<SynqtApiException>()
              .having((error) => error.httpCode, 'httpCode', 409)
              .having((error) => error.errors.single.code, 'code', 'PAYIN_ALREADY_STARTED'),
        ),
      );
    });

    test('a refusal keeps its codes but not what the payer typed', () async {
      final client = MockClient(
        (_) async => http.Response(
          '[{"code":"INVALID_PHONE_NUMBER","attrCode":"phoneNumber","attrValue":"0821234567","description":"bad"}]',
          406,
        ),
      );
      final error = await api(client)
          .createPayin('order-1', capitec)
          .then<SynqtApiException?>((_) => null, onError: (Object error) => error as SynqtApiException);
      expect(error?.errors, [
        const SynqtErrorReason(code: 'INVALID_PHONE_NUMBER', field: 'phoneNumber', description: 'bad'),
      ]);
      expect(error.toString(), isNot(contains('0821234567')));
    });

    test('the other calls go to SYNQT\'s payin endpoints', () async {
      final sent = <String>[];
      final client = MockClient((request) async {
        sent.add('${request.method} ${request.url.path} ${request.body}');
        return http.Response(switch (request.url.path) {
          '/payins/order-1' => '{"process":{"status":"SUCCESS"}}',
          '/payins/order-1/accounts' => '{"customerAccountRequest":{"accountNumber":"0000000000"}}',
          _ => '{}',
        }, 200);
      });
      final synqtApi = api(client);
      expect((await synqtApi.getPayin('order-1')).isFinal, isTrue);
      expect((await synqtApi.getPayinAccounts('order-1')).customerAccountRequest?.accountNumber, '0000000000');
      await synqtApi.setPayinExternalReference('order-1', 'UTR1');
      expect(sent, [
        'GET /payins/order-1 ',
        'GET /payins/order-1/accounts ',
        'POST /payins/order-1/!setExternalReference {"reference":"UTR1"}',
      ]);
      expect(() => synqtApi.setPayinExternalReference('order-1', ''), throwsA(isA<SynqtArgumentException>()));
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
      final options = await api(client).payinAvailablePaymentOptions(const PaymentRequested(money: money));
      expect(options.data!.single.paymentOperators!.single.name, 'Banco Ñ');
      expect(options.data!.single.name, 'PayShap');
      await expectLater(
        api(client).getPayin('order-1'),
        throwsA(isA<SynqtApiException>().having((error) => error.httpCode, 'httpCode', 401)),
      );
    });

    group('the sheet\'s bank list', () {
      // Answers each request with the next status (the last repeats) and counts the requests.
      Future<(List<PaymentOperatorIncoming>?, int)> load(List<int> statuses) async {
        var requests = 0;
        final client = MockClient((request) async {
          final status = statuses[requests < statuses.length ? requests : statuses.length - 1];
          requests++;
          return http.Response(
            status == 200
                ? '{"data":[{"paymentMethodCode":"OFFLINE","paymentOperators":[{"code":"ABSA","name":"Absa"}]}]}'
                : '{"errors":[]}',
            status,
          );
        });
        final form = methodForms.firstWhere((form) => form.code == 'OFFLINE');
        final loaded = await checkout('order-1', client).sheetOperators(form, retryAfter: Duration.zero);
        return (loaded, requests);
      }

      test('server errors are retried twice, then the list loads', () async {
        final (loaded, requests) = await load([503, 500, 200]);
        expect(loaded?.map((paymentOperator) => paymentOperator.code), ['ABSA']);
        expect(requests, 3);
      });

      test('three failures mean the list could not be loaded', () async {
        final (loaded, requests) = await load([503]);
        expect(loaded, isNull);
        expect(requests, 3);
      });

      test('a refusal is not retried', () async {
        final (loaded, requests) = await load([403]);
        expect(loaded, isNull);
        expect(requests, 1);
      });

      test('a connection failure is retried', () async {
        var requests = 0;
        final client = MockClient(
          (_) async => ++requests < 3 ? throw http.ClientException('offline') : http.Response('{"data":[]}', 200),
        );
        final form = methodForms.firstWhere((form) => form.code == 'OFFLINE');
        expect(await checkout('order-1', client).sheetOperators(form, retryAfter: Duration.zero), isEmpty);
        expect(requests, 3);
      });
    });
  });
}
