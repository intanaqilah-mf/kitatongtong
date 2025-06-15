import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/bottomNavBar.dart';
import '../pages/loginPage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  bool _isSaving = false;
  bool _isMounted = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController nricController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController postcodeController = TextEditingController();
  TextEditingController stateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    currentUser = widget.user ?? FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _loadInitialData();
      _initializeListeners();
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    nameController.removeListener(_saveData);
    phoneController.removeListener(_saveData);
    addressController.removeListener(_saveData);
    cityController.removeListener(_saveData);
    postcodeController.removeListener(_saveData);
    stateController.removeListener(_saveData);

    nameController.dispose();
    phoneController.dispose();
    nricController.dispose();
    addressController.dispose();
    cityController.dispose();
    postcodeController.dispose();
    stateController.dispose();
    super.dispose();
  }

  void _loadInitialData() async {
    await _loadCachedData();
    await _loadUserDataFromFirestore();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedImage != null) {
      if (!_isMounted) return;
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
      _saveData(isImageUpdated: true);
    }
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = currentUser?.uid;

    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();

    if (userId != null) {
      await prefs.remove('name_$userId');
      await prefs.remove('phone_$userId');
      await prefs.remove('nric_$userId');
      await prefs.remove('address_$userId');
      await prefs.remove('city_$userId');
      await prefs.remove('postcode_$userId');
      await prefs.remove('state_$userId');
      await prefs.remove('photoUrl_$userId');
    }

    if (!_isMounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
    );
  }

  Future<void> _saveData({bool isImageUpdated = false}) async {
    if (_isSaving) return;
    if (_isMounted) setState(() => _isSaving = true);

    try {
      String? userId = currentUser?.uid;
      if (userId == null || userId.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      String? imageUrl = _firestorePhotoUrl;

      if (isImageUpdated && _selectedImage != null) {
        String fileName = "${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg";
        final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/$fileName');
        final snapshot = await storageRef.putFile(_selectedImage!);
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      final userData = {
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'city': cityController.text.trim(),
        'postcode': postcodeController.text.trim(),
        'state': stateController.text.trim(),
        if (imageUrl != null) 'photoUrl': imageUrl,
      };

      await FirebaseFirestore.instance.collection('users').doc(userId).set(userData, SetOptions(merge: true));

      await prefs.setString('phone_$userId', phoneController.text.trim());
      await prefs.setString('address_$userId', addressController.text.trim());
      await prefs.setString('city_$userId', cityController.text.trim());
      await prefs.setString('postcode_$userId', postcodeController.text.trim());
      await prefs.setString('state_$userId', stateController.text.trim());
      if (imageUrl != null) {
        await prefs.setString('photoUrl_$userId', imageUrl);
      }

      if (_isMounted) {
        setState(() {
          if (isImageUpdated) {
            _firestorePhotoUrl = imageUrl;
            _selectedImage = null;
          }
        });
      }
    } catch (e) {
      print("❌ Error during data saving: $e");
    } finally {
      if (_isMounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = currentUser?.uid;
    if (userId == null || userId.isEmpty || !_isMounted) return;

    setState(() {
      nameController.text = prefs.getString('name_$userId') ?? currentUser?.displayName ?? '';
      phoneController.text = prefs.getString('phone_$userId') ?? currentUser?.phoneNumber ?? '';
      nricController.text = prefs.getString('nric_$userId') ?? '';
      addressController.text = prefs.getString('address_$userId') ?? '';
      cityController.text = prefs.getString('city_$userId') ?? '';
      postcodeController.text = prefs.getString('postcode_$userId') ?? '';
      stateController.text = prefs.getString('state_$userId') ?? '';
      _firestorePhotoUrl = prefs.getString('photoUrl_$userId') ?? currentUser?.photoURL;
      _firestoreEmail = currentUser?.email ?? '';
    });
  }

  Future<void> _loadUserDataFromFirestore() async {
    String? userId = currentUser?.uid;
    if (userId == null || userId.isEmpty) return;

    try {
      final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!_isMounted || !docSnapshot.exists) return;

      final userData = docSnapshot.data()!;
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        nameController.text = userData['name'] ?? '';
        phoneController.text = userData['phone'] ?? '';
        nricController.text = userData['nric'] ?? '';
        addressController.text = userData['address'] ?? '';
        cityController.text = userData['city'] ?? '';
        postcodeController.text = userData['postcode'] ?? '';
        stateController.text = userData['state'] ?? '';
        _firestorePhotoUrl = userData['photoUrl'];
        _firestoreEmail = userData['email'] ?? currentUser?.email ?? '';
      });

      await prefs.setString('name_$userId', nameController.text);
      await prefs.setString('phone_$userId', phoneController.text);
      await prefs.setString('nric_$userId', nricController.text);
      await prefs.setString('address_$userId', addressController.text);
      await prefs.setString('city_$userId', cityController.text);
      await prefs.setString('postcode_$userId', postcodeController.text);
      await prefs.setString('state_$userId', stateController.text);
      if (_firestorePhotoUrl != null) {
        await prefs.setString('photoUrl_$userId', _firestorePhotoUrl!);
      }
    } catch (e) {
      print("❌ Error loading data from Firestore: $e");
    }
  }

  void _initializeListeners() {
    phoneController.addListener(_saveData);
    addressController.addListener(_saveData);
    cityController.addListener(_saveData);
    postcodeController.addListener(_saveData);
    stateController.addListener(_saveData);
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
                Center(child: _buildProfileHeader()),
                SizedBox(height: 20),
                _buildProfileDetails(),
                SizedBox(height: 20),
                _buildLogoutButton(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 4,
        onItemTapped: (index) {
          if (index == 0) Navigator.pushNamed(context, '/home');
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 50,
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : (_firestorePhotoUrl != null && _firestorePhotoUrl!.isNotEmpty
                ? NetworkImage(_firestorePhotoUrl!)
                : AssetImage('assets/profileNotLogin.png')) as ImageProvider,
            child: Align(
              alignment: Alignment.bottomRight,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 15,
                child: Icon(Icons.camera_alt, size: 20.0, color: Colors.black),
              ),
            ),
          ),
        ),
        SizedBox(height: 10),
        Text(
          nameController.text.isNotEmpty ? nameController.text : "User Name",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.yellow),
          textAlign: TextAlign.center,
        ),
        Text(
          _firestoreEmail ?? "user.email@example.com",
          style: TextStyle(fontSize: 14, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProfileDetails() {
    final localizations = AppLocalizations.of(context);
    // Determine if fields should be read-only based on NRIC presence.
    final bool isEkycComplete = nricController.text.isNotEmpty;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Color(0xFF404040),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          buildEditableRow(
              'assets/profileicon2.png',
              AppLocalizations.of(context).translate('profile_set_name_hint'),
              nameController,
              readOnly: isEkycComplete,
              hint: isEkycComplete ? "Verified via eKYC" : "Enter your name"
          ),
          buildEditableRow('assets/profileicon3.png', AppLocalizations.of(context).translate('profile_mobile_number'), phoneController),
          buildEditableRow(
              'assets/profileicon4.png',
              AppLocalizations.of(context).translate('profile_nric'),
              nricController,
              readOnly: true, // This is correct
              hint: "From eKYC"
          ),
          buildEditableRow('assets/profileicon5.png', AppLocalizations.of(context).translate('profile_home_address'), addressController),
          buildEditableRow('assets/profileicon6.png', AppLocalizations.of(context).translate('profile_city'), cityController),
          buildEditableRow('assets/profileicon7.png', AppLocalizations.of(context).translate('profile_postcode'), postcodeController),
          buildEditableRow('assets/profileicon7.png', 'State', stateController),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(horizontal: 80, vertical: 12),
      ),
      onPressed: _signOut,
      child: Text(
        AppLocalizations.of(context).translate('profile_logout'),
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget buildEditableRow(String iconPath, String label, TextEditingController controller, {bool readOnly = false, String? hint}) {
    return ListTile(
      leading: Image.asset(iconPath, height: 24, width: 24),
      title: TextField(
        controller: controller,
        readOnly: readOnly,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }
}
