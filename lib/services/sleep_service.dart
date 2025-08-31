import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:async';
// 条件导入：Web平台使用web_notification_helper，其他平台使用stub
import 'web_notification_helper.dart' if (dart.library.io) 'web_notification_stub.dart' as web_helper;

class SleepSession {
  final DateTime startTime;
  DateTime endTime;
  int quality;

  SleepSession({
    required this.startTime,
    required this.endTime,
    this.quality = 3,
  });

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'quality': quality,
    };
  }

  factory SleepSession.fromJson(Map<String, dynamic> json) {
    return SleepSession(
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      quality: json['quality'],
    );
  }
}

class WeeklySleepData {
  final DateTime date;
  final Duration duration;

  WeeklySleepData({
    required this.date,
    required this.duration,
  });
}

class SleepService extends ChangeNotifier {
  List<SleepSession> _sleepSessions = [];
  DateTime? _startTime;
  bool _isTracking = false;
  int _currentQuality = 3;
  int _sleepGoal = 8;
  bool _notificationsEnabled = true;
  
  // 睡眠提醒相关属性
  bool _bedtimeReminderEnabled = true;
  TimeOfDay _bedtimeReminderTime = const TimeOfDay(hour: 22, minute: 0); // 默认晚上10点
  
  // 本地通知实例
  FlutterLocalNotificationsPlugin? _localNotifications;
  bool _notificationsInitialized = false; // 添加初始化状态标志
  
  // 定时器用于定时通知
  Timer? _bedtimeTimer;
  DateTime? _nextReminderTime;
  
  // 最大睡眠时长限制（24小时）
  static const Duration maxSleepDuration = Duration(hours: 24);

  List<SleepSession> get sleepSessions => _sleepSessions;
  DateTime? get startTime => _startTime;
  bool get isTracking => _isTracking;
  int get currentQuality => _currentQuality;
  int get sleepGoal => _sleepGoal;
  bool get notificationsEnabled => _notificationsEnabled;
  
  // 睡眠提醒相关getter
  bool get bedtimeReminderEnabled => _bedtimeReminderEnabled;
  TimeOfDay get bedtimeReminderTime => _bedtimeReminderTime;
  DateTime? get nextReminderTime => _nextReminderTime;

  SleepService() {
    _loadData();
    // 延迟初始化通知，避免在构造函数中异步操作
    _initializeNotificationsDelayed();
  }
  
  // 清理资源
  @override
  void dispose() {
    _bedtimeTimer?.cancel();
    super.dispose();
  }
  
  // 延迟初始化通知
  void _initializeNotificationsDelayed() {
    // 使用 Future.microtask 确保在下一个事件循环中执行
    Future.microtask(() async {
      try {
        await _initializeNotifications();
        
        // 初始化完成后，如果提醒开启，则设置提醒
        if (_bedtimeReminderEnabled && _notificationsInitialized) {
          await Future.delayed(const Duration(seconds: 1));
          await _scheduleBedtimeReminder();
        }
      } catch (e) {
        print('通知初始化失败: $e');
      }
    });
  }

  void startTracking() {
    _startTime = DateTime.now();
    _isTracking = true;
    _saveTrackingState(); // 保存跟踪状态到本地存储
    notifyListeners();
  }

  void stopTracking() {
    _isTracking = false;
    _clearTrackingState(); // 清除跟踪状态
    notifyListeners();
  }

  void setQuality(int quality) {
    _currentQuality = quality;
    notifyListeners();
  }

  void saveSession() {
    if (_startTime != null) {
      var endTime = DateTime.now();
      var duration = endTime.difference(_startTime!);
      
      // 如果超过24小时，将结束时间设为开始时间+24小时
      if (duration > maxSleepDuration) {
        endTime = _startTime!.add(maxSleepDuration);
      }
      
      final newSession = SleepSession(
        startTime: _startTime!,
        endTime: endTime,
        quality: _currentQuality,
      );
      _sleepSessions.add(newSession);
      _startTime = null;
      _currentQuality = 3;
      _isTracking = false;
      _clearTrackingState(); // 清除跟踪状态
      _saveData();
      notifyListeners();
    }
  }

  void setSleepGoal(int goal) {
    _sleepGoal = goal;
    _saveData();
    notifyListeners();
  }

  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    _saveData();
    notifyListeners();
  }
  
  // 睡眠提醒设置方法
  void setBedtimeReminderEnabled(bool enabled) {
    _bedtimeReminderEnabled = enabled;
    if (enabled && _notificationsInitialized) {
      // 延迟调用，确保初始化完成
      Future.delayed(const Duration(milliseconds: 500), () {
        _scheduleBedtimeReminder();
      });
    } else if (!enabled && _notificationsInitialized) {
      // 异步调用取消方法
      Future.delayed(const Duration(milliseconds: 100), () {
        _cancelBedtimeReminder();
      });
    }
    _saveData();
    notifyListeners();
  }
  
  void setBedtimeReminderTime(TimeOfDay time) {
    _bedtimeReminderTime = time;
    if (_bedtimeReminderEnabled && _notificationsInitialized) {
      // 延迟调用，确保初始化完成
      Future.delayed(const Duration(milliseconds: 500), () {
        _scheduleBedtimeReminder();
      });
    }
    _saveData();
    notifyListeners();
  }

  void resetData() {
    _sleepSessions.clear();
    _saveData();
    notifyListeners();
  }

  // 获取最新的睡眠记录
  SleepSession? getLatestSleepSession() {
    if (_sleepSessions.isEmpty) return null;
    
    // 按时间排序，返回最新的记录
    final sortedSessions = List<SleepSession>.from(_sleepSessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return sortedSessions.first;
  }

  Duration getAverageDuration() {
    if (_sleepSessions.isEmpty) return Duration.zero;
    
    int totalMinutes = 0;
    for (var session in _sleepSessions) {
      totalMinutes += session.endTime.difference(session.startTime).inMinutes;
    }
    
    return Duration(minutes: totalMinutes ~/ _sleepSessions.length);
  }

  double getAverageQuality() {
    if (_sleepSessions.isEmpty) return 0;
    
    int totalQuality = 0;
    for (var session in _sleepSessions) {
      totalQuality += session.quality;
    }
    
    return totalQuality / _sleepSessions.length;
  }

  List<WeeklySleepData> getWeeklyData() {
    final now = DateTime.now();
    final weeklyData = <WeeklySleepData>[];
    
    // Create entries for each of the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      weeklyData.add(WeeklySleepData(
        date: date,
        duration: _getSleepDurationForDate(date),
      ));
    }
    
    return weeklyData;
  }

  Duration _getSleepDurationForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day + 1);
    
    Duration totalDuration = Duration.zero;
    
    for (var session in _sleepSessions) {
      // Check if the session started on this day or ended on this day
      if ((session.startTime.isAfter(startOfDay) && 
           session.startTime.isBefore(endOfDay)) ||
          (session.endTime.isAfter(startOfDay) && 
           session.endTime.isBefore(endOfDay)) ||
          (session.startTime.isBefore(startOfDay) && 
           session.endTime.isAfter(endOfDay))) {
        
        // Calculate overlap with this day
        final sessionStart = session.startTime.isBefore(startOfDay) 
            ? startOfDay 
            : session.startTime;
        final sessionEnd = session.endTime.isAfter(endOfDay)
            ? endOfDay
            : session.endTime;
        
        totalDuration += sessionEnd.difference(sessionStart);
      }
    }
    
    return totalDuration;
  }

  // 获取当前睡眠时长（实时计算）
  Duration get currentSleepDuration {
    if (_startTime == null || !_isTracking) {
      return Duration.zero;
    }
    
    final now = DateTime.now();
    final duration = now.difference(_startTime!);
    
    // 限制最大时长为24小时
    return duration > maxSleepDuration ? maxSleepDuration : duration;
  }
  
  // 检查是否达到最大睡眠时长
  bool get hasReachedMaxDuration {
    return currentSleepDuration >= maxSleepDuration;
  }
  
  // 保存跟踪状态到本地存储
  Future<void> _saveTrackingState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_startTime != null) {
      prefs.setString('trackingStartTime', _startTime!.toIso8601String());
      prefs.setBool('isTracking', true);
    }
  }
  
  // 清除跟踪状态
  Future<void> _clearTrackingState() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('trackingStartTime');
    prefs.setBool('isTracking', false);
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save sleep sessions
    final sessionsJson = _sleepSessions.map((s) => s.toJson()).toList();
    prefs.setString('sleepSessions', json.encode(sessionsJson));
    
    // Save settings
    prefs.setInt('sleepGoal', _sleepGoal);
    prefs.setBool('notificationsEnabled', _notificationsEnabled);
    
    // Save bedtime reminder settings
    prefs.setBool('bedtimeReminderEnabled', _bedtimeReminderEnabled);
    prefs.setInt('bedtimeReminderHour', _bedtimeReminderTime.hour);
    prefs.setInt('bedtimeReminderMinute', _bedtimeReminderTime.minute);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load sleep sessions
    final sessionsJson = prefs.getString('sleepSessions');
    if (sessionsJson != null && sessionsJson.isNotEmpty) {
      try {
        final List<dynamic> sessionsList = json.decode(sessionsJson);
        _sleepSessions = sessionsList
            .map((s) => SleepSession.fromJson(s))
            .toList();
      } catch (e) {
        // 如果数据解析失败，清空数据
        _sleepSessions = [];
        prefs.remove('sleepSessions');
      }
    } else {
      // 确保没有测试数据
      _sleepSessions = [];
    }
    
    // Load settings
    _sleepGoal = prefs.getInt('sleepGoal') ?? 8;
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    
    // Load bedtime reminder settings
    _bedtimeReminderEnabled = prefs.getBool('bedtimeReminderEnabled') ?? true;
    final reminderHour = prefs.getInt('bedtimeReminderHour') ?? 22;
    final reminderMinute = prefs.getInt('bedtimeReminderMinute') ?? 0;
    _bedtimeReminderTime = TimeOfDay(hour: reminderHour, minute: reminderMinute);
    
    // 注意：不在这里设置提醒，由 _initializeNotificationsDelayed 负责
    
    // 恢复睡眠跟踪状态
    _isTracking = prefs.getBool('isTracking') ?? false;
    final startTimeString = prefs.getString('trackingStartTime');
    
    if (_isTracking && startTimeString != null) {
      try {
        _startTime = DateTime.parse(startTimeString);
        
        // 检查是否超过24小时，如果超过则自动结束跟踪
        final now = DateTime.now();
        final duration = now.difference(_startTime!);
        
        if (duration > maxSleepDuration) {
          // 自动保存为24小时的睡眠记录
          final autoSession = SleepSession(
            startTime: _startTime!,
            endTime: _startTime!.add(maxSleepDuration),
            quality: 3, // 默认质量
          );
          _sleepSessions.add(autoSession);
          
          // 重置状态
          _startTime = null;
          _isTracking = false;
          _clearTrackingState();
          _saveData();
        }
      } catch (e) {
        // 如果解析失败，重置跟踪状态
        _startTime = null;
        _isTracking = false;
        _clearTrackingState();
      }
    }
    
    notifyListeners();
  }
  
  // ==================== 通知相关方法 ====================
  
  // 初始化通知
  Future<void> _initializeNotifications() async {
    try {
      // 根据平台进行不同的初始化
      if (kIsWeb) {
        // Web平台使用浏览器原生通知
        await _initializeWebNotifications();
        return;
      }
      
      // 桌面平台初始化
      _localNotifications = FlutterLocalNotificationsPlugin();
      
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      // Windows/Linux初始化设置
      const LinuxInitializationSettings initializationSettingsLinux =
          LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );
      
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
        macOS: initializationSettingsIOS,
        linux: initializationSettingsLinux,
      );
      
      final bool? initialized = await _localNotifications!.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          print('通知被点击: ${details.payload}');
        },
      );
      
      if (initialized == true) {
        // 请求权限
        await _requestNotificationPermissions();
        
        // 等待初始化完成
        await Future.delayed(const Duration(milliseconds: 500));
        
        _notificationsInitialized = true;
        print('桌面端通知初始化成功');
      } else {
        print('桌面端通知初始化失败');
      }
    } catch (e) {
      print('通知初始化异常: $e');
    }
  }
  
  // Web平台通知初始化
  Future<void> _initializeWebNotifications() async {
    try {
      _notificationsInitialized = true;
      print('Web平台通知初始化成功');
    } catch (e) {
      print('Web通知初始化异常: $e');
      _notificationsInitialized = true;
    }
  }
  
  // 请求通知权限
  Future<void> _requestNotificationPermissions() async {
    try {
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        print('通知权限请求结果: $status');
      }
    } catch (e) {
      print('权限请求异常: $e');
    }
  }
  
  // 安排睡眠提醒（使用定时器实现真正的定时通知）
  Future<void> _scheduleBedtimeReminder() async {
    if (!_bedtimeReminderEnabled) return;
    
    // 先取消现有的定时器
    await _cancelBedtimeReminder();
    
    // 计算下一次提醒时间
    final now = DateTime.now();
    final reminderTime = DateTime(
      now.year,
      now.month,
      now.day,
      _bedtimeReminderTime.hour,
      _bedtimeReminderTime.minute,
    );
    
    DateTime scheduledTime = reminderTime;
    if (scheduledTime.isBefore(now) || scheduledTime.isAtSameMomentAs(now)) {
      // 如果今天的时间已经过了，安排到明天
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    
    _nextReminderTime = scheduledTime;
    final duration = scheduledTime.difference(now);
    
    print('睡眠提醒已设置，将在 ${duration.inHours}小时${duration.inMinutes.remainder(60)}分钟后提醒');
    print('下次提醒时间: ${scheduledTime.year}-${scheduledTime.month.toString().padLeft(2, '0')}-${scheduledTime.day.toString().padLeft(2, '0')} ${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}');
    
    // 设置定时器
    _bedtimeTimer = Timer(duration, () async {
      await _sendBedtimeNotification();
      // 发送通知后，设置下一次提醒（第二天）
      _scheduleBedtimeReminder();
    });
    
    // 发送一个确认通知
    await _sendConfirmationNotification();
    
    notifyListeners(); // 通知UI更新
  }
  
  // 取消睡眠提醒
  Future<void> _cancelBedtimeReminder() async {
    if (_bedtimeTimer != null) {
      _bedtimeTimer!.cancel();
      _bedtimeTimer = null;
      _nextReminderTime = null;
      print('定时器已取消');
      notifyListeners(); // 通知UI更新
    }
  }
  
  // 发送睡眠提醒通知
  Future<void> _sendBedtimeNotification() async {
    try {
      if (kIsWeb) {
        // Web平台使用浏览器原生通知
        await _sendWebNotification(
          '🌙 睡眠时间到了！',
          '为了保持良好的睡眠质量，现在就该去睡觉了。晚安！😴'
        );
        return;
      }
      
      // 桌面平台使用flutter_local_notifications
      if (_localNotifications == null) {
        print('通知插件未初始化');
        return;
      }
      
      await _localNotifications!.show(
        1,
        '🌙 睡眠时间到了！',
        '为了保持良好的睡眠质量，现在就该去睡觉了。晚安！😴',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'bedtime_alert',
            '睡眠提醒',
            channelDescription: '在设定的时间提醒您去睡觉',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            autoCancel: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          linux: LinuxNotificationDetails(
            urgency: LinuxNotificationUrgency.critical,
          ),
        ),
      );
      
      print('睡眠提醒通知已发送');
    } catch (e) {
      print('发送睡眠提醒失败: $e');
    }
  }
  
  // 发送确认通知
  Future<void> _sendConfirmationNotification() async {
    try {
      if (kIsWeb) {
        // Web平台使用浏览器通知
        await _sendWebNotification(
          '✅ 睡眠提醒已设置',
          '您的睡眠提醒已设置为 ${_bedtimeReminderTime.hour.toString().padLeft(2, '0')}:${_bedtimeReminderTime.minute.toString().padLeft(2, '0')}，我们会在该时间提醒您。'
        );
        return;
      }
      
      // 桌面平台
      if (_localNotifications == null) return;
      
      await _localNotifications!.show(
        0,
        '✅ 睡眠提醒已设置',
        '您的睡眠提醒已设置为 ${_bedtimeReminderTime.hour.toString().padLeft(2, '0')}:${_bedtimeReminderTime.minute.toString().padLeft(2, '0')}，我们会在该时间提醒您。',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'bedtime_info',
            '睡眠提醒设置',
            channelDescription: '显示睡眠提醒设置信息',
            importance: Importance.low,
            priority: Priority.low,
            autoCancel: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: false,
          ),
          linux: LinuxNotificationDetails(),
        ),
      );
    } catch (e) {
      print('发送确认通知失败: $e');
    }
  }
  
  // 测试通知功能（立即发送通知）
  Future<void> testNotification() async {
    try {
      if (kIsWeb) {
        // Web平台使用浏览器通知
        await _sendWebNotification(
          '📢 测试通知',
          '这是一个测试通知，如果您能看到这条消息，说明通知功能正常工作！'
        );
        return;
      }
      
      // 桌面平台
      if (_localNotifications == null) {
        print('通知系统未初始化');
        return;
      }
      
      await _localNotifications!.show(
        999,
        '📢 测试通知',
        '这是一个测试通知，如果您能看到这条消息，说明通知功能正常工作！',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_notifications',
            '测试通知',
            channelDescription: '用于测试通知功能',
            importance: Importance.high,
            priority: Priority.high,
            autoCancel: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          linux: LinuxNotificationDetails(
            urgency: LinuxNotificationUrgency.normal,
          ),
        ),
      );
      
      print('测试通知已发送');
    } catch (e) {
      print('发送测试通知失败: $e');
    }
  }
  
  // Web浏览器通知发送（简化版）
  Future<void> _sendWebNotification(String title, String body) async {
    if (!kIsWeb) return;
    
    try {
      // 在Web平台，使用浏览器原生通知API
      print('=== 🔔 浏览器通知 🔔 ===');
      print('📢 $title');
      print('📝 $body');
      
      // 使用helper类发送通知
      if (web_helper.WebNotificationHelper.isNotificationSupported) {
        final permission = web_helper.WebNotificationHelper.permission;
        print('浏览器通知权限状态: $permission');
        
        if (permission == 'granted') {
          web_helper.WebNotificationHelper.showNotification(title, body);
          print('浏览器通知已发送！');
        } else if (permission == 'default') {
          final result = await web_helper.WebNotificationHelper.requestPermission();
          if (result == 'granted') {
            web_helper.WebNotificationHelper.showNotification(title, body);
            print('浏览器通知已发送！');
          } else {
            print('浏览器通知权限被拒绝');
          }
        } else {
          print('浏览器通知权限被禁用');
        }
      } else {
        print('浏览器不支持通知API');
      }
      
      print('=== 提示：请在浏览器设置中允许通知权限 ===');
      
    } catch (e) {
      print('Web通知发送异常: $e');
      print('降级为控制台输出: $title - $body');
    }
  }
}
