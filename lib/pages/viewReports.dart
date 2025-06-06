import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:math';

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

  // Your Gemini API Key
  final String _apiKey = "AIzaSyCBbvP1G3JKbvUV00QNcQLuXz6tBXwJlK4"; // Use your actual API key

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  // Fetch data from all collections in Firestore
  Future<void> _fetchAllData() async {
    setState(() { _isDataLoading = true; });

    final firestore = FirebaseFirestore.instance;
    final collections = [
      'applications', 'donations', 'users',
      'redeemedKasih', 'package_kasih', 'notifications'
    ];

    Map<String, dynamic> data = {};
    for (String col in collections) {
      final snapshot = await firestore.collection(col).get();
      data[col] = snapshot.docs.map((doc) => doc.data()).toList();
    }

    setState(() {
      _allData = data;
      _isDataLoading = false;
    });
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

      final prompt = """
      You are a helpful business intelligence assistant for a charity management app.
      Analyze the following JSON data from our database and answer the user's question.
      Provide concise and insightful answers. Do not just repeat the data; interpret it.
      
      Here is the data:
      ${jsonEncode(_allData)}

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF3F3F3F),
      body: Stack(
        children: [
          // Main content: Charts and Graphs
          _isDataLoading
              ? Center(child: CircularProgressIndicator(color: Color(0xFFF1D789)))
              : SingleChildScrollView(
            padding: EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Dashboard Reports", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 24),
                _buildApplicationsChart(),
                SizedBox(height: 24),
                _buildDonationsChart(),
                SizedBox(height: 24),
                _buildUserRolesChart(),
                SizedBox(height: 24),
                _buildRedeemedPackagesChart(),
              ],
            ),
          ),

          // Chatbot UI
          _buildChatbot(),
        ],
      ),
      // Floating Action Button to toggle chatbot
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleChatbot,
        child: Icon(_isChatbotOpen ? Icons.close : Icons.chat_bubble),
        backgroundColor: Color(0xFFF1D789),
        foregroundColor: Color(0xFF3F3F3F),
      ),
    );
  }

  // --- WIDGETS FOR CHARTS ---

  // Pie chart for Application Status
  Widget _buildApplicationsChart() {
    final applications = _allData['applications'] as List<dynamic>;
    if (applications.isEmpty) return _buildChartContainer(title: "Application Status", chart: _noDataWidget());

    Map<String, int> statusCounts = {'Pending': 0, 'Approve': 0, 'Reject': 0};

    for (var app in applications) {
      String status = app['statusApplication'] ?? 'Unknown';
      if (statusCounts.containsKey(status)) {
        statusCounts[status] = statusCounts[status]! + 1;
      }
    }

    return _buildChartContainer(
      title: "Application Status",
      chart: PieChart(
        PieChartData(
          sections: statusCounts.entries.map((entry) {
            final colors = {'Pending': Colors.orange, 'Approve': Colors.green, 'Reject': Colors.red};
            return PieChartSectionData(
              color: colors[entry.key],
              value: entry.value.toDouble(),
              title: '${entry.value}',
              radius: 80,
              titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  // Bar chart for Donations per Month
  Widget _buildDonationsChart() {
    final donations = _allData['donations'] as List<dynamic>;
    if (donations.isEmpty) return _buildChartContainer(title: "Monthly Donations (RM)", chart: _noDataWidget());

    Map<String, double> monthlyTotals = {};
    for (var donation in donations) {
      if (donation['timestamp'] == null) continue;
      Timestamp timestamp = donation['timestamp'];
      DateTime date = timestamp.toDate();
      String month = DateFormat('yyyy-MM').format(date);
      double amount = (donation['donationAmount'] as num).toDouble();
      monthlyTotals[month] = (monthlyTotals[month] ?? 0) + amount;
    }

    if (monthlyTotals.isEmpty) return _buildChartContainer(title: "Monthly Donations (RM)", chart: _noDataWidget());

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

  // Bar chart for Redeemed Packages
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
              // CORRECTED WIDGET CREATION
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

  // Pie chart for User Roles
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

  Widget _noDataWidget() {
    return Center(child: Text("No data available.", style: TextStyle(color: Colors.grey[400])));
  }

  // A helper widget to create a consistent container for each chart
  Widget _buildChartContainer({required String title, required Widget chart}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF303030),
        borderRadius: BorderRadius.circular(16),
      ),
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

  // --- WIDGET FOR CHATBOT UI ---
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
            // Chat Header
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
            // Message History
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
            // Message Input
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