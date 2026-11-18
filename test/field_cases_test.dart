// The same inputs, checked the same way, in every SYNQT SDK. Generated: add cases to the shared table, not here.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:synqt/src/method_form.dart';
import 'package:synqt/src/method_forms.dart';

void main() {
  test('every SDK checks these fields the same way', () {
    const cases = <(String, String, String, String?)>[
      ('CAPITEC_PAY', 'said', '0000000000000', null),
      ('CAPITEC_PAY', 'said', '12345', 'Enter 13 digits'),
      ('CAPITEC_PAY', 'account.accountNumber', '1234567890', null),
      ('CAPITEC_PAY', 'account.accountNumber', '12345678ab', 'Enter 10 digits'),
      ('CAPITEC_PAY', 'emailAddress', 'test@example.com', null),
      ('CAPITEC_PAY', 'emailAddress', 'nope', 'Enter a valid email address'),
      ('CAPITEC_PAY', 'phoneNumber', '0821234567', null),
      ('CAPITEC_PAY', 'phoneNumber', '821234567', 'Enter up to 12 characters, starting with 0'),
      ('CAPITEC_PAY', 'customerName.lastName', '', 'Required'),
      ('CAPITEC_PAY', 'customerName.lastName', 'Doe', null),
      ('UPIID', 'upiId', 'name@bank', null),
      ('UPIID', 'upiId', 'namebank', 'Enter a UPI ID like name@bank'),
      ('FNB_DIRECT_EFT', 'passportNumber', 'A1234567', null),
      ('FNB_DIRECT_EFT', 'passportNumber', '1234', 'Enter a letter followed by 7 or 8 numbers'),
      ('PIXQR', 'taxId', '12345678901234', null),
      ('PIXQR', 'taxId', '123', 'Enter your 14-character CPF or CNPJ'),
      ('OTT_VOUCHER', 'voucherPin', '123456789012', null),
    ];
    for (final (code, path, value, want) in cases) {
      final field = methodForms
          .singleWhere((form) => form.code == code)
          .fields
          .singleWhere((input) => input.path == path);
      expect(problem(field, {path: value})?.text, want, reason: '$code $path "$value"');
    }
  });
}
