import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:synqt/src/method_form.dart';
import 'package:synqt/src/method_forms.dart';
import 'package:synqt/src/payin_models.dart';
import 'package:synqt/src/payment_methods.dart';
import 'package:synqt/src/results.dart';
import 'package:synqt/src/strings.dart';

MethodForm form(String code) => methodForms.firstWhere((form) => form.code == code);

FormInput field(String code, String path) => form(code).fields.firstWhere((field) => field.path == path);

List<String> pairs(List<PayinError> errors) => errors.map((error) => '$error').toList();

void main() {
  test('every method except CARD has a named form', () {
    expect(methodForms.map((form) => form.code).toSet().length, 32);
    expect(methodForms.any((form) => form.code == 'CARD'), isFalse);
    expect(text(form('CAPITEC_PAY').name), 'Capitec Pay');
  });

  test('every string the forms use has English text', () {
    final keys = [
      for (final form in methodForms) ...[
        form.name,
        for (final oneOf in form.oneOfs) ...[oneOf.question, ...oneOf.choices.map((choice) => choice.label)],
        for (final field in form.fields) ...[
          field.label,
          ...[field.hint, field.placeholder, field.section, field.invalid].nonNulls,
          ...field.options.map((option) => option.label),
        ],
      ],
    ];
    expect(keys.where((key) => !hasText(key)), isEmpty);
  });

  test('payers never see JSON paths', () {
    final labels = methodForms.expand((form) => form.fields).map((field) => text(field.label));
    expect(labels.where((label) => label.contains('.') || RegExp(r'^[a-z]+[A-Z]').hasMatch(label)), isEmpty);
  });

  test('blank groups are left out and filled ones built', () {
    final method = form('CAPITEC_PAY').build(
      const FormValues({'phoneNumber': ' 0821234567 ', 'account.accountNumber': '', 'customerName.lastName': 'Doe'}),
    );
    expect(
      method,
      const CapitecPayMethod(
        phoneNumber: '0821234567',
        customerName: PersonName(lastName: 'Doe'),
      ),
    );
  });

  test('a missing required field names the path', () {
    expect(
      () => form('CAPITEC_PAY').build(const FormValues({'customerName.firstName': 'Jane'})),
      throwsA(isA<SynqtArgumentException>().having((error) => error.path, 'path', 'customerName.lastName')),
    );
  });

  test('problems use the spec limits in plain words', () {
    final problems = form('CAPITEC_PAY').problems({
      'said': '12345',
      'account.accountNumber': '12345678ab',
      'emailAddress': 'nope',
      'customerName.lastName': 'Doe',
    }, []);
    expect(pairs(problems), [
      'emailAddress=Enter a valid email address',
      'said=Enter 13 digits',
      'account.accountNumber=Enter 10 digits',
    ]);
  });

  test('a section with a mandatory field is mandatory', () {
    expect(pairs(form('CAPITEC_PAY').problems({}, [])), ['customerName.lastName=Required']);
    expect(text(field('CAPITEC_PAY', 'customerName.lastName').section!), 'Your name');
    // A section with nothing mandatory in it stays optional.
    expect(
      text(form('EWALLET').fields.firstWhere((field) => field.path.startsWith('account.')).section!),
      'Bank account (optional)',
    );
    expect(
      pairs(form('FNB_DIRECT_EFT').problems({}).where((error) => error.attr == 'account.accountNumber').toList()),
      ['account.accountNumber=Required'],
    );
  });

  test('one field is checked on its own', () {
    final said = field('CAPITEC_PAY', 'said');
    expect(problem(said, {'said': '12345'}), const PayinError('said', 'Enter 13 digits'));
    expect(problem(said, {'said': '0000000000000'}), isNull);
  });

  test('Absa Pay asks for one detail and bank account is the default', () {
    final absaPay = form('ABSA_PAY');
    final bank = absaPay.oneOfs[0].choices[0], id = absaPay.oneOfs[0].choices[1];
    expect(text(bank.label), 'Bank account');
    const lastName =
        'customerName.lastName=Required'; // the name is asked for on Absa Pay, though the spec makes it optional
    expect(pairs(absaPay.problems({})), ['account.accountNumber=Required', lastName]);
    // Picking the ID number makes it the required one, and a stale account number is not checked or sent.
    expect(pairs(absaPay.problems({'account.accountNumber': 'x'}, [id])), ['said=Required', lastName]);
    expect(absaPay.shows('emailAddress', [id]), isTrue);
    expect(absaPay.shows('account.accountNumber', [id]), isFalse);
    final method =
        absaPay.build(const FormValues({'said': '0000000000000', 'customerName.lastName': 'Doe'})) as AbsaPayMethod;
    expect(method.said, '0000000000000');
    expect(method.account, isNull);
  });

  test('PayShap tiles need their companion fields', () {
    final payShap = form('PAYSHAP');
    final bank = payShap.oneOfs[0].choices[0], mobile = payShap.oneOfs[0].choices[1];
    const values = {'paymentOperatorCode': 'BANK', 'customerName.lastName': 'Doe'};
    expect(payShap.problems(values, [bank]).map((error) => error.attr), [
      'account.accountName',
      'account.accountNumber',
    ]);
    expect(payShap.problems(values, [mobile]).map((error) => error.attr), ['phoneNumber', 'externalProviderCode']);
    expect(
      payShap.problems({...values, 'phoneNumber': '000000000000', 'externalProviderCode': 'X'}, [mobile]),
      isEmpty,
    );
    expect(payShap.fields.where((field) => mobile.paths.contains(field.path)).map((field) => text(field.label)), [
      'Mobile number',
      'Provider',
    ]);
  });

  test('FNB Pay asks for ID or passport with ID first', () {
    final fnbDirectEft = form('FNB_DIRECT_EFT');
    final id = fnbDirectEft.oneOfs[0].choices[0], passport = fnbDirectEft.oneOfs[0].choices[1];
    expect([text(id.label), text(passport.label)], ['South African ID number', 'Passport number']);
    expect(pairs(fnbDirectEft.problems({}).where((error) => error.attr == 'said').toList()), ['said=Required']);
    expect(fnbDirectEft.problems({}, [passport]).any((error) => error.attr == 'said'), isFalse);
    expect(pairs(fnbDirectEft.problems({}, [passport]).where((error) => error.attr == 'passportNumber').toList()), [
      'passportNumber=Required',
    ]);
  });

  test('PayShap also asks which ID but leaves it optional', () {
    final payShap = form('PAYSHAP');
    final pay = payShap.oneOfs[0], ids = payShap.oneOfs[1];
    expect(text(ids.question), 'Which ID do you want to give?');
    final id = ids.choices[0], passport = ids.choices[1];
    expect(['said', 'passportNumber'].map((path) => text(field('PAYSHAP', path).label)), [
      'South African ID number (optional)',
      'Passport number (optional)',
    ]);
    final chosen = [pay.choices[0], id];
    expect(payShap.shows('said', chosen), isTrue);
    expect(payShap.shows('passportNumber', chosen), isFalse);
    // Both IDs are optional in the spec, so choosing one does not make it mandatory.
    expect(payShap.problems({}, chosen).any((error) => error.attr == 'said'), isFalse);
    expect(
      pairs(
        payShap
            .problems({'passportNumber': '123'}, [pay.choices[0], passport])
            .where((error) => error.attr == 'passportNumber')
            .toList(),
      ),
      ['passportNumber=Enter a letter followed by 7 or 8 numbers'],
    );
  });

  test('only valid prefilled fields count as filled in', () {
    final zapper = form('ZAPPER_QR');
    const prefill = {
      'emailAddress': 'test@example.com',
      'customerName.firstName': 'Jane',
      'customerName.lastName': 'Doe',
    };
    expect(zapper.filledIn(prefill, prefill, []), ['emailAddress', 'customerName.firstName', 'customerName.lastName']);
    // A malformed email stays in view so the payer can fix it; a value the payer has since changed is theirs.
    final badEmail = {...prefill, 'emailAddress': 'nope'};
    expect(zapper.filledIn(badEmail, badEmail, []), ['customerName.firstName', 'customerName.lastName']);
    final changed = {...prefill, 'customerName.firstName': 'Janet'};
    expect(zapper.filledIn(changed, prefill, []), ['emailAddress', 'customerName.lastName']);
  });

  test('a prefilled first and last name hide the optional name fields', () {
    final capitec = form('CAPITEC_PAY');
    const names = {'customerName.firstName': 'Jane', 'customerName.lastName': 'Doe'};
    expect(capitec.filledIn(names, names, capitec.defaultChoices), [
      'customerName.firstName',
      'customerName.lastName',
      'customerName.titleBefore',
      'customerName.middleName',
      'customerName.titleAfter',
    ]);
    // With only the last name, the payer still sees the rest of the name section.
    const last = {'customerName.lastName': 'Doe'};
    expect(capitec.filledIn(last, last, capitec.defaultChoices), ['customerName.lastName']);
  });

  test('the sheet pays straight away only when every mandatory field is filled in', () {
    final zapper = form('ZAPPER_QR');
    const all = {'emailAddress': 'test@example.com', 'customerName.firstName': 'Jane', 'customerName.lastName': 'Doe'};
    expect(zapper.readyToPay(all, zapper.filledIn(all, all, []), []), isTrue);
    final noEmail = {...all}..remove('emailAddress');
    expect(zapper.readyToPay(noEmail, zapper.filledIn(noEmail, noEmail, []), []), isFalse);
    // Net banking has only optional fields, so the payer still sees its form.
    expect(form('NETBANKING').readyToPay({}, [], []), isFalse);
  });

  test('South African rules make spec-optional fields mandatory', () {
    expect(form('ONLINE').fields.where((field) => field.required).map((field) => field.path), [
      'paymentOperatorCode',
      'emailAddress',
      'account.accountName',
      'account.accountNumber',
      'account.accountType',
    ]);
    expect(field('OFFLINE', 'paymentOperatorCode').required, isTrue);
    expect(pairs(form('OFFLINE').problems({}).where((error) => error.attr == 'paymentOperatorCode').toList()), [
      'paymentOperatorCode=Required',
    ]);
  });

  test('Capitec Pay asks for one detail', () {
    expect(form('CAPITEC_PAY').oneOfs[0].choices.map((choice) => text(choice.label)), [
      'Bank account',
      'Mobile number',
      'South African ID number',
    ]);
  });

  test('every form builds a method that passes its own checks', () {
    // Fill every field with something, so a form never builds a method that `create` would then reject.
    for (final form in methodForms) {
      final values = {for (final field in form.fields) field.path: field.options.firstOrNull?.value ?? 'x'};
      expect(() => validatePaymentMethod(form.build(FormValues(values))), returnsNormally, reason: form.code);
    }
  });

  test('payment operators carry their external providers', () {
    final op = PaymentOperatorIncoming.fromJson(
      jsonDecodeMap(
        '{"code":"ZA_BANK","name":"A Bank","externalProviders":{"providers":[{"code":"P1","name":"Provider one"},{"name":"no code"}]}}',
      ),
    );
    expect(op.code, 'ZA_BANK');
    expect(op.name, 'A Bank');
    expect(op.externalProviders?.providers?.map((provider) => provider.name), ['Provider one', 'no code']);
    // The sheet skips providers without a code.
    expect(providers([op]).map((provider) => provider.code), ['P1']);
  });

  test('providers list every bank\'s providers once', () {
    // Shaped like Stable's PayShap options: bank codes with providers that repeat across banks.
    const p1 = ExternalProvider(code: 'STANDARDBANK', name: 'StandardBank');
    const p2 = ExternalProvider(code: 'SHYFT', name: 'Shyft');
    const p3 = ExternalProvider(code: 'CAPITEC', name: 'CAPITEC');
    const banks = [
      PaymentOperatorIncoming(
        code: 'ZA_STANDARD',
        name: 'Standard Bank',
        externalProviders: ExternalProviders(providers: [p1, p2]),
      ),
      PaymentOperatorIncoming(
        code: 'ZA_CAPITEC',
        name: 'Capitec',
        externalProviders: ExternalProviders(providers: [p3, p1]),
      ),
      PaymentOperatorIncoming(
        code: 'NG_BANK',
        name: 'Another market',
        externalProviders: ExternalProviders(
          providers: [ExternalProvider(code: 'NG_P', name: 'x')],
        ),
      ),
    ];
    expect(providers(banks), [p1, p2, p3, const ExternalProvider(code: 'NG_P', name: 'x')]);
    expect(field('PAYSHAP', 'externalProviderCode').kind, FieldKind.provider);
  });

  test('SA mobile numbers are up to 12 characters starting with 0', () {
    for (final code in ['PAYSHAP', 'CAPITEC_PAY']) {
      final phone = field(code, 'phoneNumber');
      expect(problem(phone, {'phoneNumber': '0000000000'}), isNull); // 10 digits, the usual SA length
      expect(problem(phone, {'phoneNumber': '000000000000'}), isNull);
      expect(problem(phone, {'phoneNumber': '1000000000'})?.text, 'Enter up to 12 characters, starting with 0');
      expect(problem(phone, {'phoneNumber': '0000000000000'})?.text, 'Enter up to 12 characters, starting with 0');
    }
  });

  test('account names take letters from any language', () {
    final name = field('CAPITEC_PAY', 'account.accountName');
    expect(problem(name, {'account.accountName': "Zoë O'Neill-Nkosi"}), isNull);
    expect(
      problem(name, {'account.accountName': 'A <b>'})?.text,
      'Use letters, numbers, spaces and common punctuation only',
    );
  });

  test('payment options carry operators and payer-facing names', () {
    final options = AvailablePayinOptionList.fromJson(
      jsonDecodeMap('''
      {"data":[{"paymentMethodCode":"FPX","paymentOperators":[{"code":"MBB","name":"Maybank"},{"code":"X"}]},
         {"paymentMethodCode":"BRAND_NEW","segmentCode":"S1"}]}'''),
    ).data!;
    expect(options[0].paymentMethodCode, 'FPX');
    expect(options[0].paymentOperators?.map((op) => (op.code, op.name)), [('MBB', 'Maybank'), ('X', null)]);
    expect(options[1].paymentMethodCode, 'BRAND_NEW');
    expect(options[1].paymentOperators, isNull);
    expect(options[1].segmentCode, 'S1');
    expect(options[0].name, 'FPX online banking');
    expect(options[1].name, isNull); // the sheet cannot show it, so it has no payer-facing name
  });
}

Map<String, Object?> jsonDecodeMap(String text) => jsonDecode(text) as Map<String, Object?>;
