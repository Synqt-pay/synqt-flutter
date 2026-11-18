/// For SYNQT's own add-ons, such as the card add-on (`synqt_card`). Apps never need it, and it may change in any
/// release. An add-on adds a payment method to the payment sheet with [addSheetMethod], and draws, checks and builds
/// that method's fields itself.
library;

export 'src/addon.dart' show MethodSection, MethodSectionException, SheetMethod, addSheetMethod;
export 'src/payin.dart' show SynqtAddonPayin;
export 'src/strings.dart' show text;
