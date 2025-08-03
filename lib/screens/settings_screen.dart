import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import '../main.dart';
import '../language_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showStudyStreaks = false;
  Map<DateTime, int> _studyData = {};

  @override
  void initState() {
    super.initState();
    _loadStudyData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadStudyData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // 오늘 접속 기록 저장
    await prefs.setBool('study_$todayKey', true);

    // 임시로 08.01일 기록 추가
    final august1 = DateTime(today.year, 8, 1);
    final august1Key =
        '${august1.year}-${august1.month.toString().padLeft(2, '0')}-${august1.day.toString().padLeft(2, '0')}';
    await prefs.setBool('study_$august1Key', true);

    // 저장된 모든 study 데이터 로드
    final keys = prefs.getKeys().where((key) => key.startsWith('study_'));
    final studyData = <DateTime, int>{};

    for (final key in keys) {
      if (prefs.getBool(key) == true) {
        final dateStr = key.substring(6); // 'study_' 제거
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          studyData[date] = 1;
        }
      }
    }

    setState(() {
      _studyData = studyData;
    });
  }

  void _toggleStudyStreaks() {
    setState(() {
      _showStudyStreaks = !_showStudyStreaks;
    });
  }

  void _showLanguageDialog(
    BuildContext context,
    LanguageProvider languageProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '언어 선택',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppLanguage.values.map((language) {
              final isSelected = languageProvider.currentLanguage == language;
              return ListTile(
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
                title: Text(
                  language.displayName,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Theme.of(context).primaryColor : null,
                  ),
                ),
                subtitle: Text(
                  language.englishName,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                onTap: () async {
                  await languageProvider.setLanguage(language);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sectionPadding = const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 12,
    );
    final itemPadding = const EdgeInsets.symmetric(vertical: 8);
    final iconBg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF232325)
        : Colors.grey[200];
    final iconRadius = 18.0;
    final labelStyle = TextStyle(
      fontWeight: FontWeight.w500,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white70
          : Colors.grey[700],
      fontSize: 15,
    );
    final headingStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black87,
    );
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).scaffoldBackgroundColor,
        foregroundColor:
            Theme.of(context).appBarTheme.foregroundColor ??
            (Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black),
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        children: [
          Padding(
            padding: sectionPadding,
            child: Text('Appearance', style: headingStyle),
          ),
          Padding(
            padding: sectionPadding.copyWith(top: 0, bottom: 0),
            child: Column(
              children: [
                // Theme row with toggle switch
                _SettingsListItem(
                  icon: Icons.brightness_6,
                  iconBg: iconBg,
                  iconRadius: iconRadius,
                  title: 'Theme',
                  trailing: Switch(
                    value: themeProvider.mode == AppThemeMode.dark,
                    onChanged: (val) {
                      Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).setTheme(val ? AppThemeMode.dark : AppThemeMode.light);
                    },
                    activeColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.blueAccent,
                    inactiveThumbColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Colors.grey[400],
                    inactiveTrackColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[300],
                  ),
                  padding: itemPadding,
                ),
                GestureDetector(
                  onTap: () => _showLanguageDialog(context, languageProvider),
                  child: _SettingsListItem(
                    icon: Icons.language,
                    iconBg: iconBg,
                    iconRadius: iconRadius,
                    title: 'Language',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(languageProvider.displayName, style: labelStyle),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                          size: 20,
                        ),
                      ],
                    ),
                    padding: itemPadding,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: sectionPadding,
            child: Text('Notifications', style: headingStyle),
          ),
          Padding(
            padding: sectionPadding.copyWith(top: 0, bottom: 0),
            child: Column(
              children: [
                _SettingsToggleItem(
                  icon: Icons.notifications_active,
                  iconBg: iconBg,
                  iconRadius: iconRadius,
                  title: 'Push Notifications',
                  value: true,
                  onChanged: null,
                  padding: itemPadding,
                ),
                _SettingsToggleItem(
                  icon: Icons.wb_sunny,
                  iconBg: iconBg,
                  iconRadius: iconRadius,
                  title: 'Morning Briefings',
                  value: false,
                  onChanged: null,
                  padding: itemPadding,
                ),
                GestureDetector(
                  onTap: _toggleStudyStreaks,
                  child: _SettingsListItem(
                    icon: Icons.emoji_events,
                    iconBg: iconBg,
                    iconRadius: iconRadius,
                    title: 'Track Study Streaks',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showStudyStreaks ? '숨기기' : '보기',
                          style: labelStyle,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _showStudyStreaks
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                          size: 20,
                        ),
                      ],
                    ),
                    padding: itemPadding,
                  ),
                ),
              ],
            ),
          ),
          // Study Streaks Heatmap Calendar
          if (_showStudyStreaks) ...[
            const SizedBox(height: 24),
            Padding(
              padding: sectionPadding,
              child: Text('Study Activity', style: headingStyle),
            ),
            Padding(
              padding: sectionPadding.copyWith(top: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF232325)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '학습 활동 히트맵',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    HeatMapCalendar(
                      datasets: _studyData,
                      colorMode: ColorMode.opacity,
                      defaultColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]!
                          : Colors.grey[300]!,
                      flexible: true,
                      colorsets: {
                        1: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue[300]!
                            : Colors.blue[500]!,
                      },
                      onClick: (date) {
                        final hasData = _studyData.containsKey(date);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              hasData
                                  ? '${date.month}/${date.day}에 학습했습니다!'
                                  : '${date.month}/${date.day}에는 학습 기록이 없습니다.',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '학습 없음',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.blue[300]
                                : Colors.blue[500],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '학습함',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsListItem extends StatelessWidget {
  final IconData icon;
  final Color? iconBg;
  final double iconRadius;
  final String title;
  final Widget trailing;
  final EdgeInsets padding;
  const _SettingsListItem({
    required this.icon,
    required this.iconBg,
    required this.iconRadius,
    required this.title,
    required this.trailing,
    required this.padding,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(iconRadius),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _SettingsToggleItem extends StatelessWidget {
  final IconData icon;
  final Color? iconBg;
  final double iconRadius;
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final EdgeInsets padding;
  const _SettingsToggleItem({
    required this.icon,
    required this.iconBg,
    required this.iconRadius,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.padding,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(iconRadius),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.blueAccent,
            inactiveThumbColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[700]
                : Colors.grey[400],
            inactiveTrackColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[300],
          ),
        ],
      ),
    );
  }
}
