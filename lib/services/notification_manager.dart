import 'package:flutter/material.dart';
import 'database_service.dart';

class NotificationItem {
  final String id;
  final String type; // 'achievement', 'friend_request', 'challenge', 'streak', 'level_up'
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
    'data': data,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
    id: json['id'],
    type: json['type'],
    title: json['title'],
    message: json['message'],
    createdAt: DateTime.parse(json['createdAt']),
    isRead: json['isRead'] ?? false,
    data: json['data'],
  );
}

class NotificationManager extends ChangeNotifier {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  List<NotificationItem> _notifications = [];
  bool _initialized = false;

  List<NotificationItem> get notifications => _notifications;
  List<NotificationItem> get unreadNotifications => _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;

  Future<void> initialize() async {
    if (_initialized) return;
    await _loadNotifications();
    _initialized = true;
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await DatabaseService.loadNotifications();
      if (data != null) {
        _notifications = (data['notifications'] as List?)
            ?.map((n) => NotificationItem.fromJson(n))
            .toList() ?? [];
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _saveNotifications() async {
    try {
      await DatabaseService.saveNotifications({
        'notifications': _notifications.map((n) => n.toJson()).toList(),
      });
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  Future<void> addNotification({
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      data: data,
    );

    _notifications.insert(0, notification);
    if (_notifications.length > 100) {
      _notifications = _notifications.take(100).toList();
    }
    
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = NotificationItem(
        id: _notifications[index].id,
        type: _notifications[index].type,
        title: _notifications[index].title,
        message: _notifications[index].message,
        createdAt: _notifications[index].createdAt,
        isRead: true,
        data: _notifications[index].data,
      );
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => NotificationItem(
      id: n.id,
      type: n.type,
      title: n.title,
      message: n.message,
      createdAt: n.createdAt,
      isRead: true,
      data: n.data,
    )).toList();
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications = [];
    await _saveNotifications();
    notifyListeners();
  }
}






