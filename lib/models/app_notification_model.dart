import 'package:intl/intl.dart';

class AppNotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? typeKey;
  final Map<String, dynamic> data;
  final String? readAt;
  final String createdAt;

  AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.typeKey,
    required this.data,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return AppNotificationModel(
      id: json['id'],
      type: json['type'],
      title: data['title'] ?? 'Notification',
      body: data['body'] ?? '',
      typeKey: data['type_key'],
      data: data,
      readAt: json['read_at'],
      createdAt: json['created_at'],
    );
  }

  String get formattedDate {
    try {
      final DateTime dt = DateTime.parse(createdAt).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (e) {
      return createdAt;
    }
  }
}
