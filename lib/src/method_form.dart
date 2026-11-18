import 'payment_methods.dart';
import 'results.dart';
import 'strings.dart';

/// How the payment sheet asks for a field. [paymentOperator] lists the banks or providers availablePaymentOptions
/// returns for the method; [provider] lists the external providers of those banks.
enum FieldKind { text, email, phone, number, choice, paymentOperator, provider }

/// Every provider of [operators], once each, whichever bank the payer picks.
List<ExternalProvider> providers(List<PaymentOperator> operators) {
  final seen = <String>{};
  return [
    for (final paymentOperator in operators)
      for (final provider in paymentOperator.externalProviders)
        if (seen.add(provider.code)) provider,
  ];
}

/// One payer-facing input for a text field of a payment method, keyed by its JSON path (e.g. `customerName.lastName`).
/// Text is held as string keys (l10n/form_strings_en.dart) so it can be translated.
final class FormInput {
  const FormInput(
    this.path,
    this.label,
    this.kind, {
    required this.required,
    this.hint,
    this.placeholder,
    this.section,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.invalid,
    this.options = const [],
  });

  final String path;
  final String label;
  final FieldKind kind;
  final bool required;
  final String? hint;

  /// Shown inside the empty field instead of [hint] under it: an example of what to type.
  final String? placeholder;

  /// Heading of the group this field sits in, such as "Bank account".
  final String? section;
  final int? minLength;
  final int? maxLength;

  /// From the spec; matched anywhere in the value, as JSON Schema does.
  final String? pattern;
  final String? invalid;

  /// [FieldKind.choice] values sent to SYNQT, with the label shown for each.
  final List<({String value, String label})> options;
}

/// One answer to a [OneOf] question. Once it is chosen its [required] paths must be filled in (none, for an optional
/// question); the rest are optional.
final class Choice {
  Choice(this.label, this.paths, {List<String>? required}) : required = required ?? paths.take(1).toList();

  final String label;
  final List<String> paths;
  final List<String> required;
}

/// The payer gives one of several details. The first choice is the default; the other choices' fields are hidden and
/// not sent.
final class OneOf {
  const OneOf(this.question, this.choices);

  final String question;
  final List<Choice> choices;
}

/// A direct API method's inputs and how they become the typed [PaymentMethod]. Instances are generated into
/// method_forms.dart.
final class MethodForm {
  const MethodForm(this.code, this.name, this.fields, {this.oneOfs = const [], required this.build});

  final String code;
  final String name;
  final List<FormInput> fields;
  final List<OneOf> oneOfs;

  /// Throws [SynqtArgumentException] naming the path of a missing required value.
  final PaymentMethod Function(FormValues) build;

  /// The first choice of each question, which the sheet starts with.
  List<Choice> get defaultChoices => [for (final oneOf in oneOfs) oneOf.choices[0]];

  /// Whether the field at [path] is shown, checked and sent while [chosen] (one per question, in order) is picked. A
  /// question with nothing chosen, as when [chosen] is empty, shows all its fields.
  bool shows(String path, List<Choice> chosen) {
    for (var index = 0; index < oneOfs.length && index < chosen.length; index++) {
      if (!chosen[index].paths.contains(path) && oneOfs[index].choices.any((choice) => choice.paths.contains(path))) {
        return false;
      }
    }
    return true;
  }

  bool _mustFill(String path, List<Choice> chosen) => chosen.any((choice) => choice.required.contains(path));

  /// Payer-facing problems with [values], by field path, found before anything is sent.
  List<PayinError> problems(Map<String, String> values, [List<Choice>? chosen]) {
    final choices = chosen ?? defaultChoices;
    return [
      for (final field in fields)
        if (shows(field.path, choices)) ?problem(field, values, mustFill: _mustFill(field.path, choices)),
    ];
  }

  /// Fields the sheet can leave out of view: those the app prefilled whose value is still in place and passes its
  /// checks. Once the first and last name are filled in, the name's optional extras (title, middle name, suffix) are
  /// left out too, so the whole name section goes. [values] are the form's current values, as read from the sheet.
  List<String> filledIn(Map<String, String> values, Map<String, String> prefill, List<Choice> chosen) {
    final filled = [
      for (final field in fields)
        if (!(values[field.path] ?? '').isBlank &&
            values[field.path] == prefill[field.path] &&
            problem(field, values, mustFill: _mustFill(field.path, chosen)) == null)
          field.path,
    ];
    final named = ['customerName.firstName', 'customerName.lastName'].every(filled.contains);
    final extras = !named
        ? const <String>[]
        : [
            for (final field in fields)
              if (field.path.startsWith('customerName.') &&
                  !filled.contains(field.path) &&
                  !field.required &&
                  (values[field.path] ?? '').isBlank)
                field.path,
          ];
    return [...filled, ...extras];
  }

  /// True when the payer has nothing left to give: the method has mandatory fields, every one shown for [chosen] is in
  /// [filledIn], and nothing fails its checks. Methods with only optional fields keep their form for the payer.
  bool readyToPay(Map<String, String> values, List<String> filledIn, List<Choice> chosen) {
    final mandatory = fields
        .where((field) => shows(field.path, chosen) && (field.required || _mustFill(field.path, chosen)))
        .toList();
    return mandatory.isNotEmpty &&
        mandatory.every((field) => filledIn.contains(field.path)) &&
        problems(values, chosen).isEmpty;
  }
}

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// The problem with one field, if any. [mustFill] is for the required fields of the chosen [Choice], which the spec
/// itself marks optional.
PayinError? problem(FormInput field, Map<String, String> values, {bool mustFill = false}) {
  final value = (values[field.path] ?? '').trim();
  final length = value.runes.length;
  final pattern = field.pattern;
  final malformed =
      value.isNotEmpty &&
      ((field.minLength != null && length < field.minLength!) ||
          (field.maxLength != null && length > field.maxLength!) ||
          (pattern != null && !RegExp(pattern, unicode: pattern.contains(r'\p')).hasMatch(value)) ||
          (field.kind == FieldKind.email && !_email.hasMatch(value)));
  if (value.isEmpty && (mustFill || field.required)) return PayinError(field.path, text('synqt_sheet_required'));
  if (malformed) return PayinError(field.path, text(field.invalid ?? 'synqt_sheet_check_field'));
  return null;
}

/// A problem to show the payer: the field it is about (a JSON path, or SYNQT's attrCode), if any, and what to say.
final class PayinError {
  const PayinError(this.attr, this.text);

  final String? attr;
  final String text;

  @override
  bool operator ==(Object other) => other is PayinError && other.attr == attr && other.text == text;

  @override
  int get hashCode => Object.hash(attr, text);

  @override
  String toString() => '${attr ?? '-'}=$text';
}

/// Form input by JSON path. Blank means not set, so optional fields are left out of the request.
final class FormValues {
  const FormValues(this.values);

  final Map<String, String> values;

  String? str(String path) {
    final value = values[path]?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  /// A required value; throws [SynqtArgumentException] with [path], so the sheet knows which input to mark.
  String req(String path) => str(path) ?? (throw SynqtArgumentException('$path is required', path: path));

  /// Builds an optional nested object only when at least one of its fields is filled in.
  T? group<T>(String prefix, T Function() build) =>
      values.entries.any((entry) => entry.key.startsWith('$prefix.') && !entry.value.isBlank) ? build() : null;
}

extension IsBlank on String {
  bool get isBlank => trim().isEmpty;
}
