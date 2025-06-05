import 'dart:convert';
import 'package:http/http.dart' as http;

/// A simple service that calls your `searchItems` Cloud Function.
/// Expects query `q=…` and returns a List of item‐maps:
///   {
///     "id": "...",
///     "item_code": "...",
///     "item_name": "...",
///     "normalized_item_name": "...",
///     "average_price": 9.80
///   }
///
/// Example usage:
///   final results = await SearchService.searchItems("beras");
///   print(results[0]['item_name']); // e.g. "BERAS CAP AYAM"
class SearchService {
  /// Replace <YOUR_PROJECT_ID> with exactly your Firebase project ID (i.e. "kita-tongtong").
  /// If you’re using a custom domain or Emulator, change this to the correct URL.
  static const String _endpoint =
      'https://us-central1-kita-tongtong.cloudfunctions.net/searchItems';

  /// Hits the Cloud Function with `?q=<query>`. If it succeeds, returns a List<Map>.
  static Future<List<Map<String, dynamic>>> searchItems(String query) async {
    final uri = Uri.parse(_endpoint).replace(queryParameters: {'q': query});
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final body = json.decode(resp.body) as Map<String, dynamic>;
      // body['items'] is expected to be a List<dynamic> of maps
      final itemsList = (body['items'] as List<dynamic>).cast<Map<String, dynamic>>();
      return itemsList;
    } else {
      throw Exception('Failed to search items. HTTP ${resp.statusCode}');
    }
  }
}
