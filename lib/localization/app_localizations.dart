import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      // General
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'submit': 'Submit',
      'next': 'Next',
      'cancel': 'Cancel',
      'error': 'Error',
      'success': 'Success',
      'pending': 'Pending',
      'approve': 'Approve',
      'reject': 'Reject',
      'approved': 'Approved',
      'disapprove': 'Disapprove',
      'issued': 'Issued',
      'all': 'All',
      'date': 'Date',
      'name': 'Name',
      'status': 'Status',
      'search': 'Search',
      'filter': 'Filter',
      'sort': 'Sort',

      // HomePage
      'search_hint_admin': 'Admin here...',
      'search_hint_staff': 'Staff here...',
      'search_hint_asnaf': 'Asnaf here...',
      'upcoming_activities': 'Upcoming Activities',
      'get_points': 'Get @points pts',
      'no_location': 'No location',
      'search_page': 'Search Page',
      'shopping_page': 'Shopping Page',
      'inbox_page': 'Inbox Page',
      'profile_page': 'Profile Page',

      // LoginPage
      'login_title': 'Sign up or log in',
      'login_subtitle': 'Select your preferred method to continue',
      'login_google': 'Continue with Google',
      'login_email': 'Continue with Email',
      'login_not_implemented': 'Email sign-in not implemented yet.',
      'login_failed': 'Google sign-in canceled or failed.',
      'login_error': 'Google sign-in error: @error',

      // AmountPage
      'help_asnaf_by_amount': 'Help Asnaf by Amount',
      'other': 'Other',
      'donor_info': 'Donor’s information',
      'tax_exemption_q': 'Would you like a tax exemption letter to be sent to you?',
      'designation': 'Designation',
      'select': 'Select',
      'full_name': 'Full Name',
      'enter_full_name': 'Enter full name',
      'email': 'Email',
      'enter_email': 'Enter email',
      'contact_number': 'Contact Number',
      'enter_mobile_number': 'Enter mobile number',
      'payment_method': 'Payment Method',
      'card': 'Card',
      'fpx': 'FPX',
      'donate_now': 'Donate Now',
      'fix_errors_prompt': 'Please fix the errors before submitting.',
      'select_amount_prompt': 'Please select or enter an amount.',
      'valid_amount_prompt': 'Please enter a valid amount.',
      'donation_processing': 'Donation processing... Please follow payment instructions.',
      'full_name_required': 'Full name is required',
      'email_required': 'Email is required',
      'valid_email_prompt': 'Enter a valid email address',
      'contact_required': 'Contact number is required',
      'contact_must_be_digits': 'Must be 9-10 digits',
      'amount_must_be_number': 'Please enter a number',
      'amount_gt_one': 'Amount must be greater than RM1',

      // ApplicationReviewScreen
      'app_under_review': 'Your application is under review!',
      'app_review_notify': 'We\'re currently reviewing your application.\nWe\'ll notify your result within 6-7 business days.',

      // ApplicationsScreen
      'your_app_status': 'Your Application Status',
      'track_app_submitted': 'Track applications you’ve submitted.',
      'search_code': 'Search Code',
      'no_applications_found': 'No applications found',
      'submitted': 'Submitted',
      'completed': 'Completed',
      'rewards': 'Rewards',

      "dashboard_verify_applications": "Verify Applications",
      "dashboard_issue_reward": "Issue Reward",
      "dashboard_view_reports": "View Reports",
      "dashboard_manage_user": "Manage User",
      "dashboard_help_asnaf": "Help Asnaf",
      "dashboard_apply_aid": "Apply Aid",
      "dashboard_application_status": "Application Status",
      "dashboard_redeem_rewards": "Redeem Rewards",
      "dashboard_submit_application": "Submit Application",
      "dashboard_asnaf_vouchers": "Asnaf Vouchers",
      "dashboard_monitor_applications": "Monitor Applications",
      "dashboard_manage_events": "Manage Events",
      "userpoints_points": "Points",
      "userpoints_pickup_item": "Pickup Item",
      "userpoints_checkin_event": "Check-In Event",
      "userpoints_help_attendance": "Help Attendance",
      "userpoints_checkin_description": "Earn points by confirming\nyour attendance",

  "login_title": "Sign up or log in",
  "login_subtitle": "Select your preferred method to continue",
  "login_google": "Continue with Google",
  "login_email": "Continue with Email",
  "login_failed": "Google sign-in canceled or failed.",
  "login_error": "Google sign-in error: @error",
  "login_not_implemented": "Email sign-in not implemented yet.",
  "profile_set_name_hint": "Set your name",
  "profile_change_photo": "Change profile photo",
  "profile_no_email": "No Email Available",
  "profile_set_username": "Set username",
  "profile_mobile_number": "Mobile Number",
  "profile_nric": "NRIC",
  "profile_home_address": "Home Address",
  "profile_city": "City",
  "profile_postcode": "Postcode",
  "profile_logout": "Logout",
  "profile_login": "Login",

    },
    'ms': {
      // General
      'ok': 'OK',
      'yes': 'Ya',
      'no': 'Tidak',
      'submit': 'Hantar',
      'next': 'Seterusnya',
      'cancel': 'Batal',
      'error': 'Ralat',
      'success': 'Berjaya',
      'pending': 'Menunggu',
      'approve': 'Lulus',
      'reject': 'Tolak',
      'approved': 'Diluluskan',
      'disapprove': 'Tidak Lulus',
      'issued': 'Dikeluarkan',
      'all': 'Semua',
      'date': 'Tarikh',
      'name': 'Nama',
      'status': 'Status',
      'search': 'Cari',
      'filter': 'Tapis',
      'sort': 'Susun',

      // HomePage
      'search_hint_admin': 'Admin di sini...',
      'search_hint_staff': 'Staf di sini...',
      'search_hint_asnaf': 'Asnaf di sini...',
      'upcoming_activities': 'Aktiviti Akan Datang',
      'get_points': 'Dapat @points mata',
      'no_location': 'Tiada lokasi',
      'search_page': 'Halaman Carian',
      'shopping_page': 'Halaman Membeli-belah',
      'inbox_page': 'Halaman Peti Masuk',
      'profile_page': 'Halaman Profil',

      // LoginPage
      'login_title': 'Daftar atau log masuk',
      'login_subtitle': 'Pilih kaedah pilihan anda untuk meneruskan',
      'login_google': 'Teruskan dengan Google',
      'login_email': 'Teruskan dengan E-mel',
      'login_not_implemented': 'Log masuk e-mel belum dilaksanakan.',
      'login_failed': 'Log masuk Google dibatalkan atau gagal.',
      'login_error': 'Ralat log masuk Google: @error',

      // AmountPage
      'help_asnaf_by_amount': 'Bantu Asnaf melalui Jumlah',
      'other': 'Lain-lain',
      'donor_info': 'Maklumat Penderma',
      'tax_exemption_q': 'Adakah anda mahu surat pengecualian cukai dihantar kepada anda?',
      'designation': 'Jawatan',
      'select': 'Pilih',
      'full_name': 'Nama Penuh',
      'enter_full_name': 'Masukkan nama penuh',
      'email': 'E-mel',
      'enter_email': 'Masukkan e-mel',
      'contact_number': 'Nombor Hubungan',
      'enter_mobile_number': 'Masukkan nombor telefon bimbit',
      'payment_method': 'Kaedah Pembayaran',
      'card': 'Kad',
      'fpx': 'FPX',
      'donate_now': 'Derma Sekarang',
      'fix_errors_prompt': 'Sila betulkan ralat sebelum menghantar.',
      'select_amount_prompt': 'Sila pilih atau masukkan jumlah.',
      'valid_amount_prompt': 'Sila masukkan jumlah yang sah.',
      'donation_processing': 'Memproses derma... Sila ikut arahan pembayaran.',
      'full_name_required': 'Nama penuh diperlukan',
      'email_required': 'E-mel diperlukan',
      'valid_email_prompt': 'Masukkan alamat e-mel yang sah',
      'contact_required': 'Nombor hubungan diperlukan',
      'contact_must_be_digits': 'Mestilah 9-10 digit',
      'amount_must_be_number': 'Sila masukkan nombor',
      'amount_gt_one': 'Jumlah mesti lebih besar daripada RM1',

      // ApplicationReviewScreen
      'app_under_review': 'Permohonan anda sedang disemak!',
      'app_review_notify': 'Kami sedang menyemak permohonan anda.\nKami akan memberitahu keputusan anda dalam 6-7 hari perniagaan.',

      // ApplicationsScreen
      'your_app_status': 'Status Permohonan Anda',
      'track_app_submitted': 'Jejaki permohonan yang telah anda hantar.',
      'search_code': 'Cari Kod',
      'no_applications_found': 'Tiada permohonan ditemui',
      'submitted': 'Dihantar',
      'completed': 'Selesai',
      'rewards': 'Ganjaran',

      "dashboard_verify_applications": "Sahkan Permohonan",
      "dashboard_issue_reward": "Keluarkan Ganjaran",
      "dashboard_view_reports": "Lihat Laporan",
      "dashboard_manage_user": "Urus Pengguna",
      "dashboard_help_asnaf": "Bantu Asnaf",
      "dashboard_apply_aid": "Mohon Bantuan",
      "dashboard_application_status": "Status Permohonan",
      "dashboard_redeem_rewards": "Tebus Ganjaran",
      "dashboard_submit_application": "Hantar Permohonan",
      "dashboard_asnaf_vouchers": "Baucar Asnaf",
      "dashboard_monitor_applications": "Pantau Permohonan",
      "dashboard_manage_events": "Urus Acara",
      "userpoints_points": "Mata",
      "userpoints_pickup_item": "Ambil Barangan",
      "userpoints_checkin_event": "Daftar Masuk Acara",
      "userpoints_help_attendance": "Bantu Kehadiran",
      "userpoints_checkin_description": "Dapatkan mata dengan mengesahkan\nkehadiran anda",

      "login_title": "Daftar atau log masuk",
      "login_subtitle": "Pilih kaedah pilihan anda untuk meneruskan",
      "login_google": "Teruskan dengan Google",
      "login_email": "Teruskan dengan E-mel",
      "login_failed": "Log masuk Google dibatalkan atau gagal.",
      "login_error": "Ralat log masuk Google: @error",
      "login_not_implemented": "Log masuk e-mel belum dilaksanakan.",
      "profile_set_name_hint": "Tetapkan nama anda",
      "profile_change_photo": "Tukar gambar profil",
      "profile_no_email": "Tiada E-mel Tersedia",
      "profile_set_username": "Tetapkan nama pengguna",
      "profile_mobile_number": "Nombor Telefon Bimbit",
      "profile_nric": "NRIC",
      "profile_home_address": "Alamat Rumah",
      "profile_city": "Bandar",
      "profile_postcode": "Poskod",
      "profile_logout": "Log keluar",
      "profile_login": "Log masuk"


    },
  };

  String translate(String key) {
    return _localizedStrings[locale.languageCode]![key] ?? key;
  }

  String translateWithArgs(String key, Map<String, String> args) {
    String translation = _localizedStrings[locale.languageCode]![key] ?? key;
    args.forEach((key, value) {
      translation = translation.replaceAll('@$key', value);
    });
    return translation;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ms'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}