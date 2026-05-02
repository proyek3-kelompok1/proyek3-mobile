class ApiConstants {
  static const String baseUrl = "http://10.0.2.2:8000/api";
  static const String education = "$baseUrl/education";
  static const String services = "$baseUrl/services";
  static const String booking = "$baseUrl/bookings";
  static const String bookingHistory = "$baseUrl/bookings";
  static const String medicalRecords = "$baseUrl/medical-records";
  static String medicalRecordPdf(int id) => "$baseUrl/medical-records/$id/pdf";
  static const String checkQueue = "$baseUrl/bookings/check-queue";
  static const String queueList = "$baseUrl/bookings/queue";
  static const String doctors = "$baseUrl/doctors";
  static const String consultations = "$baseUrl/consultations";
  static const String googleLogin = "$baseUrl/auth/google";
  static const String login = "$baseUrl/auth/login";
  static const String register = "$baseUrl/auth/register";
  static const String verifyOtp = "$baseUrl/auth/verify-otp";
  static const String resendOtp = "$baseUrl/auth/resend-otp";
  static const String aiHistory = "$baseUrl/ai/history";
  static const String aiChat = "$baseUrl/ai/chat";
  static const String aiDeleteHistory = "$baseUrl/ai/history/delete";
  static const String profile = "$baseUrl/user";
  static const String updateProfile = "$baseUrl/user/profile";
  static const String updateFcmToken = "$baseUrl/user/fcm-token";
  static const String logout = "$baseUrl/logout";
}


