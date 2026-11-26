# SYNQT Flutter SDK

Take payments (SYNQT payins) in a Flutter app on iOS and Android. The SDK can show a Synqt-branded payment sheet that asks the payer for exactly the details their payment method needs, send the payment, and tell you what to do next. You don't build or maintain any payment forms.

It covers SYNQT API version 2 (spec 2.84): the direct API for all payment methods except CARD, and the hosted Payment Web App. CARD comes from a separate card add-on (`synqt_card`), available on request from SYNQT to PCI DSS compliant merchants. It is the Flutter counterpart of SYNQT's native iOS and Android SDKs: the same API, the same payment sheet, the same field rules and the same wording. One Dart codebase serves both platforms, so there is nothing to port per platform. Where it behaves differently from the native SDKs, [Differences from the native SDKs](#differences-from-the-native-sdks) lists every case.

## Requirements

- Flutter 3.38 or later (Dart 3.10). iOS 13 and Android 7.0 (API 24) or later, the minimums of `webview_flutter` and `url_launcher`. It has been run on iOS 27 and Android 17 only.
- A backend of your own that mints a SYNQT token for each order. The app never holds the merchant's private key or secret key.

Dependencies: `http`, `url_launcher`, `webview_flutter` and `flutter_svg`, all published by the Flutter team or its core maintainers.

## Integrating the SDK, step by step

Steps 1 and 2 happen once; steps 3 to 7 happen for every order.

### 1. Install the SDK

The SDK is published on pub.dev as `synqt`. Add it to your app:

```sh
flutter pub add synqt
```

or add it to your `pubspec.yaml` yourself and run `flutter pub get`:

```yaml
dependencies:
  synqt: ^0.3.0
```

To upgrade, run `flutter pub upgrade synqt`. The SDK brings its own fonts, strings and icons. On Android, make sure your app's main `AndroidManifest.xml` (not only the debug one) has `<uses-permission android:name="android.permission.INTERNET"/>`. Nothing goes in your iOS `Info.plist`.

Apps that ship the SDK must include the Phosphor Icons MIT notice and the Instrument Sans OFL notice in `THIRD_PARTY_NOTICES.md`, for example on an acknowledgements screen. Flutter's own `LicensePage` does not pick these up.

### 2. Add a token endpoint to your backend

This is the same for every SYNQT SDK. In short: your backend creates a payin ID that is new for this attempt (letters, digits, `_` and `-`, at most 250 characters), calls `POST /auth-tokens-by-action` with action `PAYIN_CREATE` and the order's `money`, signed with the merchant's private key in `X-SIGNATURE`, and returns the token, payin ID and amount to the app. The SYNQT examples repo's `scripts/sandbox-token.sh` is a working example of the signing. Never return a token with wildcard operations to an app.

### 3. Create the checkout in the app

```dart
import 'package:synqt/synqt.dart';

final synqt = Synqt(SynqtEnvironment.sandbox);
const money = MoneyPaymentRequested(amount: 1250.00, currencyCode: 'ZAR'); // the same amount and currency as the token
final checkout = synqt.checkout(
  token: response.token,
  payinId: response.payinId,
  money: money,
  returnUrl: 'https://shop.example.com/payment/return', // https, see "Other ways to pay"
  callbackUrl: 'https://shop.example.com/synqt/callback', // your backend, step 7
);
final api = IncomingPaymentsApi.create(synqt, response.token); // the API, for steps 4 and 6
```

This makes no network call. `checkout()` throws `SynqtArgumentException` if the payin ID is malformed or the `returnUrl` isn't https. The amount is a `num`, as SYNQT's spec types it; JSON carries it as a number, exact to 15 significant digits. Use `SynqtEnvironment.sandbox` while testing and `.live` for real payments.

### 4. Choose the payment method

```dart
final offered = (await api.payinAvailablePaymentOptions(const PaymentRequested(money: money))).data ?? [];
final supported = Synqt.directPaymentMethods.map((m) => m.code).toSet();
final choices = offered.where((o) => supported.contains(o.paymentMethodCode)).toList();
```

Show `choices` in your own checkout, using `option.name` as the payer-facing name. If your checkout only offers one method, skip this and pass its code, such as `'CAPITEC_PAY'`, in step 5.

### 5. Show the payment sheet

```dart
final accepted = await checkout.presentPaymentSheet(
  context,
  paymentMethodCode: methodCode,
  prefill: {
    'emailAddress': email,
    'customerName.firstName': firstName,
    'customerName.lastName': lastName,
  },
  onPresented: () { /* the sheet is on screen */ },
  onPaymentStarted: () { /* details sent to SYNQT: start showing progress, step 6 */ },
);
final redirect = accepted?.redirect();
if (accepted == null) {
  // the payer closed the sheet without paying
} else if (redirect != null) {
  // open redirect.url, see below
} else {
  // the sheet already showed the next step; go to step 6
}
```

Pass in `prefill` whatever your app already knows about the payer. The sheet hides those fields, and pays straight away when nothing mandatory is left to ask. See [The payment sheet](#the-payment-sheet).

The sheet returns SYNQT's `PayinAcceptedResponse`. When `redirect()` gives a `Redirection`, the payer finishes on a bank's page (or a card's 3-D Secure page). For `method` GET, open `url` with `url_launcher` or a web view. For POST, submit `redirect.formData()` to it as an HTML form, for example by loading a self-submitting form into a `WebViewController` with `loadHtmlString`.

To skip the sheet and use SYNQT's hosted Payment Web App instead, call `presentPaymentApp` here; see [Other ways to pay](#other-ways-to-pay).

### 6. Show the payer where the payment stands

Once `onPaymentStarted` has run (or the Payment Web App has opened), poll `api.getPayin(payinId)` every few seconds until it is final:

```dart
final detail = await api.getPayin(response.payinId);
switch (detail.process?.status) {
  case PaymentStatus.success:
    showPaid(); // fulfil only from step 7
  case PaymentStatus.failed || PaymentStatus.refused:
    showError(detail.process?.failureReasons?.payerMessage);
  default:
    break; // PROCESSING, or a status SYNQT adds later: keep polling
}
```

`detail.isFinal` says whether to stop. Stop polling when the payer leaves the screen too. Before the payment is created, `getPayin` throws `SynqtApiException` with HTTP 410.

### 7. Confirm the payment on your backend

SYNQT posts `{"idEntity":"order-1042-1"}` to your `callbackUrl` on every status change. Reply 200 at once, then call `GET /payins/order-1042-1` from your backend and fulfil the order only when `process.status` is `SUCCESS` and the amount matches. The callback carries no status and no signature, and the app's view of the status is not proof of payment.

### 8. Go live

Switch to `SynqtEnvironment.live` and your live merchant credentials, test one real payment per method you offer on both an iPhone and an Android phone, and work through [Security and compliance](#security-and-compliance).

## The payment sheet

`presentPaymentSheet` shows a modal bottom sheet with the same content and behaviour as the native SDKs' sheets, apart from the details listed under [What the payer sees](#what-the-payer-sees): the Synqt wordmark, an order summary (amount due, payment method, reference, and the merchant name if the token allows `GET /merchant-info`), one plain-language field per detail the method needs grouped into sections, the right keyboard for each field, checks on length and format before anything is sent, a menu of the banks or providers SYNQT returns for this payin, a Pay button with the amount, and a processing screen with the Synqt Orbit loader. The loader is drawn natively from the designer's Lottie file and holds still when the phone's animations are turned off.

Only the close button or the system back gesture closes the sheet, never a tap outside it or a swipe down, and neither works while a payment is being sent. Prefilled fields that pass their checks are hidden; when every mandatory field is prefilled, the sheet pays straight away. If SYNQT refuses a value, the form comes back with the error under that field. Screen readers announce every error as it appears.

For methods the payer finishes in another app (Zapper, SnapScan, UPI and others), the sheet stays open and shows the next step: an "Open Zapper" button, the QR code, the amount, the reference and a live countdown. The method's app opens by itself once if it is installed: the https link is opened only in a non-browser app (a universal link on iOS, an App Link on Android), then on the app's own URL scheme where one is known (SnapScan). If no app takes it, the button opens the link in the browser. For Pay offline the next step is "How to pay": the one-time reference, the bank account to transfer to with copy buttons, and the "Before you pay" notice.

The sheet follows the phone's light or dark setting, also when it changes while the sheet is open, even when the app forces a theme of its own. Text grows with the phone's text size, and at the largest sizes the summary and account details stack each label above its value.

What the app hears from the sheet, in order: `onPresented` once it is on screen (after the SDK has fetched the bank list and merchant name), `onPaymentStarted` each time details pass the sheet's checks and go to SYNQT, then the returned future completes once the sheet has closed: null if the payer closed it without paying, otherwise the result. Dart futures cannot be cancelled, so to close the sheet from code, pop its route; the future then completes with the accepted result, or null.

## Other ways to pay

**Call the API yourself.** `IncomingPaymentsApi` works like the Carpentum Java SDK's: one instance per token, `createPayin(idPayin, payin)` with the whole request, and SYNQT's full response back. Every method is a subclass of the sealed `PaymentMethodPayin`, named after the spec's schema (`CapitecPayMethod`, `ZapperQrMethod` and the rest), and its required fields are required parameters. Types several methods use, such as `Account` and `PersonName`, are shared, so `createPayin` checks the parts the method needs before sending and throws `SynqtArgumentException` naming the missing or unexpected field:

```dart
final accepted = await api.createPayin(
  response.payinId,
  const Payin(
    paymentRequested: PaymentRequested(money: money),
    paymentMethod: CapitecPayMethod(phoneNumber: '0821234567', customerName: PersonName(lastName: 'Doe')),
    returnUrl: 'https://shop.example.com/payment/return',
    callbackUrl: 'https://shop.example.com/synqt/callback',
  ),
);
final next = accepted.nextStep(); // the QR code, app link, amount, reference and expiry to show
```

Retrying `createPayin` after a network failure is safe: if SYNQT already has the payin, the SDK fetches it instead of creating another.

**Use SYNQT's hosted Payment Web App** when you don't want any payment UI in the app:

```dart
final result = await checkout.presentPaymentApp(context, merchantCode: 'MID',
    paymentMethodCode: 'CAPITEC_PAY',          // optional: open on this method
    prefill: {'phoneNumber': '+27821234567'}); // optional: the payer can still edit it
switch (result) {
  case PaymentAppReturned(:final url):
    break; // the Payment Web App sent the payer to returnUrl; url carries what it added
  case PaymentAppClosed():
    break; // the payer closed it first
}
final detail = await api.getPayin(response.payinId); // either way, ask where the payment stands
```

`presentPaymentApp` shows the Payment Web App full screen in a web view, with a Close button, and completes when the payer reaches `returnUrl` (same host and path, any query) or closes it. Back (on iOS, a swipe from the edge) steps back a page, and closes it from the first page. Links to bank and payment apps open outside it. To use the browser instead, `openPaymentApp(merchantCode:)` returns once the browser has the page; the payer then comes back through `returnUrl`, which must be a universal link (iOS) or verified App Link (Android) your app handles. `prefill` uses the Payment Web App's parameter names, not the sheet's field paths: `phoneNumber`, `emailAddress`, `accountName`, `accountNumber`, `upiId`, `idCustomer`, `governmentId`, `passportNumber`, `postalCode`, `city`, `district`.

## API reference

| Type or call | What it does |
|---|---|
| `Synqt(environment, client: = null)` | The entry point for one environment. Pass your own `http.Client` to control timeouts, proxies or pinning. |
| `SynqtEnvironment` | `.sandbox`, `.live` or `.stable` (SYNQT's internal platform, not for merchants), with `apiBaseUrl` and `paymentAppBaseUrl`. |
| `synqt.checkout(token:, payinId:, money:, returnUrl:, callbackUrl:)` | One order's `PayinCheckout`, for the sheet and the Payment Web App. `callbackUrl` is optional. Throws `SynqtArgumentException` for a malformed ID or a `returnUrl` that isn't https. |
| `MoneyPaymentRequested(amount:, currencyCode:)` | The amount to request, a `num` in major units. `format()` is the house format, such as `R1,250.00`. |
| `Synqt.directPaymentMethods` | The methods the sheet can collect details for, each with `code` and `name`. |
| `synqt.paymentOperators(token:)` | `List<PaymentOperatorIncoming>`: every bank and provider SYNQT knows, each with its `externalProviders`. Needs a token with `GET /payment-operators`, which `PAYIN_CREATE` tokens lack. |
| `checkout.presentPaymentSheet(context, paymentMethodCode:, prefill:, customerIp:, onPresented:, onPaymentStarted:)` | The Synqt payment sheet. Completes with `PayinAcceptedResponse?` (null when the payer closes the sheet). |
| `checkout.presentPaymentApp(context, merchantCode:, paymentMethodCode:, prefill:, extra:, onPresented:)` | The Payment Web App in a full-screen web view. Completes with `PaymentAppReturned` or `PaymentAppClosed`. |
| `checkout.openPaymentApp(...)`, `checkout.paymentAppUrl(...)` | The Payment Web App in the browser, or its URL for a web view of your own. |
| `IncomingPaymentsApi.create(synqt, accessToken)` | The payin API for one token. |
| `api.payinAvailablePaymentOptions(paymentRequested)` | `AvailablePayinOptionList`: per method in `data`, its `paymentMethodCode`, `paymentOperators`, `segmentCode` and `name` (null for methods the sheet doesn't support). |
| `api.createPayin(idPayin, payin)` | Your own UI: send a `Payin` with a `PaymentMethodPayin` you built. Returns `PayinAcceptedResponse`: `PayinAcceptedMethodResponse` (`paymentRequested`, `paymentMethodResponse`) or `PayinAcceptedRedirectResponse` (`paymentRequested`, `redirectTo`). `nextStep()` and `redirect()` read the common parts. |
| `api.getPayin(idPayin)` | `PayinDetail`: `paymentRequested`, `process` (`status`, `failureReasons`, `isTest`, times), `fee`, `paymentMethodResponse`, `settlement`, `customer`. `isFinal` says whether the status can still change. Show the payer `failureReasons.payerMessage`; SYNQT's own `message` is written for the merchant. |
| `api.getPayinAccounts(idPayin)` | `PaymentAccountDetail`: the payer's account as entered and as the payment used it. |
| `api.setPayinExternalReference(idPayin, reference)` | Sends the payer's bank or UTR reference, for methods that need it. |
| `NextStep` | What the payer does next: `appLink`, `qrCodeImageUrl`, `qrCodeData`, `amountToPay`, `reference`, `expiresAt` and `payInto`. Every `PaymentMethodResponsePayin` gives one with `nextStep()`. |
| `Redirection` | Where to send the payer: `method` (GET or POST), `url`, and `formData()` for a POST. |
| `PaymentStatus` | The four known statuses as constants: `processing`, `success`, `failed`, `refused`. |
| `SynqtApiException` | SYNQT refused the request: `httpCode` and `errors` (`code`, `field`, `description`). Never contains the raw response, because SYNQT echoes what the payer typed in it. |
| `SynqtArgumentException` | Something the app passed can't be sent: `message`, and `path` naming the field. |
| `http.ClientException`, `TimeoutException` | Network failures. A call times out if the response hasn't started within 30 seconds. |

Statuses and codes are strings, so a value SYNQT adds later never breaks parsing. A payment method this SDK version doesn't know yet, or a response that doesn't fit its model, reads as `UnknownPaymentMethodResponsePayin` with its `json` rather than failing, so a payin SYNQT has created never surfaces as an error; its `nextStep()` still reads the fields every method uses. A payin ID can be used once: calling `createPayin` again with the same ID and method is a safe retry, but with another method it throws HTTP 409 `PAYIN_ALREADY_STARTED`, and the sheet tells the payer to start a new payment.

## Coming from the Carpentum Java SDK

The API calls and models match the Java SDK's, with Dart's own idioms: classes with named parameters instead of builders, nullable fields instead of `Optional`, and futures.

| Java SDK | This SDK |
|---|---|
| `IncomingPaymentsApi.create(context, token)` | `IncomingPaymentsApi.create(Synqt(environment), token)` (the token comes from your backend; there is no `PaymentContext` or secret in an app) |
| `payinAvailablePaymentOptions(PaymentRequested)` | the same, returning `AvailablePayinOptionList` |
| `createPayin(idPayin, Payin)` | the same, returning `PayinAcceptedResponse` |
| `getPayin(idPayin)`, `getPayinAccounts(idPayin)` | the same, returning `PayinDetail` and `PaymentAccountDetail` |
| `setPayinExternalReference(idPayin, reference)` | the same |
| `CapitecPayMethod.builder()...build()` | `CapitecPayMethod(...)` |
| `AccountPayinRequestCapitecPay`, `PersonNameOffline` and other per-method variants | one shared `Account` and `PersonName`, checked per method |
| `ResponseException` and its subclasses | `SynqtApiException` (`httpCode`, `errors`), `SynqtArgumentException`, and `http.ClientException` or `TimeoutException` |

Unlike the Java SDK, this SDK checks lengths and formats before sending, retries a payin it already created after a 409, and parses a payment method it doesn't know as `UnknownPaymentMethodResponsePayin` instead of failing.

**Match your own screens (optional).** The sheet's building blocks are public: `SynqtCard`, `SynqtTextField` (with a `SynqtKeyboard`), `SynqtDropdown`, `SynqtButton` (`SynqtButtonKind.primary`, `.accent`, `.outline`), `SynqtErrorBanner`, `SynqtLogo`, `SynqtIconView`, the colour tokens `SynqtColors` (`SynqtColors.of(context)`, `.light`, `.dark`, `.magenta`, `.aqua`) and `synqtFont(size, weight:)` for Instrument Sans.

## Translations

Every piece of text the SDK shows a payer is a translated string keyed by the Android SDK's resource names, so one translation serves all three SDKs:

- `lib/src/l10n/sheet_strings_en.dart`: the sheet's own text (headings, buttons, next-step, error and failure messages), generated too, with the same wording in every SYNQT SDK.
- `lib/src/l10n/form_strings_en.dart`: method names, field labels, hints, validation messages and tile questions, generated with the code that uses it (see below).

To add a language, copy both files to `<language>` versions (for example `sheet_strings_af.dart`), translate the text keeping the keys and the `%1$s` and `%1$d` placeholders, and list them in `lib/src/strings.dart`. The sheet follows the phone's language; a string with no translation falls back to English. SYNQT's own error descriptions and bank or provider names stay in English, as they come from SYNQT's servers.

## Security and compliance

- Never put the merchant's private key or secret key in an app. Tokens come from your backend, one per order, locked to the amount.
- Only your backend's own status check proves a payment. The return URL, the sheet closing and `api.getPayin()` in the app do not.
- This SDK has no card code. CARD is offered only with the separate card add-on, for PCI DSS compliant merchants, which draws, checks and encrypts the card fields itself. The generated `CardMethod` has no raw card number field. The add-on uses this SDK's add-on API (`package:synqt/addon.dart`), which apps never need.
- Payment details include personal information (ID numbers, account numbers, phone numbers, emails) covered by POPIA. Don't log requests, responses or `SynqtApiException` descriptions alongside customer data.
- The iOS SDK ships an Apple privacy manifest. A Flutter package cannot add one to the host app, so apps using this SDK on iOS must declare the same data types in their own `PrivacyInfo.xcprivacy`: copy the categories from the iOS SDK's `Sources/SynqtSDK/Resources/PrivacyInfo.xcprivacy`. The same applies to the Google Play data safety form.

## Differences from the native SDKs

The SYNQT calls, the payment methods and their fields, the field rules, the wording, the sheet's screens and the next steps are the same in all three SDKs. Everything that differs is listed here.

### What the app calls

| | iOS | Android | Flutter |
|---|---|---|---|
| Amount type | `Decimal` | `BigDecimal` | `num`, as the spec's number type, exact to 15 significant digits |
| When a hand-built `PaymentMethodPayin` is checked | At `createPayin`, `SynqtArgumentError` | When you construct it, `IllegalArgumentException` | At `createPayin`, `SynqtArgumentException` |
| SYNQT refused the request | `SynqtAPIError` | `SynqtException`, an `IOException`, so `catch (e: IOException)` catches it too | `SynqtApiException`, not an `http.ClientException`, so catch both |
| Network failure | `URLError` | `IOException` | `http.ClientException`, or `TimeoutException` |
| Timeout | 30 s per request | 15 s to connect, 30 s to read | 30 s until the response starts. The body is then read with no time limit of the SDK's own |
| Your own HTTP stack | `URLSession` | Not replaceable | `http.Client` |
| Payer-facing names and failure messages | `name`, `payerMessage` | `name(context)`, `payerMessage(context)` | `name`, `payerMessage`, getters with no context |
| Payment Web App options | `paymentMethodCode`, `prefill` and `extra` | `extra` only, so you add `optionsAvailable` and `allowCustomerDataChange` yourself | As iOS |
| Payment Web App link | Amount without trailing zeros (`1250`), a space as `%20`, and an `extra` key repeated after a built-in one of the same name | Amount as given (`1250.00`), a space as `+`, and an `extra` key replaces a built-in one | As iOS |
| Spotting the return URL | When the web view asks to load it | When the web view asks to load it | Also when the page's URL changes without a load request, as some platforms don't ask about every navigation |
| `intent:` links in the Payment Web App | Not used on iOS | Opened as the intent, in the app it names | Opened as the link it stands for (`intent://pay#Intent;scheme=upi;end` opens `upi://pay`) in any app that claims that scheme. The named app and extras are dropped, and a link with no scheme does nothing |
| Comparing results | `Equatable` | Data classes | No `==`: compare the fields |
| When `onPresented` runs | After the slide-in | When the dialog shows. With every field prefilled, `onPaymentStarted` runs first | After the first frame, while the sheet slides in |
| `openPaymentApp` returns | Whether Safari opened it | Nothing | Whether the browser opened it |
| Closing the sheet or Payment Web App from code | Cancel the `Task`. The call returns nil (or `.closed`), even if SYNQT already accepted the payment | Cancel the coroutine | Dart futures can't be cancelled, so pop the route. The future completes with the accepted result if there is one, else null (or `PaymentAppClosed`) |

### What the payer sees

| | iOS | Android | Flutter |
|---|---|---|---|
| Sheet frame | The system form sheet, with a grabber | 24dp corners, a drag handle on phones, at most 92% of the screen high, 60% dim behind | 16 corners, no handle, as high as the status bar allows, Material's dim behind. On a tablet (600 or wider on the shorter side), a centred card 640 wide, as on Android |
| Largest text sizes | Summary and account rows stack each label above its value. Icons grow with the text | Rows stay side by side. Icons stay the same size | As iOS. Rows stack from 1.6 times the normal size |
| Light or dark changing while the sheet is open | Followed live from iOS 17. On iOS 15 and 16, only when the app becomes active again | Followed live | Followed live |
| Errors and screen readers | Every error is announced, and so is the "copied" message | Field errors are announced. The error banner (errors not tied to a field) is not | Every error is announced, and so is the "copied" message |
| Closing the sheet | Close button only | Close button or Back | As the native sheets: close button only on iOS, close button or Back on Android. Never a tap outside or a swipe down, and not while a payment is being sent |
| Back in the Payment Web App | Close button only | Back steps back through its pages, and closes it from the first page | As Android. On iOS, a swipe from the edge also steps back a page |
| Opening the method's app (Zapper, SnapScan) | A universal link, then the app's own URL scheme | Opens the link in the Zapper or SnapScan package if it is installed, then tries the QR data. Other methods' apps (UPI and the like) do not open by themselves. The SDK's manifest declares both packages | Opens the https link in any installed app that claims it rather than a browser (an App Link on Android, a universal link on iOS), then tries the app's own URL scheme. Nothing goes in your manifest |
| Copy confirmation | The SDK's own "copied" message | Android's own confirmation from Android 13, the SDK's message below 13 | The SDK's own message on both, so Android 13 and later shows two |
| Font | Instrument Sans | Instrument Sans from Android 8.0, the system font below | Instrument Sans on every version |
| Language | The phone's language, through `.lproj` files | The app's language, through string resources (per-app language settings apply) | The phone's language, read from the system. It ignores the `locale` your `MaterialApp` sets |

### What the host app looks after

| | iOS | Android | Flutter |
|---|---|---|---|
| Lifecycle | A modal view controller | The sheet and Payment Web App are SDK activities that keep their state through rotation, appearance, font size and language changes | Routes on your app's navigator. They keep their state through rotation and appearance changes, because Flutter's activity template handles those itself (keep its `configChanges`). If Android stops the app while the payer is in another app, the app restarts without the sheet and the future never completes, so check `api.getPayin(payinId)` when your app starts again |
| Permissions and package visibility | None | Declared in the SDK's manifest | Add `INTERNET` to your app's main `AndroidManifest.xml` |
| Privacy declarations | Ships `PrivacyInfo.xcprivacy` | Google Play data safety form, filled in by the app | A Flutter package can't add a privacy manifest. Declare the same categories in your own `PrivacyInfo.xcprivacy` and on the Play data safety form |
| Third-party code in your app | None | AndroidX Annotation and kotlinx-coroutines | `http`, `url_launcher`, `webview_flutter` and `flutter_svg`, and their platform plugins |
| Adding a language | Add `.lproj` files | Add `values-<language>` folders | Add two Dart files and list them in `lib/src/strings.dart`, which is a code change |
| Building blocks for your own screens | SwiftUI views | `SynqtUI` view factories | Flutter widgets, plus `SynqtLogo` and `SynqtIconView` |

## Generated code and the SYNQT API version

The payin models (`lib/src/payin_models.dart`: `Payin`, `PayinAcceptedResponse`, `PayinDetail` and the rest, named as in SYNQT's spec and the Carpentum Java SDK), the payment method models (`lib/src/payment_methods.dart`), the sheet's fields (`lib/src/method_forms.dart`), all of the sheet's text (`lib/src/l10n/form_strings_en.dart` and `sheet_strings_en.dart`), the colours (`lib/src/ui/colors.dart`) and the shared field test cases (`test/field_cases_test.dart`) are generated from SYNQT's OpenAPI spec and SYNQT's shared tables. CARD's raw card number fields are left out of this SDK, as they put the app in PCI DSS scope; only the card add-on has them.

They are generated from SYNQT API 2.84 today, and the spec lives with the generator app. A new SYNQT API version replaces the generated files in one commit, and every SYNQT SDK moves to the same version together, so they all ask payers for the same things in the same words.

Dart has no nested types, so where the other SDKs say `PaymentMethodPayin.Account` or `PaymentMethodResponsePayin.Account`, this one says `Account` and `AccountResponse`, and `PaymentMethodResponsePayin.Unknown` is `UnknownPaymentMethodResponsePayin`.

The Android README describes the South African mandatory fields, the "at least one of" tiles and the ID or passport question.

## Tests

`test/` covers the models, the forms and their SA rules, parsing, error wording, the sheet's behaviour, the loader's keyframes, and the HTTP calls against a mock client. They are the iOS suite's tests, ported. Run them with `flutter test`.

## Running the example app

The example app lives in the [synqt-examples](https://github.com/synqt-pay/synqt-examples) repo, under `flutter/`. By default it uses the released package; to try changes in this checkout, clone that repo next to this one and switch it to local mode (its README has the steps).

## Licence

The SDK is licensed under the Apache License, Version 2.0: see `LICENSE` and `NOTICE`. It bundles the Instrument Sans typeface (SIL Open Font License 1.1) and Phosphor icons (MIT); their notices are in `THIRD_PARTY_NOTICES.md`, and `fonts/InstrumentSans-OFL.txt` has the font licence in full.

## Status

Built with Flutter 3.47.9 (Dart 3.13.7): `flutter analyze` reports no issues and the test suite passes (62 tests, including widget tests that open the sheet in light and dark, check and refuse fields, switch tiles, and walk the Pay offline next step). The generated models, form fields and English strings match the iOS SDK's output exactly. The demo builds as a debug APK and for the iOS Simulator, and launches on the iPhone 18 Pro simulator (iOS 27) and an Android 17 emulator. Set `SYNQT_SHOTS` to a folder when running `flutter test test/payment_sheet_test.dart` to save a PNG of each sheet screen.
