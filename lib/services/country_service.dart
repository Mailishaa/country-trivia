import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/country.dart';
import '../models/question.dart';
import '../utils/constants.dart';

/// Raised when the countries API cannot be used.
///
/// Carries a user-presentable [message] so the UI can show it directly.
class CountriesApiException implements Exception {
  final String message;

  const CountriesApiException(this.message);

  @override
  String toString() => 'CountriesApiException: $message';
}

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
  /// Throws [CountriesApiException] on non-200 status codes, network errors,
  /// or when the response body is not a JSON array of countries.
  ///
  /// The API can answer 200 with an error envelope (for example
  /// `{"success": false, "errors": [...]}`) when a version is retired, so a
  /// bare status check is not enough. See `kCountriesApiUrl` in constants.
  Future<List<Country>> fetchAllCountries() async {
    final http.Response response;
    try {
      response = await _client.get(Uri.parse(kCountriesApiUrl));
    } catch (e) {
      throw CountriesApiException('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw CountriesApiException(
        'Failed to load countries: HTTP ${response.statusCode}',
      );
    }

    final dynamic decoded;
    try {
      decoded = json.decode(response.body);
    } catch (e) {
      throw CountriesApiException('Malformed JSON response: $e');
    }

    // Guard against error envelopes that arrive with a 200 status.
    if (decoded is Map && decoded['success'] == false) {
      final errors = decoded['errors'];
      final message = errors is List && errors.isNotEmpty
          ? (errors.first is Map ? errors.first['message'] : errors.first)
          : 'unknown error';
      throw CountriesApiException('API returned an error: $message');
    }

    if (decoded is! List) {
      throw CountriesApiException(
        'Expected a JSON array of countries, got ${decoded.runtimeType}',
      );
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Country.fromJson)
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
