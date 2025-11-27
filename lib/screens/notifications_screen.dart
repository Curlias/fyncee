import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/supabase_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  
  // Método helper para obtener colores según el tema
  Color get backgroundColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.background 
      : FynceeColors.lightBackground;
  
  Color get surfaceColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.surface 
      : FynceeColors.lightSurface;
  
  Color get textPrimaryColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.textPrimary 
      : FynceeColors.lightTextPrimary;
  
  Color get textSecondaryColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.textSecondary 
      : FynceeColors.lightTextSecondary;
  
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }
  
  Future<void> _loadNotifications() async {
    final notifications = await SupabaseService().getNotifications();
    if (mounted) {
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    }
  }
  
  Future<void> _markAsRead(int id) async {
    await SupabaseService().markNotificationAsRead(id);
    _loadNotifications();
  }
  
  Future<void> _markAllAsRead() async {
    await SupabaseService().markAllNotificationsAsRead();
    _loadNotifications();
  }
  
  Future<void> _deleteNotification(int id) async {
    await SupabaseService().deleteNotification(id);
    _loadNotifications();
  }
  
  String _getNotificationIcon(String type) {
    switch (type) {
      case 'budget_alert':
        return '⚠️';
      case 'goal_completed':
        return '🎉';
      case 'reminder':
        return '⏰';
      case 'achievement':
        return '🏆';
      default:
        return '📢';
    }
  }
  
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'budget_alert':
        return Colors.orange;
      case 'goal_completed':
        return Colors.green;
      case 'reminder':
        return Colors.blue;
      case 'achievement':
        return Colors.purple;
      default:
        return FynceeColors.primary;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['read'] == false).length;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notificaciones',
              style: TextStyle(
                color: textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount sin leer',
                style: TextStyle(
                  color: textSecondaryColor.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Leer todas',
                style: TextStyle(
                  color: FynceeColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
                ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: FynceeColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 40,
              color: FynceeColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay notificaciones',
            style: TextStyle(
              color: textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Te avisaremos cuando haya algo nuevo',
            style: TextStyle(
              color: textSecondaryColor.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['read'] == true;
    final type = notification['type'] as String;
    final title = notification['title'] as String;
    final message = notification['message'] as String;
    final createdAt = DateTime.parse(notification['created_at'] as String);
    final timeAgo = _getTimeAgo(createdAt);
    
    return Dismissible(
      key: Key(notification['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification['id'] as int);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isRead 
              ? FynceeColors.surface.withValues(alpha: 0.5)
              : FynceeColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: !isRead
              ? Border.all(color: FynceeColors.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (!isRead) {
                _markAsRead(notification['id'] as int);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getNotificationColor(type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _getNotificationIcon(type),
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Contenido
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: textPrimaryColor,
                                  fontSize: 15,
                                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: FynceeColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: TextStyle(
                            color: textSecondaryColor.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            color: textSecondaryColor.withValues(alpha: 0.6),
                            fontSize: 12,
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
      ),
    );
  }
  
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return DateFormat('d MMM', 'es').format(dateTime);
    } else if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? "s" : ""}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? "s" : ""}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? "s" : ""}';
    } else {
      return 'Ahora';
    }
  }
}
