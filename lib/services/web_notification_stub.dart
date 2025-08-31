// 非Web平台的通知占位实现
class WebNotificationHelper {
  static bool get isNotificationSupported => false;
  
  static String get permission => 'denied';
  
  static Future<String> requestPermission() async => 'denied';
  
  static void showNotification(String title, String body) {
    // 非Web平台不支持浏览器通知
    print('非Web平台: $title - $body');
  }
}