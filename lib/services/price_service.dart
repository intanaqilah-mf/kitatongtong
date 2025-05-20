import 'package:http/http.dart' as http;

class PriceService {
  /// Fetch the first RMxx.xx on whatever page [url] points to.
  /// Throws if it can’t find a price.
  static Future<double> fetchPriceFromUrl(String url) async {
    final uri = Uri.parse(url);
    final resp = await http.get(uri, headers: {
      'User-Agent': 'Mozilla/5.0'
    });
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch $url: HTTP ${resp.statusCode}');
    }

    // look for RM12.34 or RM 12.34
    final regex = RegExp(r'RM\s*([\d]+\.\d{1,2})');
    final match = regex.firstMatch(resp.body);
    if (match == null) {
      throw Exception('Price not found on page: $url');
    }
    return double.parse(match.group(1)!);
  }

  /// items: List of { "url": String, "number": int }
  static Future<double> fetchExpectedTotalFromUrls(
      List<Map<String, dynamic>> items) async {
    double total = 0;
    for (final item in items) {
      final url = item['url'] as String;
      final qty = item['number'] as int;
      final price = await fetchPriceFromUrl(url);
      total += price * qty;
    }
    return total;
  }
}
