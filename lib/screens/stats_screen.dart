import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/sleep_service.dart';
import 'package:intl/intl.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          '睡眠统计',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF4E65FF),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4E65FF),
                Color(0xFF92EFFD),
              ],
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<SleepService>(
          builder: (context, sleepService, child) {
            final weeklyData = sleepService.getWeeklyData();
            final averageDuration = sleepService.getAverageDuration();
            final averageQuality = sleepService.getAverageQuality();
            final sleepGoal = sleepService.sleepGoal;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  
                  // 统计概览卡片
                  _buildStatsOverview(
                    context,
                    averageDuration: averageDuration,
                    averageQuality: averageQuality,
                    sleepGoal: sleepGoal,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 周睡眠图表卡片
                  _buildWeeklyChartCard(weeklyData, sleepGoal),
                  
                  const SizedBox(height: 24),
                  
                  // 睡眠历史记录卡片
                  _buildSleepHistoryCard(sleepService.sleepSessions),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 建美的周睡眠图表卡片
  Widget _buildWeeklyChartCard(List<WeeklySleepData> weeklyData, int sleepGoal) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4E65FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFF4E65FF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '过去7天睡眠时长',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    const Color(0xFF4E65FF).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: BarChart(
                  _buildBarChartData(weeklyData, sleepGoal),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 睡眠历史记录卡片
  Widget _buildSleepHistoryCard(List<SleepSession> sessions) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C88FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Color(0xFF9C88FF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '睡眠历史',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSleepHistory(sessions),
          ],
        ),
      ),
    );
  }
  // 构建统计概览卡片
  Widget _buildStatsOverview(
    BuildContext context, {
    required Duration averageDuration,
    required double averageQuality,
    required int sleepGoal,
  }) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                '睡眠概览',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.access_time_rounded,
                      title: '平均睡眠',
                      value: '${averageDuration.inHours}h ${averageDuration.inMinutes.remainder(60)}m',
                      color: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.star_rounded,
                      title: '平均质量',
                      value: averageQuality.toStringAsFixed(1),
                      color: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.flag_rounded,
                      title: '睡眠目标',
                      value: '$sleepGoal 小时',
                      color: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建单个统计项
  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 构建柱状图数据
  BarChartData _buildBarChartData(
    List<WeeklySleepData> weeklyData,
    int sleepGoal,
  ) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: sleepGoal + 2, // 图表最大值比目标值高2小时，留出空间
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final sleepData = weeklyData[groupIndex];
            final hours = sleepData.duration.inHours;
            final minutes = sleepData.duration.inMinutes.remainder(60);
            final durationText = '${hours}h ${minutes}m';
            
            return BarTooltipItem(
              '${DateFormat.E().format(sleepData.date)}: $durationText',
              const TextStyle(color: Colors.white),
            );
          },
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          top: BorderSide.none,
          right: BorderSide.none,
          left: BorderSide(color: Colors.grey, width: 0.5),
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      gridData: FlGridData(
        show: true,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          // 突出显示目标线
          if (value == sleepGoal.toDouble()) {
            return FlLine(
              color: Colors.green,
              strokeWidth: 2,
              dashArray: [5, 5],
            );
          }
          return FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < weeklyData.length) {
                return Text(
                  DateFormat.E().format(weeklyData[index].date),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}h',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              );
            },
            interval: 1,
          ),
        ),
      ),
      barGroups: weeklyData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final hours = data.duration.inMinutes / 60;
        
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: hours,
              width: 20,
              color: hours >= sleepGoal ? Colors.green : Colors.blueAccent,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }).toList(),
    );
  }

  // 构建睡眠历史记录列表
  Widget _buildSleepHistory(List<SleepSession> sessions) {
    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey[50]!,
              Colors.grey[100]!,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.sentiment_neutral_rounded,
              color: Colors.grey[400],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              '还没有睡眠记录',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '开始你的第一次睡眠跟踪吧！',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // 按时间倒序排列，确保显示最新的记录
    final sortedSessions = List<SleepSession>.from(sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    
    return Column(
      children: sortedSessions.take(5).map((session) {
        final duration = session.endTime.difference(session.startTime);
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFF9C88FF).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF9C88FF).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C88FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        DateFormat('MM月dd日').format(session.startTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9C88FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('HH:mm').format(session.startTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '睡眠时长: ${hours}h ${minutes}m',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < session.quality
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: i < session.quality
                              ? Colors.amber
                              : Colors.grey[300],
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}