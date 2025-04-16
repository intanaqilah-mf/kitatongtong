import 'package:flutter/material.dart';
import 'package:projects/widgets/bottomNavBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:projects/pages/packageKasih.dart';
import 'package:projects/pages/packageRedeem.dart';

class Rewards extends StatefulWidget {
  @override
  _RewardsState createState() => _RewardsState();
}

class _RewardsState extends State<Rewards> {
  bool isRewards = true;
  int _selectedIndex = 0;
  int userPoints = 0;
  int redeemablePoints = 0;
  int valuePoints = 0;
  String validityMessage = "Valid for 1 month";
  List<Map<String, dynamic>> eligibleVouchers = [];
  List<Map<String, dynamic>> eventList = [];
  String getAdminVoucherBanner(String voucherGranted) {
    if (voucherGranted == "RM10") {
      return "https://firebasestorage.googleapis.com/v0/b/kita-tongtong.firebasestorage.app/o/voucherBanner%2F100_points_RM10.png?alt=media";
    } else if (voucherGranted == "RM20") {
      return "https://firebasestorage.googleapis.com/v0/b/kita-tongtong.firebasestorage.app/o/voucherBanner%2F200_points_RM20.png?alt=media";
    } else if (voucherGranted == "RM30") {
      return "https://firebasestorage.googleapis.com/v0/b/kita-tongtong.firebasestorage.app/o/voucherBanner%2F300_points_RM30.png?alt=media";
    } else if (voucherGranted == "RM40") {
      return "https://firebasestorage.googleapis.com/v0/b/kita-tongtong.firebasestorage.app/o/voucherBanner%2F400_points_RM40.png?alt=media";
    }
    return "";
  }


  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchEvents();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> fetchUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final voucherQuery = await _firestore.collection('vouchers').get();

    // Print user's doc info
    debugPrint("==== FETCHING USER DATA ====");
    debugPrint("UserDoc ID: $uid");
    debugPrint("UserDoc data: ${userDoc.data()}");

    // userPoints is from the 'points' field (not totalValuePoints!)
    int points = userDoc.data()?['points'] ?? 0;
    debugPrint("User has $points points.");

    // All voucher docs
    final allVouchers = voucherQuery.docs.map((doc) => doc.data()).toList();
    debugPrint("Total vouchers found in Firestore: ${allVouchers.length}");

    // Filter only vouchers of type "Points"
    final validVouchers = allVouchers
        .where((data) =>
    (data['typeVoucher'] ?? '').toString().trim().toLowerCase() == 'points')
        .toList()
      ..sort((a, b) => b['points'].compareTo(a['points'])); // Sort descending

    // Print all "Points" vouchers
    debugPrint("All 'Points' vouchers (descending by points):");
    for (var v in validVouchers) {
      debugPrint("  - points=${v['points']}, valuePoints=${v['valuePoints']}, bannerVoucher=${v['bannerVoucher']}");
    }

    // Filter for vouchers user can claim (points <= user's points, and has a banner)
    final pointVouchers = validVouchers.where((data) {
      final voucherPoints = data['points'] ?? 0;
      final banner = (data['bannerVoucher'] ?? '').toString().trim();
      return voucherPoints <= points && banner.isNotEmpty;
    }).toList();

    // Print the vouchers that user is actually eligible for
    debugPrint("Eligible vouchers (user has $points pts):");
    for (var v in pointVouchers) {
      debugPrint("  * points=${v['points']}, valuePoints=${v['valuePoints']}, bannerVoucher=${v['bannerVoucher']}");
    }

    // Keep for building your horizontal list
    eligibleVouchers = pointVouchers
        .where((v) =>
    v['points'] != null &&
        v['valuePoints'] != null &&
        v['bannerVoucher'] != null)
        .toList();

    // Now find the single "best match" voucher
    int bestMatchPoints = 0;
    int bestMatchValue = 0;
    for (var voucher in validVouchers) {
      if ((voucher['points'] ?? 0) <= points) {
        bestMatchPoints = voucher['points'];
        bestMatchValue = voucher['valuePoints'];
        break; // Found the largest voucher that user can afford
      }
    }

    debugPrint("==> BEST MATCH: $bestMatchPoints points => RM$bestMatchValue");
    int daysLeft = 0;
    if (userDoc.data()?['voucherReceived'] != null) {
      final received = userDoc.data()!['voucherReceived'];
      if (received is Map && received['redeemedAt'] != null) {
        final redeemedAt = received['redeemedAt'] as Timestamp?;
        if (redeemedAt != null) {
          final redeemedDate = redeemedAt.toDate();
          final now = DateTime.now();
          final difference = 30 - now.difference(redeemedDate).inDays;
          if (difference >= 0) {
            daysLeft = difference;
            validityMessage = "Valid for $daysLeft day${daysLeft == 1 ? '' : 's'}";
          } else {
            validityMessage = "Expired";
          }
        }
      }
    }

    setState(() {
      userPoints = points;
      redeemablePoints = bestMatchPoints;
      valuePoints = bestMatchValue;
    });
  }


  Future<Map<String, dynamic>?> fetchBestVoucherForTotalValuePoints() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    // 1) Read the user's totalValuePoints
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final int totalVal = userDoc.data()?['totalValuePoints'] ?? 0;
    // Convert totalValuePoints to effective points (assuming factor 10)
    final int effectivePoints = totalVal * 10;
    debugPrint("User has totalValuePoints: $totalVal, effectivePoints: $effectivePoints");

    // 2) Get all vouchers of type "Points"
    final voucherDocs = await _firestore.collection('vouchers').get();
    final allVouchers = voucherDocs.docs.map((doc) => doc.data()).toList();

    final validVouchers = allVouchers.where((v) {
      final tv = (v['typeVoucher'] ?? '').toString().trim().toLowerCase();
      return tv == 'points';
    }).toList()
      ..sort((a, b) {
        final aPoints = int.tryParse(a['points'].toString()) ?? 0;
        final bPoints = int.tryParse(b['points'].toString()) ?? 0;
        return bPoints.compareTo(aPoints); // descending order
      });

    // 3) Find the best voucher: largest voucher whose threshold <= effectivePoints
    Map<String, dynamic>? bestVoucher;
    for (var v in validVouchers) {
      final int threshold = int.tryParse(v['points'].toString()) ?? 0;
      if (threshold <= effectivePoints) {
        bestVoucher = v;
        break;
      }
    }

    if (bestVoucher == null) {
      debugPrint("No voucher found for effectivePoints = $effectivePoints");
      return null;
    }

    debugPrint("Best voucher for effectivePoints=$effectivePoints is threshold=${bestVoucher['points']} => RM${bestVoucher['valuePoints']}");
    return bestVoucher;
  }

  Future<void> fetchEvents() async {
    final querySnapshot =
    await FirebaseFirestore.instance.collection('event').get();

    final List<Map<String, dynamic>> fetchedEvents = querySnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'bannerUrl': data['bannerUrl'] ?? '',
        'eventName': data['eventName'] ?? '',
        'organiserName': data['organiserName'] ?? '',
        'points': data['points'] ?? 0,
        'eventEndDate': data['eventEndDate'] ?? '',
      };
    }).toList();
    final now = DateTime.now();
    // Filter events: include only if eventEndDate is today or in the future.
    final upcomingEvents = fetchedEvents.where((event) {
      final String eventEndDateStr = event['eventEndDate'] as String;
      if (eventEndDateStr.isEmpty) return false;
      try {
        final eventEndDate = DateFormat("dd MMM yyyy").parse(eventEndDateStr);
        final today = DateTime(now.year, now.month, now.day);
        return eventEndDate.isAtSameMomentAs(today) || eventEndDate.isAfter(today);
      } catch (e) {
        return false;
      }
    }).toList();

    setState(() {
      eventList = upcomingEvents;
    });
  }

  Future<void> redeemPoints() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || redeemablePoints == 0) return;

    final now = Timestamp.now();
    final userRef = _firestore.collection('users').doc(uid);
    final historyRef = _firestore.collection('redeemedPoints').doc();

    final userSnapshot = await userRef.get();
    final userData = userSnapshot.data();
    final name = userData?['name'] ?? '';
    final email = userData?['email'] ?? '';
    final currentPoints = userData?['points'] ?? 0;
    final currentTotalValue = userData?['totalValuePoints'] ?? 0;
    final currentVoucherHistory = userData?['voucherReceived'] ?? [];

    if (redeemablePoints > currentPoints) return;

    await _firestore.runTransaction((transaction) async {
      transaction.update(userRef, {
        'points': currentPoints - redeemablePoints,
        'totalValuePoints': currentTotalValue + valuePoints,
        'voucherReceived': FieldValue.arrayUnion([
          {
            'redeemedAt': now,
            'valuePoints': valuePoints,
          }
        ])
      });

      transaction.set(historyRef, {
        'userId': uid,
        'name': name,
        'email': email,
        'pointsUsed': redeemablePoints,
        'valuePoints': valuePoints,
        'redeemedAt': now,
      });
    });

    fetchUserData(); // Refresh
  }
  Future<void> claimVoucher(int selectedPoints, int selectedValuePoints) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || selectedPoints == 0) return;

    final now = Timestamp.now();
    final userRef = _firestore.collection('users').doc(uid);
    final historyRef = _firestore.collection('redeemedPoints').doc();

    final userSnapshot = await userRef.get();
    final userData = userSnapshot.data();
    final name = userData?['name'] ?? '';
    final email = userData?['email'] ?? '';
    final currentPoints = userData?['points'] ?? 0;
    final currentTotalValue = userData?['totalValuePoints'] ?? 0;

    if (selectedPoints > currentPoints) return;

    // Generate a unique voucherId by combining the voucher's value with the current timestamp's millisecond value.
    final voucherId = "${selectedValuePoints}_${now.millisecondsSinceEpoch}";

    await _firestore.runTransaction((transaction) async {
      transaction.update(userRef, {
        'points': currentPoints - selectedPoints,
        'totalValuePoints': currentTotalValue + selectedValuePoints,
        'voucherReceived': FieldValue.arrayUnion([
          {
            'redeemedAt': now,
            'valuePoints': selectedValuePoints,
            'voucherId': voucherId,  // Unique identifier added here.
          }
        ])
      });

      transaction.set(historyRef, {
        'userId': uid,
        'name': name,
        'email': email,
        'pointsUsed': selectedPoints,
        'valuePoints': selectedValuePoints,
        'redeemedAt': now,
      });
    });

    fetchUserData();
  }

  Widget buildRewardsListSection() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text("No user found."),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(uid).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!userSnapshot.hasData || userSnapshot.data == null) {
          return Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text("No user data found."),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;

        // Get the user's vouchers from the document.
        List<dynamic> userVouchers = [];
        if (userData.containsKey('voucherReceived')) {
          if (userData['voucherReceived'] is List) {
            userVouchers = List<dynamic>.from(userData['voucherReceived']);
          } else if (userData['voucherReceived'] is Map) {
            userVouchers = [userData['voucherReceived']];
          }
        }
        // Claimed vouchers: only those that do NOT have a voucherGranted field.
        final claimedVouchers = userVouchers.where((v) {
          return !(v is Map && v.containsKey('voucherGranted'));
        }).toList();

        return FutureBuilder<QuerySnapshot>(
          future: _firestore
              .collection('applications')
              .where("userId", isEqualTo: uid)
              .where("statusReward", isEqualTo: "Issued")
              .get(),
          builder: (context, appSnapshot) {
            if (appSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            List<Map<String, dynamic>> adminVoucherList = [];
            if (appSnapshot.hasData && appSnapshot.data!.docs.isNotEmpty) {
              // Map all matching documents.
              adminVoucherList = appSnapshot.data!.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();
            }
            // Transform each admin voucher document into a format that buildAdminVoucherWidget expects.
            List<Map<String, dynamic>> adminVouchers = adminVoucherList
                .where((doc) => doc.containsKey('reward'))
                .map((doc) {
              return {
                'voucherGranted': doc['reward'], // e.g. "RM10", "RM20", etc.
                'rewardType': doc.containsKey('rewardType')
                    ? doc['rewardType']
                    : doc['reward'],
                'eligibility': doc.containsKey('eligibility')
                    ? doc['eligibility']
                    : "Asnaf Application",
              };
            }).toList();

            return Padding(
              padding: EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.16, 0.38, 0.58, 0.88],
                    colors: [
                      Color(0xFFF9F295),
                      Color(0xFFE0AA3E),
                      Color(0xFFF9F295),
                      Color(0xFFB88A44),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Admin-issued vouchers fetched from the applications collection.
                    Text(
                      "This is your Rewards!",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10),
                    if (adminVouchers.isNotEmpty)
                    // Display admin vouchers in a column.
                      Column(
                        children: adminVouchers.map((voucher) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: buildAdminVoucherWidget(voucher),
                          );
                        }).toList(),
                      )
                    else
                      Text("No admin-issued rewards available.",
                          style: TextStyle(color: Colors.black)),
                    SizedBox(height: 20),
                    // Section 2: Claimed vouchers from the user's voucherReceived field (which do not have voucherGranted).
                    Text(
                      "My Claimed Vouchers",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildClaimedVoucherList(claimedVouchers),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClaimedVoucherList(dynamic voucherData) {
    List claimedVouchers = [];
    if (voucherData is List) {
      claimedVouchers = voucherData;
    } else if (voucherData is Map) {
      claimedVouchers.add(voucherData);
    }
    if (claimedVouchers.isEmpty) {
      return Text(
        "No claimed vouchers available.",
        style: TextStyle(color: Colors.black),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: claimedVouchers.length,
      itemBuilder: (context, index) {
        final voucher = claimedVouchers[index] as Map<String, dynamic>;
        String voucherValue = voucher['valuePoints'] != null
            ? voucher['valuePoints'].toString()
            : "0";
        String voucherGranted = "RM" + voucherValue;
        String bannerUrl = getAdminVoucherBanner(voucherGranted);
        String redeemedDateStr = "";
        if (voucher['redeemedAt'] != null) {
          redeemedDateStr = DateFormat("dd MMM yyyy")
              .format((voucher['redeemedAt'] as Timestamp).toDate());
        }
        int rmValue = int.tryParse(voucherValue) ?? 0;
        String subtitle = "Redeemed on:\n" + redeemedDateStr;

        return GestureDetector(
          onTap: () async {
            bool? removed = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PackageKasihPage(
                  rmValue: rmValue,
                  voucherReceived: voucher,
                ),
              ),
            );
            if (removed == true) {
              fetchUserData();
            }
          },

          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bannerUrl.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    bannerUrl,
                    width: double.infinity,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 110,
                        color: Colors.grey,
                        child: Center(
                            child: Text("Image Error",
                                style: TextStyle(color: Colors.white))),
                      );
                    },
                  ),
                )
                    : Container(
                  width: double.infinity,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text("Admin Issued Reward",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Redeem with",
                              style: TextStyle(
                                  color: Color(0xFFA67C00),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          Text("Rewards",
                              style: TextStyle(
                                  color: Color(0xFFA67C00),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(voucherGranted,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text(subtitle,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildVoucherWidget(Map<String, dynamic> voucher) {
    String bannerUrl = voucher['bannerVoucher'] ?? "";
    int thresholdPoints = int.tryParse(voucher['points'].toString()) ?? 0;
    int rmValue = int.tryParse(voucher['valuePoints'].toString()) ?? 0;
    String title = "$thresholdPoints pts";
    String subtitle = "RM$rmValue";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PackageRedeemPage(
              bannerUrl: bannerUrl, // provide the proper bannerUrl extracted from your voucher or package data
              packageLabel: 'X',    // set a label as needed
              rmValue: rmValue,
              validityDays: 30,
              items: [],            // supply actual package items if available
              voucherReceived: voucher,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                bannerUrl,
                width: double.infinity,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 110,
                    color: Colors.grey,
                    child: Center(child: Icon(Icons.error, color: Colors.white)),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Redeem with",
                          style: TextStyle(
                              color: Color(0xFFA67C00),
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Text("Rewards",
                          style: TextStyle(
                              color: Color(0xFFA67C00),
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      Text(subtitle,
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAdminVoucherWidget(Map<String, dynamic> voucher) {
    String voucherGranted = voucher['voucherGranted']?.toString() ?? "";
    String bannerUrl = getAdminVoucherBanner(voucherGranted);
    String title = voucherGranted;
    String subtitle = "${voucher['rewardType']}\n${voucher['eligibility']}";
    int rmValue = int.tryParse(voucherGranted.replaceAll("RM", "")) ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PackageKasihPage(rmValue: rmValue),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bannerUrl.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                bannerUrl,
                width: double.infinity,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 110,
                    color: Colors.grey,
                    child: Center(child: Text("Image Error", style: TextStyle(color: Colors.white))),
                  );
                },
              ),
            )
                : Container(
              width: double.infinity,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text("Admin Issued Reward", style: TextStyle(color: Colors.white)),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Redeem with",
                          style: TextStyle(
                              color: Color(0xFFA67C00),
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Text("Rewards",
                          style: TextStyle(
                              color: Color(0xFFA67C00),
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      Text(subtitle,
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRedeemSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tongtong Points\n$userPoints Pts",
                style: TextStyle(
                  color: Color(0xFFFFCF40),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.start,
              ),
              Image.asset(
                'assets/Smiley.png',
                width: 40,
                height: 40,
              ),
            ],
          ),
          SizedBox(height: 20),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Points to Redeem",
                  style: TextStyle(
                    color: Color(0xFFFDB515),
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "$redeemablePoints",
                  style: TextStyle(
                    color: Color(0xFFFFCF40),
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Details",
                  style: TextStyle(
                    color: Color(0xFFFDB515),
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "$valuePoints Cash Voucher\n$validityMessage",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: redeemPoints,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEFBF04),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    "Redeem Points",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 20),

                if (eligibleVouchers.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [0.16, 0.38, 0.58, 0.88],
                        colors: [
                          Color(0xFFF9F295),
                          Color(0xFFE0AA3E),
                          Color(0xFFF9F295),
                          Color(0xFFB88A44),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Redeem your Points!",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        SizedBox(
                          height: 260, // ← fixed overflow without breaking design
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: eligibleVouchers.length,
                            itemBuilder: (context, index) {
                              final voucher = eligibleVouchers[index];
                              final bannerUrl = voucher['bannerVoucher'];
                              final valuePoints = voucher['valuePoints'];
                              final pointsCost = voucher['points'];

                              return Container(
                                width: 200,
                                margin: EdgeInsets.only(right: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        bannerUrl,
                                        fit: BoxFit.cover,
                                        width: 200,
                                        height: 110,
                                      ),
                                    ),
                                    Container(
                                      width: 200,
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(10),
                                          bottomRight: Radius.circular(10),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text("Redeem with", style: TextStyle(color: Color(0xFFA67C00), fontWeight: FontWeight.bold, fontSize: 13)),
                                              Text("Rewards", style: TextStyle(color: Color(0xFFA67C00), fontWeight: FontWeight.bold, fontSize: 13)),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text("$pointsCost pts", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13)),
                                              Text("RM$valuePoints", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13)),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () => claimVoucher(pointsCost, valuePoints),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(0xFFFDB515),
                                                padding: EdgeInsets.symmetric(vertical: 10),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: Text("Claim", style: TextStyle(fontSize: 14, color: Colors.white)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        Text(
                          "Join Activity and Get Rewards!",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        if (eventList.isNotEmpty)
                        SizedBox(
                          height: 260, // match the voucher box height
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: eventList.length,
                            itemBuilder: (context, index) {
                              final event = eventList[index];
                              final bannerUrl = event['bannerUrl'];
                              final eventName = event['eventName'];
                              final organiserName = event['organiserName'];
                              final eventPoints = event['points'];

                              return Container(
                                width: 200,
                                margin: EdgeInsets.only(right: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Event Banner
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: bannerUrl.isNotEmpty
                                          ? Image.network(
                                        bannerUrl,
                                        fit: BoxFit.cover,
                                        width: 200,
                                        height: 110,
                                      )
                                          : Container(
                                        width: 200,
                                        height: 110,
                                        color: Colors.grey,
                                        child: Center(child: Text("No Image")),
                                      ),
                                    ),
                                    // White info box (like vouchers)
                                    Container(
                                      width: 200,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(10),
                                          bottomRight: Radius.circular(10),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Event Name
                                          Text(
                                            eventName,
                                            style: TextStyle(
                                              color: Color(0xFFA67C00),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          // Organiser Name
                                          Text(
                                            "by $organiserName",
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12,
                                            ),
                                          ),
                                          // Points
                                          SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "$eventPoints pts",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Icon(Icons.calendar_today, color: Colors.red, size: 16),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    event['eventEndDate'],
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),

                                          // "View" or "Join" button
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                // navigate to event details or do something else
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(0xFFFDB515),
                                                padding:
                                                EdgeInsets.symmetric(vertical: 10),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: Text(
                                                "Join",
                                                style: TextStyle(
                                                    fontSize: 14, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303030),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs: Redeem Rewards / Rewards
            Padding(
              padding: const EdgeInsets.only(top: 70.0, left: 16, right: 16),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Color(0xFFFDB515),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isRewards = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isRewards ? Colors.white : Color(0xFFFDB515),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Redeem Rewards",
                            style: TextStyle(
                              color: isRewards ? Color(0xFFFDB515) : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isRewards = false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !isRewards ? Colors.white : Color(0xFFFDB515),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Rewards",
                            style: TextStyle(
                              color: !isRewards ? Color(0xFFFDB515) : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // Show Redeem Section or Rewards Section
            isRewards
                ? buildRedeemSection()
                : buildRewardsListSection(),

            SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

}