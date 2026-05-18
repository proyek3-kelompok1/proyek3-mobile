import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ReverbService {
  static final ReverbService _instance = ReverbService._internal();
  factory ReverbService() => _instance;
  ReverbService._internal();

  PusherChannelsFlutter? _pusher;
  bool _isInitialized = false;
  String? _currentToken;

  // Reverb Configuration — sesuai Laravel .env lokal
  static const String appKey = 'aqk7uvcj07urqnwj9fss';
  static const String host = '10.0.160.138';
  static const int port = 8080;
  static const String scheme = 'http';
  static const String cluster = 'mt1';

  Future<void> init() async {
    if (_isInitialized) {
      debugPrint('🔌 Reverb already initialized');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentToken = prefs.getString('auth_token');

      if (_currentToken == null) {
        debugPrint('⚠️ No auth token found, skipping Reverb init');
        return;
      }

      _pusher = PusherChannelsFlutter.getInstance();

      await _pusher!.init(
        apiKey: appKey,
        cluster: cluster,
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onSubscriptionSucceeded: _onSubscriptionSucceeded,
        onEvent: _onEvent,
        onSubscriptionError: _onSubscriptionError,
        onDecryptionFailure: _onDecryptionFailure,
        onMemberAdded: _onMemberAdded,
        onMemberRemoved: _onMemberRemoved,
        onAuthorizer: _onAuthorizer,
      );

      await _pusher!.connect();
      _isInitialized = true;
      debugPrint('✅ Reverb WebSocket initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Reverb: $e');
      _isInitialized = false;
    }
  }

  // Custom authorizer for private channels
  dynamic _onAuthorizer(String channelName, String socketId, dynamic options) async {
    debugPrint('🔐 Authorizing channel: $channelName with socketId: $socketId');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        debugPrint('❌ No auth token for authorization');
        return null;
      }

      // Call Laravel broadcasting/auth endpoint
      final response = await _authorizeChannel(channelName, socketId, token);
      debugPrint('✅ Channel authorized: $channelName');
      return response;
    } catch (e) {
      debugPrint('❌ Authorization error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _authorizeChannel(
    String channelName,
    String socketId,
    String token,
  ) async {
    // This should call your Laravel broadcasting/auth endpoint
    final response = await http.post(
      Uri.parse('http://10.0.160.138:8000/broadcasting/auth'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'socket_id': socketId,
        'channel_name': channelName,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to authorize channel: ${response.statusCode}');
    }
  }

  void _onConnectionStateChange(String currentState, String previousState) {
    debugPrint('🔌 Connection state changed: $previousState -> $currentState');
  }

  void _onError(String message, int? code, dynamic e) {
    debugPrint('❌ Reverb error: $message (code: $code)');
  }

  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    debugPrint('✅ Subscribed to channel: $channelName');
  }

  void _onEvent(PusherEvent event) {
    debugPrint('📨 Event received: ${event.eventName} on ${event.channelName}');
    debugPrint('   Data: ${event.data}');
  }

  void _onSubscriptionError(String message, dynamic e) {
    debugPrint('❌ Subscription error: $message');
  }

  void _onDecryptionFailure(String event, String reason) {
    debugPrint('❌ Decryption failure: $event - $reason');
  }

  void _onMemberAdded(String channelName, PusherMember member) {
    debugPrint('👤 Member added to $channelName: ${member.userId}');
  }

  void _onMemberRemoved(String channelName, PusherMember member) {
    debugPrint('👤 Member removed from $channelName: ${member.userId}');
  }

  // Subscribe to a private consultation channel
  Future<PusherChannel?> subscribeToConsultation(
    int sessionId,
    Function(PusherEvent) onMessageReceived,
  ) async {
    if (!_isInitialized || _pusher == null) {
      debugPrint('⚠️ Reverb not initialized, initializing now...');
      await init();
    }

    if (_pusher == null) {
      debugPrint('❌ Failed to initialize Reverb');
      return null;
    }

    try {
      final channelName = 'private-consultation.$sessionId';
      debugPrint('📡 Subscribing to channel: $channelName');

      final channel = await _pusher!.subscribe(
        channelName: channelName,
        onEvent: onMessageReceived,
      );

      debugPrint('✅ Subscribed to consultation channel: $sessionId');
      return channel;
    } catch (e) {
      debugPrint('❌ Error subscribing to consultation: $e');
      return null;
    }
  }

  // Unsubscribe from a channel
  Future<void> unsubscribe(String channelName) async {
    if (_pusher == null) return;

    try {
      await _pusher!.unsubscribe(channelName: channelName);
      debugPrint('✅ Unsubscribed from: $channelName');
    } catch (e) {
      debugPrint('❌ Error unsubscribing: $e');
    }
  }

  // Disconnect from Reverb
  Future<void> disconnect() async {
    if (_pusher == null) return;

    try {
      await _pusher!.disconnect();
      _isInitialized = false;
      debugPrint('✅ Disconnected from Reverb');
    } catch (e) {
      debugPrint('❌ Error disconnecting: $e');
    }
  }

  // Reconnect to Reverb
  Future<void> reconnect() async {
    await disconnect();
    await init();
  }

  bool get isInitialized => _isInitialized;
}
