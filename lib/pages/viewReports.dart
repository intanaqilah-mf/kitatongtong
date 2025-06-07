import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:math';
import 'package:projects/config/app_config.dart';

// The main screen for displaying reports and the chatbot
class ViewReportsScreen extends StatefulWidget {
  @override
  _ViewReportsScreenState createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> {
  // State for chatbot
  bool _isChatbotOpen = false;
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatHistory = [];
  bool _isChatLoading = false;

  // State for data and charts
  bool _isDataLoading = true;
  Map<String, dynamic> _allData = {};

  final String _apiKey = AppConfig.getGeminiAPIKey();

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  // Fetch data from all collections in Firestore
  Future<void> _fetchAllData() async {
    setState(() { _isDataLoading = true; });

    final firestore = FirebaseFirestore.instance;
    // Note: Ensure your collection name is 'donations' (plural). If it is 'donation', change it here.
    final collections = [
      'applications', 'donation', 'users',
      'redeemedKasih', 'package_kasih', 'notifications'
    ];

    Map<String, dynamic> data = {};
    for (String col in collections) {
      final snapshot = await firestore.collection(col).get();
      print("Fetched ${snapshot.docs.length} documents from '$col'");
      data[col] = snapshot.docs.map((doc) => doc.data()).toList();
    }

    setState(() {
      _allData = data;
      _isDataLoading = false;
    });
  }

  // Helper to make Firestore data encodable for Gemini
  Map<String, dynamic> _makeDataJsonEncodable(Map<String, dynamic> data) {
    final Map<String, dynamic> encodableData = {};
    data.forEach((key, value) {
      if (value is List) {
        encodableData[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _makeDataJsonEncodable(item);
          }
          return item;
        }).toList();
      } else if (value is Map<String, dynamic>) {
        encodableData[key] = _makeDataJsonEncodable(value);
      } else if (value is Timestamp) {
        encodableData[key] = value.toDate().toIso8601String();
      } else {
        encodableData[key] = value;
      }
    });
    return encodableData;
  }

  void _toggleChatbot() {
    setState(() {
      _isChatbotOpen = !_isChatbotOpen;
    });
  }

  // --- GEMINI CHATBOT LOGIC ---
  Future<void> _sendMessageToGemini() async {
    if (_chatController.text.isEmpty) return;

    final userMessage = _chatController.text;
    setState(() {
      _isChatLoading = true;
      _chatHistory.add({'role': 'user', 'text': userMessage});
      _chatController.clear();
    });

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);

      // Convert data to be JSON-safe before encoding
      final encodableData = _makeDataJsonEncodable(Map<String, dynamic>.from(_allData));

      final prompt = """
      You are a helpful business intelligence assistant for a charity management app.
      Analyze the following JSON data from our database and answer the user's question.
      Provide concise and insightful answers. Do not just repeat the data; interpret it.
      
      Here is the data:
      ${jsonEncode(encodableData)}

      User's question: "$userMessage"
      """;

      final response = await model.generateContent([Content.text(prompt)]);

      setState(() {
        _chatHistory.add({'role': 'model', 'text': response.text ?? "Sorry, I couldn't get a response."});
        _isChatLoading = false;
      });
    } catch (e) {
      setState(() {
        _chatHistory.add({'role': 'model', 'text': 'Error: ${e.toString()}'});
        _isChatLoading = false;
      });
      print("Gemini Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF3F3F3F),
      body: Stack(
        children: [
          _isDataLoading
              ? Center(child: CircularProgressIndicator(color: Color(0xFFF1D789)))
              : SingleChildScrollView(
            padding: EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Dashboard Reports", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 24),
                _buildPostcodeRegionChart(),
                SizedBox(height: 24),
                _buildDonationsChart(),
                SizedBox(height: 24),
                _buildUserRolesChart(),
                SizedBox(height: 24),
                _buildRedeemedPackagesChart(),
              ],
            ),
          ),
          _buildChatbot(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleChatbot,
        child: Icon(_isChatbotOpen ? Icons.close : Icons.chat_bubble),
        backgroundColor: Color(0xFFF1D789),
        foregroundColor: Color(0xFF3F3F3F),
      ),
    );
  }

  // --- WIDGETS FOR CHARTS ---

  // Postcode to Region Chart
  Widget _buildPostcodeRegionChart() {
    final applications = _allData['applications'] as List<dynamic>;
    if (applications.isEmpty) return _buildChartContainer(title: "Applicants by Region", chart: _noDataWidget());

    Map<String, int> regionCounts = {};
    for (var app in applications) {
      final postcode = app['postcode']?.toString();
      if (postcode != null) {
        final region = _getRegionFromPostcode(postcode);
        regionCounts[region] = (regionCounts[region] ?? 0) + 1;
      }
    }

    final List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
    int colorIndex = 0;

    return _buildChartContainer(
      title: "Applicants by Region",
      chart: PieChart(
        PieChartData(
          sections: regionCounts.entries.map((entry) {
            final color = colors[colorIndex % colors.length];
            colorIndex++;
            return PieChartSectionData(
              color: color,
              value: entry.value.toDouble(),
              title: '${entry.key}\n(${entry.value})',
              radius: 80,
              titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              titlePositionPercentageOffset: 0.55,
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  String _getRegionFromPostcode(String postcode) {
    const Map<String, String> regionMap = {
      '08000': 'Sg. Petani',
      '08010': 'Sg. Petani',
      '09000': 'Kulim',
      '09400': 'Padang Serai',
      '05000': 'Alor Setar',
      '05050': 'Alor Setar',
      '05100': 'Alor Setar',
      '06000': 'Jitra',
      '07000': 'Langkawi',
    };
    return regionMap[postcode] ?? 'Other';
  }

  // Donations Chart with corrected field names
  Widget _buildDonationsChart() {
    final donations = _allData['donation'] as List<dynamic>;
    if (donations.isEmpty) return _buildChartContainer(title: "Monthly Donations (RM)", chart: _noDataWidget());

    Map<String, double> monthlyTotals = {};
    for (var donation in donations) {
      // CORRECTED: Using 'createdAt' and 'amount' to match your likely Firestore structure.
      if (donation['timestamp'] == null || donation['timestamp'] is! Timestamp) {
        print("Skipping donation due to missing or invalid 'createdAt' field: $donation");
        continue;
      }
      if (donation['amount'] == null || donation['amount'] is! num) {
        print("Skipping donation due to missing or invalid 'amount' field: $donation");
        continue;
      }

      Timestamp timestamp = donation['timestamp'];
      DateTime date = timestamp.toDate();
      String month = DateFormat('yyyy-MM').format(date);
      double amount = (donation['amount'] as num).toDouble();
      monthlyTotals[month] = (monthlyTotals[month] ?? 0) + amount;
    }

    if (monthlyTotals.isEmpty) {
      print("Donation chart has no data to plot after processing. Check the logs above for reasons.");
      return _buildChartContainer(title: "Monthly Donations (RM)", chart: _noDataWidget());
    }

    var sortedEntries = monthlyTotals.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    double maxValue = sortedEntries.map((e) => e.value).reduce(max);

    return _buildChartContainer(
      title: "Monthly Donations (RM)",
      chart: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,
          barGroups: sortedEntries.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [BarChartRodData(
                toY: entry.value.value,
                color: Color(0xFFF1D789),
                width: 16,
                borderRadius: BorderRadius.zero,
              )],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) {
              if (value == meta.max) return Container();
              return Text('${(value/1000).toStringAsFixed(0)}k', style: TextStyle(color: Colors.grey, fontSize: 10));
            })),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
              String monthLabel = DateFormat('MMM').format(DateTime.parse('${sortedEntries[value.toInt()].key}-01'));
              return Text(monthLabel, style: TextStyle(color: Colors.grey, fontSize: 10));
            }, reservedSize: 22)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true, checkToShowHorizontalLine: (value) => value % 500 == 0, horizontalInterval: 500),
        ),
      ),
    );
  }

  // Redeemed Packages Chart
  Widget _buildRedeemedPackagesChart() {
    final redeemed = _allData['redeemedKasih'] as List<dynamic>;
    if (redeemed.isEmpty) return _buildChartContainer(title: "Redeemed Packages", chart: _noDataWidget());

    Map<String, int> packageCounts = {};
    for (var item in redeemed) {
      String name = item['packageName'] ?? 'Unknown';
      packageCounts[name] = (packageCounts[name] ?? 0) + 1;
    }

    return _buildChartContainer(
      title: "Redeemed Packages",
      chart: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: packageCounts.entries.toList().asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [BarChartRodData(
                toY: entry.value.value.toDouble(),
                color: Colors.teal,
                width: 20,
                borderRadius: BorderRadius.zero,
              )],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 5)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
              final text = packageCounts.keys.elementAt(value.toInt());
              return Text(text, style: TextStyle(color: Colors.grey, fontSize: 10));
            }, interval: 1, reservedSize: 30)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
        ),
      ),
    );
  }

  // User Roles Chart
  Widget _buildUserRolesChart() {
    final users = _allData['users'] as List<dynamic>;
    if (users.isEmpty) return _buildChartContainer(title: "User Roles", chart: _noDataWidget());

    Map<String, int> roleCounts = {};
    for (var user in users) {
      String role = user['role'] ?? 'Unknown';
      roleCounts[role] = (roleCounts[role] ?? 0) + 1;
    }

    return _buildChartContainer(
      title: "User Roles",
      chart: PieChart(
        PieChartData(
          sections: roleCounts.entries.map((entry) {
            final colors = {'User': Colors.blue, 'Admin': Colors.purple, 'Staff': Colors.amber};
            return PieChartSectionData(
              color: colors[entry.key] ?? Colors.grey,
              value: entry.value.toDouble(),
              title: '${entry.key}\n(${entry.value})',
              radius: 80,
              titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _noDataWidget() {
    return Center(child: Text("No data available.", style: TextStyle(color: Colors.grey[400])));
  }

  Widget _buildChartContainer({required String title, required Widget chart}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Color(0xFF303030), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildChatbot() {
    return Positioned(
      bottom: 80,
      right: 16,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: _isChatbotOpen ? MediaQuery.of(context).size.width * 0.85 : 0,
        height: _isChatbotOpen ? MediaQuery.of(context).size.height * 0.6 : 0,
        decoration: BoxDecoration(
          color: Color(0xFF303030),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: _isChatbotOpen ? Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
              ),
              child: Row(
                children: [
                  Icon(Icons.support_agent, color: Color(0xFFF1D789)),
                  SizedBox(width: 8),
                  Text("BI Assistant", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: _chatHistory.length,
                itemBuilder: (context, index) {
                  final msg = _chatHistory[index];
                  bool isUser = msg['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isUser ? Color(0xFFF1D789) : Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg['text']!,
                        style: TextStyle(color: isUser ? Colors.black : Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isChatLoading) Padding(
                padding: const EdgeInsets.all(8.0),
                child: LinearProgressIndicator(color: Color(0xFFF1D789), backgroundColor: Colors.grey.shade700,)
            ),
            Container(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Ask about the data...",
                        hintStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Color(0xFF3F3F3F),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: Color(0xFFF1D789)),
                    onPressed: _isChatLoading ? null : _sendMessageToGemini,
                  ),
                ],
              ),
            ),
          ],
        ) : null,
      ),
    );
  }
}