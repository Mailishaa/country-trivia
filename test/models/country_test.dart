import 'package:flutter_test/flutter_test.dart';
import 'package:country_trivia/models/country.dart';

void main() {
  group('Country', () {
    group('fromJson', () {
      test('parses valid JSON correctly', () {
        final json = {
          'name': {'common': 'United States'},
          'cca2': 'US',
        };

        final country = Country.fromJson(json);

        expect(country.name, 'United States');
        expect(country.isoCode, 'US');
      });

      test('handles missing name field', () {
        final json = {
          'cca2': 'US',
        };

        final country = Country.fromJson(json);

        expect(country.name, '');
        expect(country.isoCode, 'US');
      });

      test('handles missing cca2 field', () {
        final json = {
          'name': {'common': 'United States'},
        };

        final country = Country.fromJson(json);

        expect(country.name, 'United States');
        expect(country.isoCode, '');
      });

      test('handles null values', () {
        final json = {
          'name': null,
          'cca2': null,
        };

        final country = Country.fromJson(json);

        expect(country.name, '');
        expect(country.isoCode, '');
      });

      test('handles empty JSON', () {
        final json = <String, dynamic>{};

        final country = Country.fromJson(json);

        expect(country.name, '');
        expect(country.isoCode, '');
      });
    });

    group('flagUrl', () {
      test('returns correct URL with lowercase ISO code', () {
        const country = Country(name: 'United States', isoCode: 'US');

        expect(country.flagUrl, 'https://flagcdn.com/w320/us.png');
      });

      test('handles already lowercase ISO code', () {
        const country = Country(name: 'Germany', isoCode: 'DE');

        expect(country.flagUrl, 'https://flagcdn.com/w320/de.png');
      });

      test('handles mixed case ISO code', () {
        const country = Country(name: 'France', isoCode: 'Fr');

        expect(country.flagUrl, 'https://flagcdn.com/w320/fr.png');
      });
    });

    group('toJson', () {
      test('round-trips correctly', () {
        const country = Country(name: 'Japan', isoCode: 'JP');

        final json = country.toJson();
        final restored = Country.fromJson(json);

        expect(restored.name, country.name);
        expect(restored.isoCode, country.isoCode);
      });
    });

    group('fromJson flat shape', () {
      test('parses flat name and isoCode', () {
        final json = {
          'name': 'Brazil',
          'isoCode': 'BR',
        };

        final country = Country.fromJson(json);

        expect(country.name, 'Brazil');
        expect(country.isoCode, 'BR');
      });

      test('falls back to cca2 when isoCode is absent', () {
        final json = {
          'name': 'Chile',
          'cca2': 'CL',
        };

        final country = Country.fromJson(json);

        expect(country.name, 'Chile');
        expect(country.isoCode, 'CL');
      });

      test('handles flat shape with missing fields', () {
        final json = <String, dynamic>{};

        final country = Country.fromJson(json);

        expect(country.name, '');
        expect(country.isoCode, '');
      });
    });

    group('equality', () {
      test('same values are equal', () {
        const a = Country(name: 'US', isoCode: 'US');
        const b = Country(name: 'US', isoCode: 'US');

        expect(a, equals(b));
      });

      test('different values are not equal', () {
        const a = Country(name: 'US', isoCode: 'US');
        const b = Country(name: 'France', isoCode: 'FR');

        expect(a, isNot(equals(b)));
      });

      test('identical instance equals itself', () {
        const a = Country(name: 'US', isoCode: 'US');

        expect(a, equals(a));
      });

      test('equal instances share a hash code', () {
        const a = Country(name: 'US', isoCode: 'US');
        const b = Country(name: 'US', isoCode: 'US');

        expect(a.hashCode, b.hashCode);
      });

      test('is not equal to a different type', () {
        const a = Country(name: 'US', isoCode: 'US');

        expect(a, isNot(equals('US')));
      });
    });

    group('toString', () {
      test('includes name and isoCode', () {
        const country = Country(name: 'Italy', isoCode: 'IT');

        final result = country.toString();

        expect(result, contains('Italy'));
        expect(result, contains('IT'));
      });
    });
  });
}
