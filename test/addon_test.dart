import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synqt/addon.dart';
import 'package:synqt/src/method_form.dart';
import 'package:synqt/src/method_forms.dart';
import 'package:synqt/src/payment_sheet_model.dart';
import 'package:synqt/src/results.dart';
import 'package:synqt/synqt.dart';

class _Method implements SheetMethod {
  _Method(this.code, [this.fields]);

  @override
  final String code;
  final _Section? fields;

  @override
  String get name => 'Test add-on';

  @override
  bool get secure => false;

  @override
  MethodSection section(Payin payin, Map<String, String> prefill) => fields!;
}

class _Section implements MethodSection {
  List<String> problems = [];
  Object? buildError;
  final shown = <String, String>{};
  var cleared = false;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  @override
  List<String> check() => problems;

  @override
  Future<Map<String, Object?>> paymentMethod() async =>
      buildError == null ? {'paymentMethodCode': 'TEST_ADDON', 'secret': 'sealed'} : throw buildError!;

  @override
  String? showError(String attr, String message) {
    if (!attr.endsWith('secret')) return null;
    shown[attr] = message;
    return 'Secret: $message';
  }

  @override
  void clear() => cleared = true;
}

void main() {
  test('an added method is offered and named once', () {
    addSheetMethod(_Method('TEST_ADDON'));
    addSheetMethod(_Method('TEST_ADDON'));
    expect(Synqt.directPaymentMethods.where((method) => method.code == 'TEST_ADDON').length, 1);
    expect(const DirectPaymentMethod('TEST_ADDON').name, 'Test add-on');
    expect(const PaymentOption(code: 'TEST_ADDON').name, 'Test add-on');
  });

  test('built-in methods cannot be replaced, and CARD needs the add-on', () {
    expect(() => addSheetMethod(_Method('CAPITEC_PAY')), throwsA(isA<SynqtArgumentException>()));
    expect(Synqt.directPaymentMethods.any((method) => method.code == 'CARD'), isFalse);
  });

  test('a 3-D Secure redirect becomes a redirect', () {
    final result = parseCreatePayin(
      '{"paymentMethodResponse":{"paymentMethodCode":"CARD","userInteraction":{"type":"REDIRECT","url":"https://acs.example/3ds"}}}',
    );
    expect(result, isA<RedirectResult>().having((redirect) => redirect.url, 'url', 'https://acs.example/3ds'));
  });

  test('a form with nothing to enter says so; one with fields has no intro', () {
    PaymentSheetModel sheet(MethodForm form) => PaymentSheetModel(
      form: form,
      prefill: const {},
      operators: const [],
      summary: const PaymentSummary(amount: 'R1.00', merchant: null, method: 'Test', reference: 'o-1'),
      submit: (_) => throw StateError('not sent'),
    );
    expect(
      sheet(MethodForm('TEST_EMPTY', '', const [], build: (_) => throw StateError('nothing to build'))).intro,
      'No details needed. Tap Pay to continue.',
    );
    expect(sheet(methodForms.firstWhere((form) => form.code == 'CAPITEC_PAY')).intro, isNull);
  });

  group('sheet with an add-on section', () {
    late _Section section;
    late List<Map<String, Object?>> sent;
    late List<String> said;
    late PaymentSheetModel model;
    Future<CreatePayinResult> Function(Map<String, Object?>) reply = (_) async => throw StateError('unset');

    setUp(() {
      section = _Section();
      sent = [];
      said = [];
      addSheetMethod(_Method('TEST_ADDON', section));
      model = PaymentSheetModel(
        form: MethodForm('TEST_ADDON', '', const [], build: (_) => throw StateError('built by the add-on')),
        prefill: const {},
        operators: const [],
        summary: const PaymentSummary(amount: 'R1.00', merchant: null, method: 'Test add-on', reference: 'o-1'),
        section: section,
        submit: (_) => throw StateError('not for add-ons'),
        submitJson: (json) {
          sent.add(json);
          return reply(json);
        },
      )..announce = said.add;
    });

    test('does not pay by itself, and asks the payer for details', () {
      model.start();
      expect(model.processing, isFalse);
      expect(model.methodName, 'Test add-on');
      expect(model.intro, isNull);
    });

    test('a failed check sends nothing and is read out', () {
      section.problems = ['Secret: Required'];
      model.pay();
      expect(sent, isEmpty);
      expect(model.processing, isFalse);
      expect(said, ['Secret: Required']);
    });

    test("the section's method is sent, and its errors come back to it", () async {
      reply = (_) async => throw const SynqtApiException(406, [
        SynqtErrorReason(code: 'INVALID_SECRET', field: 'paymentMethod.secret', description: 'Bad'),
      ]);
      var started = 0;
      model
        ..onPaymentStarted = (() => started++)
        ..pay();
      await Future<void>.delayed(Duration.zero);
      expect(sent.single['secret'], 'sealed');
      expect(started, 1);
      expect(section.shown.keys, ['paymentMethod.secret']);
      expect(model.banner, isNull);
      expect(said.single, startsWith('Secret: '));
    });

    test('a section that cannot build its method shows why and sends nothing', () async {
      section.buildError = const MethodSectionException('Could not secure it');
      var started = 0;
      model
        ..onPaymentStarted = (() => started++)
        ..pay();
      await Future<void>.delayed(Duration.zero);
      expect(sent, isEmpty);
      expect(started, 0);
      expect(model.banner, 'Could not secure it');
      expect(model.processing, isFalse);
    });
  });
}
