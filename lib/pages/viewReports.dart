import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:math';
import 'package:projects/config/app_config.dart';
import 'package:projects/widgets/bottomNavBar.dart';

// Enum for the interactive redemption chart view
enum RedemptionView { summary, kasih, hamper }

class ViewReportsScreen extends StatefulWidget {
  const ViewReportsScreen({Key? key}) : super(key: key);

  @override
  _ViewReportsScreenState createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> {
  int _selectedIndex = 0;
  bool _isDataLoading = true;
  Map<String, dynamic> _allData = {};
  RedemptionView _selectedRedemptionView = RedemptionView.summary;

  // Chatbot state
  bool _isChatbotOpen = false;
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatHistory = [];
  bool _isChatLoading = false;
  final String _apiKey = AppConfig.getGeminiAPIKey();

  // Theme Colors from Screenshot
  static const Color primaryGold = Color(0xFFFDB515);
  static const Color darkGold = Color(0xFFB88A44);
  static const Color lightGold = Color(0xFFF9F295);
  static const Color darkBackground = Color(0xFF303030);
  static const Color chartContainerBg = Color(0xFF3F3F3F);
  static const Color accentBlue = Color(0xFF4A90E2);
  static const Color accentGreen = Color(0xFF50E3C2);

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  void _onItemTapped(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _fetchAllData() async {
    if (mounted) setState(() => _isDataLoading = true);

    final firestore = FirebaseFirestore.instance;
    final collections = [
      'applications', 'donation', 'users',
      'redeemedKasih', 'package_kasih', 'package_hamper', 'notifications'
    ];

    Map<String, dynamic> data = {};
    for (String col in collections) {
      try {
        final snapshot = await firestore.collection(col).get();
        data[col] = snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
      } catch (e) {
        print("Error fetching collection '$col': $e");
        data[col] = [];
      }
    }

    if (mounted) {
      setState(() {
        _allData = data;
        _isDataLoading = false;
      });
    }
  }

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
    setState(() => _isChatbotOpen = !_isChatbotOpen);
  }

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: Stack(
        children: [
          _isDataLoading
              ? const Center(child: CircularProgressIndicator(color: primaryGold))
              : SingleChildScrollView(
            padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Dashboard Reports", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Actionable insights for strategic decisions.", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 24),
                _buildApplicationFunnelChart(),
                const SizedBox(height: 24),
                _buildRegionChart(),
                const SizedBox(height: 24),
                _buildDonationsChart(),
                const SizedBox(height: 24),
                _buildRedemptionPopularityChart(),
              ],
            ),
          ),
          _buildChatbot(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleChatbot,
        backgroundColor: primaryGold,
        foregroundColor: Colors.black,
        child: Icon(_isChatbotOpen ? Icons.close : Icons.chat_bubble_outline),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  // --- CHART BUILDER WIDGETS ---

  Widget _buildApplicationFunnelChart() {
    final applications = _allData['applications'] as List<dynamic>? ?? [];
    if (applications.isEmpty) return _buildChartContainer(title: "Application Funnel Analysis", chart: _noDataWidget());

    final total = applications.length;
    final approved = applications.where((app) => app['statusApplication'] == 'Approve').length;
    final rejected = applications.where((app) => app['statusApplication'] == 'Reject').length;
    final pending = total - approved - rejected;

    final data = [
      {'label': 'Total Apps', 'value': total, 'color': primaryGold},
      {'label': 'Pending', 'value': pending, 'color': accentBlue},
      {'label': 'Approved', 'value': approved, 'color': accentGreen},
      {'label': 'Rejected', 'value': rejected, 'color': Colors.redAccent},
    ];

    double maxValue = data.map((d) => d['value'] as int).reduce(max).toDouble();

    return _buildChartContainer(
      title: "Application Funnel Analysis",
      chart: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${data[groupIndex]['label']}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: <TextSpan>[
                    TextSpan(
                      text: (rod.toY).toInt().toString(),
                      style: const TextStyle(color: primaryGold, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
              show: true,
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                  )
              )
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          barGroups: data.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> item = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (item['value'] as int).toDouble(),
                  color: item['color'] as Color,
                  width: 25,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRegionChart() {
    final applications = _allData['applications'] as List<dynamic>? ?? [];
    if (applications.isEmpty) return _buildChartContainer(title: "Applicants by Region", chart: _noDataWidget());

    Map<String, int> regionCounts = {};
    for (var app in applications) {
      final postcode = app['postcode']?.toString();
      if (postcode != null) {
        final region = _getRegionFromPostcode(postcode);
        regionCounts[region] = (regionCounts[region] ?? 0) + 1;
      }
    }

    final sortedRegions = regionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    double maxValue = sortedRegions.isNotEmpty ? sortedRegions.first.value.toDouble() : 10;

    return _buildChartContainer(
      title: "Applicants by Region",
      chart: BarChart(
        BarChartData(
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  // Add this check to prevent the RangeError
                  if (index < 0 || index >= sortedRegions.length) {
                    return Container(); // Return an empty container for invalid indices
                  }
                  return Text(
                    sortedRegions[index].key,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.right,
                  );
                },
                reservedSize: 80,
              ),
            ),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22, getTitlesWidget: (value, meta) {
              if (value.toInt() % 5 != 0 && value != meta.max) return Container();
              return Text(value.toInt().toString(), style: const TextStyle(color: Colors.white70, fontSize: 10));
            })),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true, checkToShowHorizontalLine: (val) => val % 5 == 0, horizontalInterval: 5),
          barGroups: sortedRegions.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value.toDouble(),
                  color: primaryGold,
                  width: 15,
                  borderRadius: BorderRadius.circular(2),
                )
              ],
            );
          }).toList(),
          maxY: (maxValue * 1.2).ceilToDouble(),
        ),
        swapAnimationDuration: const Duration(milliseconds: 150),
        swapAnimationCurve: Curves.linear,
      ),
    );
  }

  String _getRegionFromPostcode(String postcode) {
    const Map<String, String> regionMap = {
      '08000': 'Sg. Petani', '08010': 'Sg. Petani', '09000': 'Kulim',
      '09400': 'Padang Serai', '05000': 'Alor Setar', '05050': 'Alor Setar',
      '05100': 'Alor Setar', '06000': 'Jitra', '07000': 'Langkawi',
    };
    return regionMap[postcode] ?? 'Other';
  }

  Widget _buildDonationsChart() {
    final donations = _allData['donation'] as List<dynamic>? ?? [];
    if (donations.isEmpty) return _buildChartContainer(title: "Monthly Donations (RM)", chart: _noDataWidget());

    Map<String, double> monthlyTotals = {};
    Map<String, int> monthlyCounts = {};

    for (var donation in donations) {
      if (donation['timestamp'] == null || donation['timestamp'] is! Timestamp || donation['amount'] == null || donation['amount'] is! num) continue;
      Timestamp timestamp = donation['timestamp'];
      DateTime date = timestamp.toDate();
      String month = DateFormat('yyyy-MM').format(date);
      double amount = (donation['amount'] as num).toDouble();
      monthlyTotals[month] = (monthlyTotals[month] ?? 0) + amount;
      monthlyCounts[month] = (monthlyCounts[month] ?? 0) + 1;
    }

    if (monthlyTotals.isEmpty) return _buildChartContainer(title: "Monthly Donations (RM)", chart: _noDataWidget());

    var sortedEntries = monthlyTotals.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    double maxValue = sortedEntries.map((e) => e.value).reduce(max);
    int maxCount = monthlyCounts.values.reduce(max);

    return _buildChartContainer(
      title: "Monthly Donation Analysis",
      chart: BarChart(
        BarChartData(
          maxY: maxValue * 1.2,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text('RM${(value/1000).toStringAsFixed(0)}k', style: const TextStyle(color: primaryGold, fontSize: 10)))),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text((value / (maxValue * 1.2) * maxCount).round().toString(), style: const TextStyle(color: accentGreen, fontSize: 10)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Text(DateFormat('MMM').format(DateTime.parse('${sortedEntries[value.toInt()].key}-01')), style: const TextStyle(color: Colors.white70, fontSize: 10)), reservedSize: 22)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true, horizontalInterval: 500, checkToShowHorizontalLine: (v) => v % 1000 == 0),
          barGroups: sortedEntries.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(toY: entry.value.value, color: primaryGold, width: 12),
                BarChartRodData(toY: (monthlyCounts[entry.value.key]!.toDouble() / maxCount) * maxValue, color: accentGreen.withOpacity(0.8), width: 12),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRedemptionPopularityChart() {
    final redeemedItems = _allData['redeemedKasih'] as List<dynamic>? ?? [];
    if (redeemedItems.isEmpty) return _buildChartContainer(title: "Redemption Popularity", chart: _noDataWidget());

    Map<String, int> hamperCounts = {};
    Map<String, int> kasihCounts = {};
    int totalHampers = 0;
    int totalKasih = 0;

    for (var redemption in redeemedItems) {
      List<dynamic> items = redemption['itemsRedeemed'] ?? [];
      for (var item in items) {
        if (item['category'] == 'Hamper') {
          hamperCounts[item['name']] = (hamperCounts[item['name']] ?? 0) + 1;
          totalHampers++;
        } else {
          kasihCounts[item['name']] = (kasihCounts[item['name']] ?? 0) + 1;
          totalKasih++;
        }
      }
    }

    var sortedHampers = hamperCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    var sortedKasih = kasihCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top10Kasih = sortedKasih.take(10).toList();

    Widget chartView;
    switch (_selectedRedemptionView) {
      case RedemptionView.summary:
        chartView = _buildSummaryBarChart(totalKasih, totalHampers);
        break;
      case RedemptionView.kasih:
        chartView = _buildDetailedBarChart(top10Kasih, "Top 10 Redeemed Kasih Items");
        break;
      case RedemptionView.hamper:
        chartView = _buildDetailedBarChart(sortedHampers, "Redeemed Hampers");
        break;
    }

    return _buildChartContainer(
      title: "Redemption Popularity",
      customHeader: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildToggleChip("Summary", RedemptionView.summary),
          _buildToggleChip("Kasih", RedemptionView.kasih),
          _buildToggleChip("Hamper", RedemptionView.hamper),
        ],
      ),
      chart: chartView,
    );
  }

  Widget _buildToggleChip(String label, RedemptionView view) {
    bool isSelected = _selectedRedemptionView == view;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedRedemptionView = view;
            });
          }
        },
        backgroundColor: chartContainerBg,
        selectedColor: primaryGold,
        labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? primaryGold : darkGold)),
      ),
    );
  }

  Widget _buildSummaryBarChart(int kasihCount, int hamperCount) {
    return BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: kasihCount.toDouble(), color: accentBlue, width: 40)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: hamperCount.toDouble(), color: accentGreen, width: 40)]),
        ],
        gridData: FlGridData(show: true, horizontalInterval: 5, checkToShowHorizontalLine: (v) => v % 10 == 0),
        borderData: FlBorderData(show: false)
    ));
  }

  Widget _buildDetailedBarChart(List<MapEntry<String, int>> data, String title) {
    if (data.isEmpty) return _noDataWidget();
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                // ADD THIS BOUNDARY CHECK TO PREVENT THE CRASH
                if (index < 0 || index >= data.length) {
                  return Container(); // Return an empty widget for invalid indices
                }
                return Text(
                    data[index].key,
                    style: const TextStyle(color: Colors.white70, fontSize: 10)
                );
              },
              reservedSize: 100,
            ),
          ),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true, horizontalInterval: 2, checkToShowHorizontalLine: (v) => v % 2 == 0),
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [BarChartRodData(toY: entry.value.value.toDouble(), color: primaryGold, width: 14, borderRadius: BorderRadius.circular(2))],
          );
        }).toList(),
      ),
      swapAnimationDuration: const Duration(milliseconds: 150),
      swapAnimationCurve: Curves.linear,
    );
  }

  Widget _noDataWidget() {
    return const Center(child: Text("No data available to display.", style: TextStyle(color: Colors.white70)));
  }

  Widget _buildChartContainer({required String title, Widget? customHeader, required Widget chart}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: chartContainerBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (customHeader == null)
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
          else
            customHeader,
          const SizedBox(height: 20),
          SizedBox(height: 250, child: chart),
        ],
      ),
    );
  }

  Widget _buildChatbot() {
    return Positioned(
      bottom: 80,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: _isChatbotOpen ? max(MediaQuery.of(context).size.width * 0.85, 300) : 0,
        height: _isChatbotOpen ? MediaQuery.of(context).size.height * 0.6 : 0,
        decoration: BoxDecoration(
            color: darkBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15)],
            border: Border.all(color: darkGold)
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _isChatbotOpen ? Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: chartContainerBg,
                child: const Row(
                  children: [
                    Icon(Icons.support_agent, color: primaryGold),
                    SizedBox(width: 8),
                    Text("BI Assistant", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _chatHistory.length,
                  itemBuilder: (context, index) {
                    final msg = _chatHistory[index];
                    bool isUser = msg['role'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isUser ? primaryGold : chartContainerBg,
                          borderRadius: BorderRadius.circular(16),
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
                  child: LinearProgressIndicator(color: primaryGold, backgroundColor: Colors.grey.shade700,)
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: darkGold)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                            hintText: "Ask about the data...",
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: chartContainerBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16)
                        ),
                        onSubmitted: (_) => _sendMessageToGemini(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: primaryGold),
                      onPressed: _isChatLoading ? null : _sendMessageToGemini,
                    ),
                  ],
                ),
              ),
            ],
          ) : null,
        ),
      ),
    );
  }
}
