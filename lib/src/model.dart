import 'dart:convert';

/// A request model: what it sends to SYNQT, and equality by that JSON.
abstract class SynqtModel {
  const SynqtModel();

  /// The JSON object SYNQT receives. Unset optional fields are left out.
  Map<String, Object?> toJson();

  @override
  bool operator ==(Object other) =>
      other is SynqtModel && other.runtimeType == runtimeType && jsonEncode(other.toJson()) == jsonEncode(toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;

  @override
  String toString() => '$runtimeType${jsonEncode(toJson())}';
}
