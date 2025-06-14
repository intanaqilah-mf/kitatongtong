import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottomNavBar.dart';
import '../pages/loginPage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projects/localization/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  final User? user;

  const ProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? currentUser;
  File? _selectedImage;
  String? _firestorePhotoUrl;
  String? _firestoreEmail;

  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController nricController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController postcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
    _loadCachedData();
    _initializeListeners();

    nameController.text = currentUser?.displayName ?? '';
    phoneController.text = currentUser?.phoneNumber ?? '';
    nricController.text = '';
    addressController.text = '';
    cityController.text = '';
    postcodeController.text = '';
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
    await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
      _saveData(isImageUpdated: true);
    }
  }

  Future<void> clearAuthCache() async {
    await FirebaseAuth.instance.signOut();

    GoogleSignIn googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.disconnect();
    }
    await googleSignIn.signOut();

    final prefs = await SharedPreferences.getInstance();
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    print("SharedPreferences for $userId: ${prefs.getString('name_$userId')}");

    if (userId.isNotEmpty) {
      await prefs.remove('name_$userId');
      await prefs.remove('phone_$userId');
      await prefs.remove('nric_$userId');
      await prefs.remove('address_$userId');
      await prefs.remove('city_$userId');
      await prefs.remove('postcode_$userId');
      await prefs.remove('photoUrl_$userId');
    }

    print("✅ Cached user data cleared.");
  }

  Future<void> _saveData({bool isImageUpdated = false}) async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
      if (userId.isEmpty) return;

      String? imageUrl;
      final prefs = await SharedPreferences.getInstance();

      if (isImageUpdated && _selectedImage != null) {
        String fileName =
            "${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg";
        final storageRef =
        FirebaseStorage.instance.ref().child('profile_pictures/$fileName');

        final TaskSnapshot snapshot = await storageRef.putFile(_selectedImage!);
        imageUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set({'photoUrl': imageUrl}, SetOptions(merge: true));

        prefs.setString('photoUrl_$userId', imageUrl);
      }

      final userData = {
        'name': nameController.text,
        'phone': phoneController.text,
        'nric': nricController.text,
        'address': addressController.text,
        'city': cityController.text,
        'postcode': postcodeController.text,
        if (imageUrl != null) 'photoUrl': imageUrl,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(userData, SetOptions(merge: true));

      prefs.setString('name_$userId', nameController.text);
      prefs.setString('phone_$userId', phoneController.text);
      prefs.setString('nric_$userId', nricController.text);
      prefs.setString('address_$userId', addressController.text);
      prefs.setString('city_$userId', cityController.text);
      prefs.setString('postcode_$userId', postcodeController.text);
      if (_firestorePhotoUrl != null) {
        prefs.setString('photoUrl_$userId', _firestorePhotoUrl!);
      }


      setState(() {
        if (imageUrl != null) {
          _selectedImage = null;
        }
      });

      print("✅ User data saved successfully.");
    } catch (e) {
      print("❌ Error during data saving: $e");
    }
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    if (userId.isEmpty) return;

    final docSnapshot =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (docSnapshot.exists) {
      final userData = docSnapshot.data();

      setState(() {
        nameController.text = userData?['name'] ?? '';
        phoneController.text = userData?['phone'] ?? '';
        nricController.text = userData?['nric'] ?? '';
        addressController.text = userData?['address'] ?? '';
        cityController.text = userData?['city'] ?? '';
        postcodeController.text = userData?['postcode'] ?? '';
        _firestorePhotoUrl = userData?['photoUrl'];
        _firestoreEmail = userData?['email'];

        prefs.setString('name_$userId', nameController.text);
        prefs.setString('phone_$userId', phoneController.text);
        prefs.setString('nric_$userId', nricController.text);
        prefs.setString('address_$userId', addressController.text);
        prefs.setString('city_$userId', cityController.text);
        prefs.setString('postcode_$userId', postcodeController.text);
        if (_firestorePhotoUrl != null) {
          prefs.setString('photoUrl_$userId', _firestorePhotoUrl!);
        }
      });
    }
  }

  void _initializeListeners() {
    nameController.addListener(() => _saveData());
    phoneController.addListener(() => _saveData());
    nricController.addListener(() => _saveData());
    addressController.addListener(() => _saveData());
    cityController.addListener(() => _saveData());
    postcodeController.addListener(() => _saveData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (currentUser != null) {
                            _pickImage();
                          }
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (_firestorePhotoUrl != null
                              ? NetworkImage(_firestorePhotoUrl!)
                              : AssetImage('assets/profileNotLogin.png'))
                          as ImageProvider,
                        ),
                      ),
                      Stack(
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.6,
                            ),
                            child: TextField(
                              controller: nameController,
                              onChanged: (text) {
                                setState(() {});
                              },
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.yellow,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: AppLocalizations.of(context)
                                    .translate('profile_set_name_hint'),
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Positioned(
                            right: MediaQuery.of(context).size.width * 0.05,
                            top: 10,
                            child: GestureDetector(
                              child: Image.asset(
                                'assets/pencil.png',
                                height: 20,
                                width: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Color(0xFF404040),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Image.asset(
                                'assets/profileicon1.png',
                                height: 24,
                                width: 24,
                              ),
                              title: GestureDetector(
                                onTap: () {
                                  _pickImage();
                                },
                                child: Text(
                                  AppLocalizations.of(context)
                                      .translate('profile_change_photo'),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            buildEmailRow(
                              'assets/profileIcon9.png',
                              _firestoreEmail != null && _firestoreEmail!.isNotEmpty
                                  ? _firestoreEmail!
                                  : AppLocalizations.of(context).translate('profile_no_email'),
                            ),
                            buildNonEditableRow(
                                'assets/profileicon2.png',
                                currentUser?.displayName ??
                                    AppLocalizations.of(context)
                                        .translate('profile_set_username')),
                            buildEditableRow(
                                'assets/profileicon3.png',
                                AppLocalizations.of(context)
                                    .translate('profile_mobile_number'),
                                phoneController),
                            buildEditableRow(
                                'assets/profileicon4.png',
                                AppLocalizations.of(context)
                                    .translate('profile_nric'),
                                nricController),
                            buildEditableRow(
                                'assets/profileicon5.png',
                                AppLocalizations.of(context)
                                    .translate('profile_home_address'),
                                addressController),
                            buildEditableRow(
                                'assets/profileicon6.png',
                                AppLocalizations.of(context)
                                    .translate('profile_city'),
                                cityController),
                            buildEditableRow(
                                'assets/profileicon7.png',
                                AppLocalizations.of(context)
                                    .translate('profile_postcode'),
                                postcodeController),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: Column(
                    children: [
                      SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentUser != null
                              ? Colors.red
                              : Color(0xFFFFCF40),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 80, vertical: 12),
                        ),
                        onPressed: () async {
                          await clearAuthCache();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()),
                          );
                        },
                        child: Text(
                          currentUser != null
                              ? AppLocalizations.of(context)
                              .translate('profile_logout')
                              : AppLocalizations.of(context)
                              .translate('profile_login'),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 4,
        onItemTapped: (int index) {
          if (index != 4) {
            Navigator.pushNamed(context, '/home');
          }
        },
      ),
    );
  }

  Widget buildNonEditableRow(String iconPath, String text) {
    return ListTile(
      leading: Image.asset(
        iconPath,
        height: 24,
        width: 24,
      ),
      title: Text(
        text,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }

  Widget buildEditableRow(
      String iconPath, String label, TextEditingController controller) {
    return ListTile(
      leading: Image.asset(
        iconPath,
        height: 24,
        width: 24,
      ),
      title: TextField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

Widget buildEmailRow(String iconPath, String email) {
  return ListTile(
    leading: Image.asset(
      iconPath,
      height: 24,
      width: 24,
    ),
    title: Text(
      email,
      style: TextStyle(
        color: Colors.white,
      ),
    ),
  );
}
