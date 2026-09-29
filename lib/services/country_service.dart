import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/country.dart';
import '../models/question.dart';
import '../utils/constants.dart';

/// Service for fetching countries from the REST API and generating questions.
class CountryService {
  final http.Client _client;
  final Random _random;

  CountryService({
    http.Client? client,
    Random? random,
  })  : _client = client ?? http.Client(),
        _random = random ?? Random();

  /// Fetches all countries from the REST Countries API.
  ///
  /// Throws [Exception] on non-200 status codes or network errors.
  Future<List<Country>> fetchAllCountries() async {
    final response = await _client.get(
      Uri.parse(kCountriesApiUrl),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load countries: HTTP ${response.statusCode}',
      );
    }

    final List<dynamic> data = json.decode(response.body) as List<dynamic>;
    return data
        .map((e) => Country.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Generates a question from the given pool of countries.
  ///
  /// Picks one correct country and 3 random distractors, then shuffles.
  /// Throws [ArgumentError] if pool has fewer than 4 countries.
  Question generateQuestion(List<Country> pool) {
    if (pool.length < 4) {
      throw ArgumentError(
        'Pool must contain at least 4 countries, got ${pool.length}',
      );
    }

    final correct = pool[_random.nextInt(pool.length)];

    final distractors = pool
        .where((c) => c.isoCode != correct.isoCode)
        .toList()
      ..shuffle(_random);

    final options = [
      correct,
      ...distractors.take(3),
    ]..shuffle(_random);

    return Question(
      correctCountry: correct,
      options: options,
    );
  }
}
