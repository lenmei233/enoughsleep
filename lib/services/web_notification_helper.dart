// Web平台专用的通知帮助类
import 'dart:html' as html;

class WebNotificationHelper {
  static bool get isNotificationSupported {
    try {
      return html.window.navigator.permissions != null && 
             html.Notification.supported;
    } catch (e) {
      return false;
    }
  }
  
  static String get permission {
    try {
      return html.Notification.permission ?? 'denied';
    } catch (e) {
      return 'denied';
    }
  }
  
  static Future<String> requestPermission() async {
    try {
      final permission = await html.Notification.requestPermission();
      return permission ?? 'denied';
    } catch (e) {
      return 'denied';
    }
  }
  
  static void showNotification(String title, String body) {
    try {
      final permission = html.Notification.permission ?? 'denied';
      if (permission == 'granted') {
        html.Notification(title, body: body, icon: '/favicon.png');
      }
    } catch (e) {
      print('发送Web通知失败: $e');
    }
  }
}