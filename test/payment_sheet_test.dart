import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synqt/src/method_forms.dart';
import 'package:synqt/src/payment_sheet.dart';
import 'package:synqt/src/results.dart';
import 'package:synqt/synqt.dart';

// Set SYNQT_SHOTS to a folder to save a PNG of each screen, for checking the layout by eye.
final _shots = Platform.environment['SYNQT_SHOTS'];
final _frame = GlobalKey();

Future<void> _loadFonts() async {
  final font = FontLoader('packages/synqt/SynqtInstrumentSans');
  for (final weight in ['regular', 'medium', 'semibold']) {
    font.addFont(Future.value(ByteData.sublistView(File('fonts/synqt_instrument_sans_$weight.ttf').readAsBytesSync())));
  }
  await font.load();
}

Future<void> _shot(WidgetTester tester, String name) async {
  if (_shots == null) return;
  // flutter_svg draws off the test clock.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_frame));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_shots/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

/// Opens the sheet for [code] from a button, as an app would.
Future<Future<CreatePayinResult?>> _open(
  WidgetTester tester,
  String code, {
  Map<String, String> prefill = const {},
  List<PaymentOperator> operators = const [],
  Size size = const Size(1179, 2556),
  required Future<CreatePayinResult> Function(PaymentMethod) submit,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  late Future<CreatePayinResult?> result;
  await tester.pumpWidget(
    RepaintBoundary(
      key: _frame,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  final model = PaymentSheetModel(
                    form: methodForms.firstWhere((form) => form.code == code),
                    prefill: prefill,
                    operators: operators,
                    summary: const PaymentSummary(
                      amount: 'R1,250.00',
                      merchant: 'Test Shop',
                      method: 'x',
                      reference: 'order-1',
                    ),
                    submit: submit,
                  );
                  result = showPaymentSheet(context, model);
                },
                child: const Text('Checkout'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Checkout'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('a tablet shows the sheet as a centred card that a tap outside does not close', (tester) async {
    final result = await _open(
      tester,
      'CAPITEC_PAY',
      size: const Size(3072, 4098), // iPad Pro 12.9", 1024 wide
      submit: (_) => throw StateError('not sent'),
    );
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.getSize(find.descendant(of: find.byType(Dialog), matching: find.byType(Material)).first).width, 640);
    await _shot(tester, 'tablet');

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Your details'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    expect(await result, isNull);
    expect(find.byType(Dialog), findsNothing);
  });

  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';

    testWidgets('Capitec Pay form checks fields and switches tiles ($theme)', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final result = await _open(tester, 'CAPITEC_PAY', submit: (_) => throw StateError('not sent'));
      expect(find.text('Your details'), findsOneWidget);
      expect(find.text('Pay R1,250.00'), findsOneWidget);
      expect(find.text('Test Shop'), findsOneWidget);
      // No bank list from SYNQT, so the optional bank field is hidden.
      expect(find.text('Bank or provider (optional)'), findsNothing);
      await _shot(tester, 'capitec-$theme');

      await tester.tap(find.text('Pay R1,250.00'));
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsNWidgets(2)); // account number and last name
      await _shot(tester, 'capitec-errors-$theme');

      await tester.tap(find.text('Mobile number'));
      await tester.pumpAndSettle();
      expect(find.text('0821234567'), findsOneWidget); // the mobile number's placeholder
      expect(find.text('Account number'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(await result, isNull);
      expect(find.text('Your details'), findsNothing);
    });

    testWidgets('Pay offline shows how to pay once SYNQT accepts it ($theme)', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final accepted = parseCreatePayin(
        '''
        {"paymentMethodResponse":{"paymentMethodCode":"OFFLINE","reference":"REF123",
           "expireAt":"${DateTime.now().toUtc().add(const Duration(hours: 2)).toIso8601String()}",
           "account":{"accountName":"Test Payee","accountNumber":"0000000000","bankName":"Test Bank","bankCode":"000000"}}}''',
      );
      final reply = Completer<CreatePayinResult>();
      final result = await _open(
        tester,
        'OFFLINE',
        prefill: const {'customerName.firstName': 'Jane', 'customerName.lastName': 'Doe'},
        operators: const [PaymentOperator(code: 'ZA_TEST', name: 'Test Bank')],
        submit: (_) => reply.future,
      );
      expect(find.text('Bank or provider'), findsOneWidget);
      await _shot(tester, 'offline-form-$theme');

      await tester.tap(find.text('Choose one'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Bank').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pay R1,250.00'));
      await tester.pump(const Duration(milliseconds: 500)); // the loader animates, so no pumpAndSettle here
      expect(find.text('Processing your payment'), findsOneWidget);
      await _shot(tester, 'processing-$theme');
      reply.complete(accepted);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('How to pay'), findsOneWidget);
      expect(find.text('Test Payee'), findsOneWidget);
      expect(find.text('REF123'), findsOneWidget);
      expect(find.text('Before you pay'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^0[12]:\d\d:\d\d$')), findsOneWidget); // the countdown
      await _shot(tester, 'offline-next-$theme');

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(await result, same(accepted));
    });
  }

  testWidgets('everything prefilled pays straight away', (tester) async {
    var sent = 0;
    final result = await _open(
      tester,
      'ZAPPER_QR',
      prefill: const {
        'emailAddress': 'test@example.com',
        'customerName.firstName': 'Jane',
        'customerName.lastName': 'Doe',
      },
      submit: (_) async {
        sent++;
        return const RedirectResult(httpMethod: 'GET', url: 'https://bank.example.com');
      },
    );
    expect(sent, 1);
    expect(await result, const RedirectResult(httpMethod: 'GET', url: 'https://bank.example.com'));
  });
}
