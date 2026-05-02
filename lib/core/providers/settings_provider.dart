import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'locale_code';

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('id');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Theme
    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    // Load Locale
    final localeCode = prefs.getString(_localeKey) ?? 'id';
    _locale = Locale(localeCode);
    
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, _themeMode.index);
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
  }

  String translate(String key) {
    final Map<String, Map<String, String>> localizedValues = {
      'id': {
        'settings': 'Pengaturan',
        'general_prefs': 'Preferensi Umum',
        'notifications': 'Notifikasi',
        'notifications_sub': 'Update status booking & promo',
        'dark_mode': 'Mode Gelap',
        'dark_mode_sub': 'Tampilan gelap yang nyaman',
        'app_language': 'Bahasa Aplikasi',
        'security_account': 'Keamanan & Akun',
        'change_password': 'Ubah Kata Sandi',
        'change_password_sub': 'Perbarui keamanan akun Anda',
        'about_us': 'Tentang Kami',
        'rate_us': 'Beri Rating',
        'rate_us_sub': 'Bantu kami menjadi lebih baik',
        'select_language': 'Pilih Bahasa',
        'my_profile': 'Profil Saya',
        'account_settings': 'Pengaturan Akun',
        'edit_account': 'Edit Akun',
        'edit_account_sub': 'Ubah nama, email, dan lainnya',
        'settings_sub': 'Notifikasi, bahasa, dan keamanan',
        'support_more': 'Dukungan & Lainnya',
        'help_center': 'Pusat Bantuan',
        'help_center_sub': 'FAQ dan kontak dukungan',
        'logout': 'Keluar',
        'logout_sub': 'Keluar dari akun Anda',
        'guest': 'Pengguna',
        'halo': 'Halo, {name}! 🐾',
        'harimu_menyenangkan': 'Semoga harimu menyenangkan',
        'search': 'Cari',
        'konsultasi_cepat': 'Konsultasi hewan\npeliharaan Anda dengan\ncepat dan mudah.',
        'antrian': 'Antrian',
        'konsultasi': 'Konsultasi',
        'rekam_medis': 'Rekam Medis',
        'dokter_paw': 'DokterPaw',
        'edukasi': 'Edukasi',
        'lihat_semua': 'Lihat semua',
        'riwayat_booking': 'Riwayat Booking',
        'belum_ada_booking': 'Belum ada booking aktif',
        'booking_sekarang': 'Booking sekarang untuk hewan peliharaan Anda',
        'kali_dilihat': 'kali dilihat',
        'edit_profile': 'Edit Profil',
        'personal_info': 'Informasi Pribadi',
        'full_name': 'Nama Lengkap',
        'email_address': 'Alamat Email',
        'phone_number': 'Nomor Telepon',
        'save_changes': 'Simpan Perubahan',
        'profile_updated': 'Profil berhasil diperbarui!',
        'profile_update_failed': 'Gagal memperbarui profil.',
        'name_empty_error': 'Nama tidak boleh kosong',
        'help_center_title': 'Pusat Bantuan',
        'ready_to_help': 'Kami siap membantu Anda',
        'need_fast_help': 'Butuh Bantuan Cepat?',
        'chat_direct': 'Chat langsung',
        'send_message': 'Kirim pesan',
        'faq_title': 'Pertanyaan Umum',
        'legal_policy': 'Hukum & Kebijakan',
        'terms_sub': 'Aturan penggunaan aplikasi',
        'privacy_sub': 'Cara kami menjaga data Anda',
        'cannot_open_wa': 'Tidak dapat membuka WhatsApp',
        'cannot_open_email': 'Tidak dapat membuka aplikasi Email',
        'faq1_q': 'Bagaimana cara booking?',
        'faq1_a': 'Pilih layanan yang Anda inginkan di halaman utama, pilih jadwal yang tersedia, lalu lakukan konfirmasi pembayaran.',
        'faq2_q': 'Apakah bisa membatalkan janji?',
        'faq2_a': 'Ya, pembatalan dapat dilakukan maksimal 24 jam sebelum jadwal melalui menu riwayat transaksi.',
        'faq3_q': 'Metode pembayaran apa saja?',
        'faq3_a': 'Kami mendukung berbagai metode pembayaran mulai dari Transfer Bank hingga E-Wallet (Gopay, OVO, Dana).',
        'privacy_title': 'Kebijakan Privasi',
        'last_updated': 'Terakhir diperbarui: 30 April 2026',
        'privacy_sec1_t': 'Informasi yang Kami Kumpulkan',
        'privacy_sec1_c': 'Kami mengumpulkan informasi yang Anda berikan secara langsung kepada kami, seperti saat Anda membuat akun, melakukan booking, atau menghubungi layanan pelanggan. Ini termasuk nama, alamat email, nomor telepon, dan informasi hewan peliharaan Anda.',
        'privacy_sec2_t': 'Penggunaan Informasi',
        'privacy_sec2_c': 'Kami menggunakan informasi tersebut untuk memproses booking Anda, memberikan layanan konsultasi, mengelola akun Anda, dan mengirimkan informasi penting terkait layanan kami.',
        'privacy_sec3_t': 'Keamanan Data',
        'privacy_sec3_c': 'Kami menerapkan langkah-langkah keamanan teknis dan organisasional yang tepat untuk melindungi data pribadi Anda dari akses, penggunaan, atau pengungkapan yang tidak sah.',
        'privacy_sec4_t': 'Berbagi Informasi',
        'privacy_sec4_c': 'Kami tidak menjual atau menyewakan informasi pribadi Anda kepada pihak ketiga. Kami hanya berbagi informasi dengan dokter hewan atau mitra layanan yang diperlukan untuk memenuhi kebutuhan medis hewan Anda.',
        'privacy_sec5_t': 'Hak Anda',
        'privacy_sec5_c': 'Anda memiliki hak untuk mengakses, memperbarui, atau meminta penghapusan data pribadi Anda kapan saja melalui pengaturan akun atau dengan menghubungi kami.',
        'privacy_sec6_t': 'Cookies',
        'privacy_sec6_c': 'Aplikasi kami dapat menggunakan cookies dan teknologi serupa untuk meningkatkan pengalaman pengguna dan menganalisis penggunaan aplikasi.',
        'terms_title': 'Syarat & Ketentuan',
        'terms_sec1_t': 'Penerimaan Ketentuan',
        'terms_sec1_c': 'Dengan menggunakan aplikasi DVPets, Anda setuju untuk terikat oleh Syarat & Ketentuan ini. Jika Anda tidak menyetujui bagian apa pun dari ketentuan ini, Anda tidak diperbolehkan menggunakan layanan kami.',
        'terms_sec2_t': 'Layanan Kami',
        'terms_sec2_c': 'DVPets menyediakan platform untuk booking layanan kesehatan hewan, konsultasi dokter hewan, dan manajemen rekam medis hewan peliharaan Anda.',
        'terms_sec3_t': 'Akun Pengguna',
        'terms_sec3_c': 'Anda bertanggung jawab untuk menjaga kerahasiaan informasi akun dan kata sandi Anda. Anda setuju untuk bertanggung jawab atas semua aktivitas yang terjadi di bawah akun Anda.',
        'terms_sec4_t': 'Kebijakan Pembatalan',
        'terms_sec4_c': 'Pembatalan janji temu dapat dilakukan melalui aplikasi paling lambat 24 jam sebelum waktu yang dijadwalkan. Pembatalan yang dilakukan kurang dari 24 jam mungkin akan dikenakan biaya administrasi.',
        'terms_sec5_t': 'Batasan Tanggung Jawab',
        'terms_sec5_c': 'DVPets tidak bertanggung jawab atas kerugian atau kerusakan yang timbul dari penggunaan layanan kami, kecuali jika diwajibkan oleh hukum yang berlaku.',
        'terms_sec6_t': 'Perubahan Ketentuan',
        'terms_sec6_c': 'Kami berhak untuk mengubah Syarat & Ketentuan ini kapan saja. Perubahan akan berlaku segera setelah dipublikasikan di aplikasi.',
      },
      'en': {
        'settings': 'Settings',
        'general_prefs': 'General Preferences',
        'notifications': 'Notifications',
        'notifications_sub': 'Update booking status & promos',
        'dark_mode': 'Dark Mode',
        'dark_mode_sub': 'Comfortable dark appearance',
        'app_language': 'App Language',
        'security_account': 'Security & Account',
        'change_password': 'Change Password',
        'change_password_sub': 'Update your account security',
        'about_us': 'About Us',
        'rate_us': 'Rate Us',
        'rate_us_sub': 'Help us become better',
        'select_language': 'Select Language',
        'my_profile': 'My Profile',
        'account_settings': 'Account Settings',
        'edit_account': 'Edit Account',
        'edit_account_sub': 'Change name, email, and more',
        'settings_sub': 'Notifications, language, and security',
        'support_more': 'Support & More',
        'help_center': 'Help Center',
        'help_center_sub': 'FAQ and support contact',
        'logout': 'Logout',
        'logout_sub': 'Log out of your account',
        'guest': 'Guest User',
        'halo': 'Hello, {name}! 🐾',
        'harimu_menyenangkan': 'Have a nice day',
        'search': 'Search',
        'konsultasi_cepat': 'Consult your pet\nquickly and easily.',
        'antrian': 'Queue',
        'konsultasi': 'Consultation',
        'rekam_medis': 'Medical Record',
        'dokter_paw': 'PawDoctor',
        'edukasi': 'Education',
        'lihat_semua': 'See all',
        'riwayat_booking': 'Booking History',
        'belum_ada_booking': 'No active bookings',
        'booking_sekarang': 'Book now for your pet',
        'kali_dilihat': 'views',
        'edit_profile': 'Edit Profile',
        'personal_info': 'Personal Information',
        'full_name': 'Full Name',
        'email_address': 'Email Address',
        'phone_number': 'Phone Number',
        'save_changes': 'Save Changes',
        'profile_updated': 'Profile updated successfully!',
        'profile_update_failed': 'Failed to update profile.',
        'name_empty_error': 'Name cannot be empty',
        'help_center_title': 'Help Center',
        'ready_to_help': 'We are ready to help you',
        'need_fast_help': 'Need Fast Help?',
        'chat_direct': 'Chat directly',
        'send_message': 'Send message',
        'faq_title': 'Common Questions (FAQ)',
        'legal_policy': 'Legal & Policy',
        'terms_sub': 'Rules for using the application',
        'privacy_sub': 'How we take care of your data',
        'cannot_open_wa': 'Cannot open WhatsApp',
        'cannot_open_email': 'Cannot open Email application',
        'faq1_q': 'How to book?',
        'faq1_a': 'Select the service you want on the home page, choose an available schedule, then confirm payment.',
        'faq2_q': 'Can I cancel an appointment?',
        'faq2_a': 'Yes, cancellations can be made up to 24 hours before the schedule through the transaction history menu.',
        'faq3_q': 'What are the payment methods?',
        'faq3_a': 'We support various payment methods from Bank Transfer to E-Wallet (Gopay, OVO, Dana).',
        'privacy_title': 'Privacy Policy',
        'last_updated': 'Last updated: April 30, 2026',
        'privacy_sec1_t': 'Information We Collect',
        'privacy_sec1_c': 'We collect information that you provide directly to us, such as when you create an account, make a booking, or contact customer service. This includes your name, email address, phone number, and information about your pet.',
        'privacy_sec2_t': 'Use of Information',
        'privacy_sec2_c': 'We use that information to process your bookings, provide consultation services, manage your account, and send important information related to our services.',
        'privacy_sec3_t': 'Data Security',
        'privacy_sec3_c': 'We implement appropriate technical and organizational security measures to protect your personal data from unauthorized access, use, or disclosure.',
        'privacy_sec4_t': 'Sharing Information',
        'privacy_sec4_c': 'We do not sell or rent your personal information to third parties. We only share information with veterinarians or service partners as necessary to fulfill your pet\'s medical needs.',
        'privacy_sec5_t': 'Your Rights',
        'privacy_sec5_c': 'You have the right to access, update, or request the deletion of your personal data at any time through account settings or by contacting us.',
        'privacy_sec6_t': 'Cookies',
        'privacy_sec6_c': 'Our application may use cookies and similar technologies to enhance the user experience and analyze application usage.',
        'terms_title': 'Terms & Conditions',
        'terms_sec1_t': 'Acceptance of Terms',
        'terms_sec1_c': 'By using the DVPets application, you agree to be bound by these Terms & Conditions. If you do not agree to any part of these terms, you are not permitted to use our services.',
        'terms_sec2_t': 'Our Services',
        'terms_sec2_c': 'DVPets provides a platform for booking pet healthcare services, veterinarian consultations, and managing your pet\'s medical records.',
        'terms_sec3_t': 'User Account',
        'terms_sec3_c': 'You are responsible for maintaining the confidentiality of your account information and password. You agree to be responsible for all activities that occur under your account.',
        'terms_sec4_t': 'Cancellation Policy',
        'terms_sec4_c': 'Appointment cancellations can be made through the application no later than 24 hours before the scheduled time. Cancellations made less than 24 hours in advance may be subject to an administrative fee.',
        'terms_sec5_t': 'Limitation of Liability',
        'terms_sec5_c': 'DVPets is not responsible for any losses or damages arising from the use of our services, unless required by applicable law.',
        'terms_sec6_t': 'Changes to Terms',
        'terms_sec6_c': 'We reserve the right to change these Terms & Conditions at any time. Changes will be effective immediately upon publication in the application.',
      },
    };

    String text = localizedValues[_locale.languageCode]?[key] ?? key;
    return text;
  }
}
