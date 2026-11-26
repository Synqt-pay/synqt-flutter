import 'package:flutter/widgets.dart';

import 'method_forms.dart';
import 'payin_checkout.dart';
import 'results.dart';

/// A payment method an add-on adds to the payment sheet, registered with [addSheetMethod]. The sheet keeps its header,
/// summary, Pay button, processing state, general errors and next steps; the add-on draws, checks and builds only its
/// own fields, so what the payer types there never reaches the base SDK.
abstract interface class SheetMethod {
  /// The `paymentMethodCode`, such as `CARD`.
  String get code;

  /// The payer-facing name, in the phone's language.
  String get name;

  /// True covers the sheet while the app is not in front, so the app switcher's snapshot doesn't show this method's
  /// fields.
  bool get secure;

  /// The method's fields, for one sheet. [prefill] is the app's, as given to `PayinCheckout.presentPaymentSheet`. The section
  /// lives as long as the sheet, through light or dark, font size, language and rotation changes.
  MethodSection section(PayinCheckout checkout, Map<String, String> prefill);
}

/// One sheet's fields for a [SheetMethod].
abstract interface class MethodSection {
  /// Added to the sheet under "Your details". Called on every rebuild of the sheet, so return a widget with a stable
  /// type and key that keeps its own state.
  Widget build(BuildContext context);

  /// Checks every field when the payer taps Pay, shows each problem under its field and focuses the first. Returns
  /// what screen readers should say about each problem, such as "Card number: Check the card number"; empty if all
  /// pass.
  List<String> check();

  /// The `paymentMethod` object to send, built after [check] passed. Throw [MethodSectionException] with payer-facing
  /// text if it can't be built; the sheet shows it and sends nothing.
  Future<Map<String, Object?>> paymentMethod();

  /// Shows SYNQT's refusal under the field SYNQT names in [attr], and returns what screen readers should say about it,
  /// or null if no field here matches.
  String? showError(String attr, String message);

  /// Wipes what the payer typed. Called when the sheet closes.
  void clear();
}

/// A [MethodSection] could not build its request. [payerMessage] is shown in the sheet as it is.
final class MethodSectionException implements Exception {
  const MethodSectionException(this.payerMessage);

  final String payerMessage;

  @override
  String toString() => 'MethodSectionException: $payerMessage';
}

final _addons = <SheetMethod>[];

/// Adds an add-on's method, such as the card add-on's CARD, to the sheet and `Synqt.directPaymentMethods`. Once is
/// enough; adding it again replaces it. Throws [SynqtArgumentException] for a method the SDK already has.
void addSheetMethod(SheetMethod method) {
  if (methodForms.any((form) => form.code == method.code)) {
    throw SynqtArgumentException('${method.code} is already built in');
  }
  _addons
    ..removeWhere((registered) => registered.code == method.code)
    ..add(method);
}

/// The add-ons' methods, in the order they were added.
List<SheetMethod> get addonMethods => List.unmodifiable(_addons);
