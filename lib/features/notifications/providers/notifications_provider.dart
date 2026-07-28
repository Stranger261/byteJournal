import 'dart:async';
import 'package:blog_app/features/notifications/data/notification_model.dart';
import 'package:blog_app/features/notifications/data/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsProvider extends ChangeNotifier {
  final _service = NotificationService();
  static const _pageSize = 20;

  final List<NotificationModel> _notifications = [];
  int _page = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  int _unreadCount = 0;

  RealtimeChannel? _channel;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get hasMore => _hasMore;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  Future<void> loadInitial() async {
    _page = 0;
    _hasMore = true;
    _notifications.clear();
    _error = null;
    notifyListeners();
    await Future.wait([_fetchPage(), refreshUnreadCount()]);
  }

  Future<void> refreshPage() async {
    _page = 0;
    _hasMore = true;
    await _fetchPage(isRefresh: true);
    await refreshUnreadCount();
  }

  Future<void> loadMore() async {
    if (_isLoading || _isRefreshing || !_hasMore) return;
    await _fetchPage();
  }

  Future<void> _fetchPage({bool isRefresh = false}) async {
    if (isRefresh) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }
    _error = null;
    notifyListeners();

    try {
      final newItems = await _service.getNotifications(
        page: _page,
        pageSize: _pageSize,
      );

      if (isRefresh) {
        _notifications
          ..clear()
          ..addAll(newItems);
      } else {
        _notifications.addAll(newItems);
      }
      _hasMore = newItems.length == _pageSize;
      _page++;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (isRefresh) {
        _isRefreshing = false;
      } else {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await _service.getUnreadCount();
      notifyListeners();
    } catch (_) {
      // keep previous count on failure
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1 || _notifications[index].isRead) return;

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    if (_unreadCount > 0) _unreadCount--;
    notifyListeners();

    try {
      await _service.markAsRead(notificationId);
    } catch (_) {
      _notifications[index] = _notifications[index].copyWith(isRead: false);
      _unreadCount++;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    final unreadIndexes = <int>[];
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) unreadIndexes.add(i);
    }
    if (unreadIndexes.isEmpty) return;

    for (final i in unreadIndexes) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _unreadCount = 0;
    notifyListeners();

    try {
      await _service.markAllAsRead();
    } catch (_) {
      for (final i in unreadIndexes) {
        _notifications[i] = _notifications[i].copyWith(isRead: false);
      }
      _unreadCount = unreadIndexes.length;
      notifyListeners();
    }
  }

  // --- Realtime ---

  void subscribeToRealtime() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _channel != null) return;

    _channel = Supabase.instance.client
        .channel('notifications:recipient_id=eq.$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: userId,
          ),
          callback: (payload) => _handleInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: userId,
          ),
          callback: (payload) => _handleUpdate(payload.newRecord),
        )
        .subscribe();
  }

  Future<void> _handleInsert(Map<String, dynamic> row) async {
    // avoid duplicate if this client itself triggered the fetch already
    if (_notifications.any((n) => n.id == row['id'])) return;

    final full = await _service.getNotificationById(row['id'] as String);
    if (full == null) return;

    _notifications.insert(0, full);
    if (!full.isRead) _unreadCount++;
    notifyListeners();
  }

  void _handleUpdate(Map<String, dynamic> row) {
    final id = row['id'] as String;
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final isRead = row['is_read'] as bool? ?? false;
    final wasRead = _notifications[index].isRead;
    if (isRead == wasRead) return;

    _notifications[index] = _notifications[index].copyWith(isRead: isRead);
    if (isRead && !wasRead) {
      if (_unreadCount > 0) _unreadCount--;
    } else if (!isRead && wasRead) {
      _unreadCount++;
    }
    notifyListeners();
  }

  void unsubscribeFromRealtime() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }
  }

  void clear() {
    _notifications.clear();
    _unreadCount = 0;
    _page = 0;
    _hasMore = true;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unsubscribeFromRealtime();
    super.dispose();
  }
}
