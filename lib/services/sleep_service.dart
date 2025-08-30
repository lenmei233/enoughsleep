import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  List<SleepSession> get sleepSessions => _sleepSessions;
  DateTime? get startTime => _startTime;
  bool get isTracking => _isTracking;
  int get currentQuality => _currentQuality;
  int get sleepGoal => _sleepGoal;
  bool get notificationsEnabled => _notificationsEnabled;

  SleepService() {
    _loadData();
  }

  void startTracking() {
    _startTime = DateTime.now();
    _isTracking = true;
    notifyListeners();
  }

  void stopTracking() {
    _isTracking = false;
    notifyListeners();
  }

  void setQuality(int quality) {
    _currentQuality = quality;
    notifyListeners();
  }

  void saveSession() {
    if (_startTime != null) {
      final newSession = SleepSession(
        startTime: _startTime!,
        endTime: DateTime.now(),
        quality: _currentQuality,
      );
      _sleepSessions.add(newSession);
      _startTime = null;
      _currentQuality = 3;
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

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save sleep sessions
    final sessionsJson = _sleepSessions.map((s) => s.toJson()).toList();
    prefs.setString('sleepSessions', json.encode(sessionsJson));
    
    // Save settings
    prefs.setInt('sleepGoal', _sleepGoal);
    prefs.setBool('notificationsEnabled', _notificationsEnabled);
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
    
    notifyListeners();
  }
}
