import '../utils/constants.dart';

/// Represents a country with its name and ISO code.
class Country {
  /// Common name of the country (e.g. "United States").
  final String name;

  /// ISO 3166-1 alpha-2 code (e.g. "US").
  final String isoCode;

  const Country({
    required this.name,
    required this.isoCode,
  });

  /// URL for the country's flag image from flagcdn.com.
  String get flagUrl =>
      kFlagUrlPattern.replaceAll('{iso}', isoCode.toLowerCase());

  /// Creates a [Country] from a JSON object.
  ///
  /// Accepts both the REST Countries API v3.1 shape
  /// (`{'name': {'common': ...}, 'cca2': ...}`) and the flat shape produced
  /// by [toJson] (`{'name': ..., 'isoCode': ...}`).
  factory Country.fromJson(Map<String, dynamic> json) {
    final nameField = json['name'];

    // REST Countries API shape: name is a nested map.
    if (nameField is Map<String, dynamic>) {
      return Country(
        name: nameField['common'] as String? ?? '',
        isoCode: json['cca2'] as String? ?? '',
      );
    }

    // Flat shape produced by toJson.
    return Country(
      name: nameField as String? ?? '',
      isoCode: json['isoCode'] as String? ?? json['cca2'] as String? ?? '',
    );
  }

  /// Converts this [Country] to a JSON map.
  Map<String, dynamic> toJson() => {
        'name': name,
        'isoCode': isoCode,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          isoCode == other.isoCode;

  @override
  int get hashCode => name.hashCode ^ isoCode.hashCode;

  @override
  String toString() => 'Country(name: $name, isoCode: $isoCode)';
}
