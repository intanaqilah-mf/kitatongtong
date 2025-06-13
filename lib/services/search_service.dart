import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchService {

  static const String _endpoint =
      'https://us-central1-kita-tongtong.cloudfunctions.net/searchItems';
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
