## 0.3.0

- First public release of the SYNQT Flutter SDK, published on pub.dev as `synqt`. Import it with `package:synqt/synqt.dart`.
- Takes SYNQT payins (API version 2) on iOS and Android from one Dart codebase, through the direct API or the hosted Payment Web App.
- `IncomingPaymentsApi`, with the Carpentum Java SDK's payin calls and models: `payinAvailablePaymentOptions`, `createPayin(idPayin, payin)`, `getPayin`, `getPayinAccounts` and `setPayinExternalReference`, returning SYNQT's full `PayinAcceptedResponse` and `PayinDetail`. `PayinCheckout` (from `Synqt.checkout`) runs the payment sheet and the Payment Web App.
- A Synqt-branded payment sheet that asks the payer only for the details their payment method needs, checks them before anything is sent, and shows the next step (open the payment app, a QR code, or how to pay offline).
- Light and dark mode, screen reader support, and localisable payer-facing text.
- An add-on API (`package:synqt/addon.dart`) that SYNQT's card add-on uses to offer CARD to PCI DSS compliant merchants.
