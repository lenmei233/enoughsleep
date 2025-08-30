# Flutter相关
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }

# 保持睡眠服务相关类
-keep class com.lenmei233.enoughsleep.** { *; }

# SharedPreferences相关（用于数据存储）
-keep class androidx.preference.** { *; }

# Provider相关（状态管理）
-keep class * extends provider.** { *; }

# 图表库相关
-keep class com.github.mikephil.charting.** { *; }

# 其他Flutter插件
-dontwarn io.flutter.embedding.**

# 保持序列化类
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# 避免混淆枚举
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}