/// For SYNQT's own add-ons, such as the card add-on (`synqt_card`). Apps never need it, and it may change in any
/// release. An add-on adds a payment method to the payment sheet with [addSheetMethod], and draws, checks and builds
/// that method's fields itself.
library;

export 'src/addon.dart' show MethodSection, MethodSectionException, SheetMethod, addSheetMethod;
export 'src/incoming_payments_api.dart' show SynqtAddonApi;
export 'src/payin_checkout.dart' show SynqtAddonCheckout;
export 'src/payment_methods.dart' show AddonPaymentMethod;
export 'src/strings.dart' show text;
