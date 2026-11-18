# Example

Your backend mints a SYNQT token for the order (see the README, step 2). The app then creates the payin and shows the payment sheet:

```dart
import 'package:flutter/widgets.dart';
import 'package:synqt/synqt.dart';

Future<void> pay(BuildContext context, String token, String payinId) async {
  final payin = Synqt(SynqtEnvironment.sandbox).payin(
    token: token,
    payinId: payinId,
    money: Money(amount: '1250.00', currencyCode: 'ZAR'), // the same amount and currency as the token
    returnUrl: 'https://shop.example.com/payment/return',
    callbackUrl: 'https://shop.example.com/synqt/callback',
  );

  final result = await payin.presentPaymentSheet(
    context,
    paymentMethodCode: 'CAPITEC_PAY',
    prefill: {'emailAddress': 'test@example.com'},
  );
  switch (result) {
    case null: break;                  // the payer closed the sheet without paying
    case InstructionsResult(): break;  // the sheet showed the next step; poll payin.status()
    case RedirectResult(:final url): break; // open url, see the README
  }
}
```

Only your backend's own `GET /payins/{id}` proves the payment. A complete app is in the [synqt-examples](https://github.com/synqt-pay/synqt-examples) repo, under `flutter/`.
