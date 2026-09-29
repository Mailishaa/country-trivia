import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:country_trivia/models/country.dart';
import 'package:country_trivia/services/country_service.dart';

void main() {
  group('CountryService', () {
    late CountryService service;

    setUp(() {
      service = CountryService();
    });

    group('fetchAllCountries', () {
      test('returns list of countries on 200 response', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            json.encode([
              {
                'name': {'common': 'United States'},
                'cca2': 'US',
              },
              {
                'name': {'common': 'France'},
                'cca2': 'FR',
              },
            ]),
            200,
          );
        });

        final serviceWithMock = CountryService(client: mockClient);
        final countries = await serviceWithMock.fetchAllCountries();

        expect(countries.length, 2);
        expect(countries[0].name, 'United States');
        expect(countries[0].isoCode, 'US');
        expect(countries[1].name, 'France');
        expect(countries[1].isoCode, 'FR');
      });

      test('throws exception on 500 error', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Server Error', 500);
        });

        final serviceWithMock = CountryService(client: mockClient);

        expect(
          () => serviceWithMock.fetchAllCountries(),
          throwsException,
        );
      });

      test('throws exception on 404 error', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Not Found', 404);
        });

        final serviceWithMock = CountryService(client: mockClient);

        expect(
          () => serviceWithMock.fetchAllCountries(),
          throwsException,
        );
      });

      test('throws exception on network error', () async {
        final mockClient = MockClient((request) async {
          throw Exception('Network error');
        });

        final serviceWithMock = CountryService(client: mockClient);

        expect(
          () => serviceWithMock.fetchAllCountries(),
          throwsException,
        );
      });

      test('returns empty list for empty array response', () async {
        final mockClient = MockClient((request) async {
          return http.Response(json.encode([]), 200);
        });

        final serviceWithMock = CountryService(client: mockClient);
        final countries = await serviceWithMock.fetchAllCountries();

        expect(countries, isEmpty);
      });

      test('throws on malformed JSON', () async {
        final mockClient = MockClient((request) async {
          return http.Response('not valid json', 200);
        });

        final serviceWithMock = CountryService(client: mockClient);

        expect(
          () => serviceWithMock.fetchAllCountries(),
          throwsA(isA<CountriesApiException>()),
        );
      });

      test('throws when 200 carries a deprecated-version error envelope', () async {
        // The live API answered 200 with this body after retiring v3.1, which
        // a bare status check would have treated as success.
        final mockClient = MockClient((request) async {
          return http.Response(
            json.encode({
              'success': false,
              'data': null,
              'errors': [
                {
                  'message':
                      'This API version has been deprecated. Please visit '
                      'https://restcountries.com/docs/countries/legacy-api-deprecation',
                },
              ],
            }),
            200,
          );
        });

        final serviceWithMock = CountryService(client: mockClient);

        expect(
          () => serviceWithMock.fetchAllCountries(),
          throwsA(
            isA<CountriesApiException>().having(
              (e) => e.message,
              'message',
              contains('deprecated'),
            ),
          ),
        );
      });

      test('throws when 200 body is an object that is not an error envelope',
          () async {
        final mockClient = MockClient((request) async {
          return http.Response(json.encode({'unexpected': 'shape'}), 200);
        });

        final serviceWithMock = CountryService(client: mockClient);

        expect(
          () => serviceWithMock.fetchAllCountries(),
          throwsA(isA<CountriesApiException>()),
        );
      });

      test('skips non-object entries instead of crashing', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            json.encode([
              'not-an-object',
              {'name': {'common': 'Ireland'}, 'cca2': 'IE'},
            ]),
            200,
          );
        });

        final serviceWithMock = CountryService(client: mockClient);
        final countries = await serviceWithMock.fetchAllCountries();

        expect(countries.length, 1);
        expect(countries.single.name, 'Ireland');
      });
    });

    group('generateQuestion', () {
      final pool = List.generate(
        10,
        (i) => Country(name: 'Country $i', isoCode: 'C$i'),
      );

      test('returns question with 4 options', () {
        final question = service.generateQuestion(pool);

        expect(question.options.length, 4);
      });

      test('includes correct answer in options', () {
        final question = service.generateQuestion(pool);

        expect(
          question.options
              .any((c) => c.isoCode == question.correctCountry.isoCode),
          isTrue,
        );
      });

      test('all options are unique', () {
        final question = service.generateQuestion(pool);
        final isoCodes = question.options.map((c) => c.isoCode).toSet();

        expect(isoCodes.length, 4);
      });

      test('throws ArgumentError for pool smaller than 4', () {
        final smallPool = pool.take(3).toList();

        expect(
          () => service.generateQuestion(smallPool),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError for empty pool', () {
        expect(
          () => service.generateQuestion([]),
          throwsArgumentError,
        );
      });

      test('works with pool of exactly 4', () {
        final exactPool = pool.take(4).toList();

        final question = service.generateQuestion(exactPool);

        expect(question.options.length, 4);
      });

      test('correct answer is from the pool', () {
        final question = service.generateQuestion(pool);

        expect(
          pool.any((c) => c.isoCode == question.correctCountry.isoCode),
          isTrue,
        );
      });

      test('correct answer appears exactly once across many runs', () {
        for (var i = 0; i < 50; i++) {
          final question = service.generateQuestion(pool);
          final correct = question.correctCountry;

          expect(
            question.options.where((c) => c.isoCode == correct.isoCode).length,
            1,
            reason: 'correct answer must appear exactly once',
          );
        }
      });

      test('minimal pool always yields all four countries', () {
        final exactPool = pool.take(4).toList();

        for (var i = 0; i < 20; i++) {
          final question = service.generateQuestion(exactPool);

          expect(
            question.options.map((c) => c.isoCode).toSet(),
            exactPool.map((c) => c.isoCode).toSet(),
          );
        }
      });

      test('eventually produces different correct answers', () {
        // Guards against the correct answer always being pool[0].
        final seen = <String>{};
        for (var i = 0; i < 200; i++) {
          seen.add(service.generateQuestion(pool).correctCountry.isoCode);
        }

        expect(seen.length, greaterThan(1));
      });
    });
  });
}
