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

class ProfilePage extends StatefulWidget {
  final User? user;

  ProfilePage({this.user});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? currentUser;
  File? _selectedImage;

  // Text controllers for editable fields
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
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);

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
  }

  Future<void> _saveData({bool isImageUpdated = false}) async {
    try {
      String? imageUrl;

      if (isImageUpdated && _selectedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures/${currentUser!.uid}.jpg');
        await storageRef.putFile(_selectedImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      final userData = {
        'name': nameController.text,
        'phone': phoneController.text,
        'nric': nricController.text,
        'address': addressController.text,
        'city': cityController.text,
        'postcode': postcodeController.text,
        'photoUrl': imageUrl ?? currentUser?.photoURL,
      };

      await FirebaseFirestore.instance
          .collection('asnafInfo')
          .doc(currentUser!.uid)
          .set(userData);

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('name', nameController.text);
      prefs.setString('phone', phoneController.text);
      prefs.setString('nric', nricController.text);
      prefs.setString('address', addressController.text);
      prefs.setString('city', cityController.text);
      prefs.setString('postcode', postcodeController.text);
      if (imageUrl != null) prefs.setString('photoUrl', imageUrl);
    } catch (e) {
      debugPrint('Error saving data: $e');
    }
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nameController.text = prefs.getString('name') ?? currentUser?.displayName ?? '';
      phoneController.text = prefs.getString('phone') ?? currentUser?.phoneNumber ?? '';
      nricController.text = prefs.getString('nric') ?? '';
      addressController.text = prefs.getString('address') ?? '';
      cityController.text = prefs.getString('city') ?? '';
      postcodeController.text = prefs.getString('postcode') ?? '';
    });
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
      body: Column(
        children: [
          SizedBox(height: 50),
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
                        : (currentUser?.photoURL != null
                        ? NetworkImage(currentUser!.photoURL!)
                        : AssetImage('assets/profileNotLogin.png')) as ImageProvider,
                  ),
                ),
                SizedBox(height: 10),
                Stack(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.6, // Limit text width to 60% of screen width
                      ),
                      child: TextField(
                        controller: nameController,
                        onChanged: (text) {
                          setState(() {}); // Recalculate layout on text change
                        },
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.yellow,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Set your name",
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        maxLines: 2, // Allow wrapping to the second line
                        textAlign: TextAlign.center, // Center the text
                      ),
                    ),
                    Positioned(
                      right: MediaQuery.of(context).size.width * 0.001,
                      top: MediaQuery.of(context).size.width * 0.05,
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


                SizedBox(height: 10),
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
                            'Change profile photo',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      buildNonEditableRow('assets/profileicon2.png', currentUser?.displayName ?? 'Set username'),
                      buildEditableRow('assets/profileicon3.png', 'Mobile Number', phoneController),
                      buildEditableRow('assets/profileicon4.png', 'NRIC', nricController),
                      buildEditableRow('assets/profileicon5.png', 'Home Address', addressController),
                      buildEditableRow('assets/profileicon6.png', 'City', cityController),
                      buildEditableRow('assets/profileicon7.png', 'Postcode', postcodeController),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: currentUser != null ? Colors.red : Color(0xFFFFCF40),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 80, vertical: 12),
              ),
              onPressed: () async {
                await clearAuthCache();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text(
                currentUser != null ? "Logout" : "Login",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
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

  Widget buildEditableRow(String iconPath, String label, TextEditingController controller) {
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
