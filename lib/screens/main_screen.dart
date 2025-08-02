import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
import '../db/schedule_api_service.dart';
import 'pomodoro_screen.dart';
import 'todo_screen.dart';
import 'settings_screen.dart';
import 'dictionary_screen.dart';
import 'speech_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<ScheduleData> _schedule = [];
  bool _isLoading = true;
  final ScheduleApiService _scheduleService = ScheduleApiService();

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen();
      case 2:
        return const PomodoroScreen();
      case 3:
        return TodoScreen(
          onBackToMain: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        );
      case 4:
        return const DictionaryScreen();
      default:
        return _buildPlaceholderScreen();
    }
  }

  Widget _buildHomeScreen() {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFFF7D8C5), // Always peach, even in dark mode
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Image.asset(
                  'assets/mainScreenImg.jpg',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
              child: Text(
                'Daily Schedule',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _schedule.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_note,
                            size: 64,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[600]
                                : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '오늘 예정된 일정이 없습니다',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '마이크 버튼을 눌러 새로운 일정을 추가해보세요',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[500]
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 0,
                      ),
                      itemCount: _schedule.length,
                      itemBuilder: (context, index) {
                        final item = _schedule[index];
                        final isLast = index == _schedule.length - 1;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 24,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 48,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: CustomPaint(
                                        painter: DottedLinePainter(
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFF444444)
                                              : Colors.grey[400]!,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF2C2C2E)
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF444444)
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : Colors.black87,
                                                  ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark
                                                  ? Colors.deepPurple
                                                        .withOpacity(0.3)
                                                  : Colors.deepPurple
                                                        .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              item.category,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? Colors.deepPurple[200]
                                                    : Colors.deepPurple[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.time} • ${item.date}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color:
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                      ),
                                      if (item.description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          item.description,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color:
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey[300]
                                                    : Colors.grey[700],
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          bottom: 24.0,
          right: 24.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 새로고침 버튼
              FloatingActionButton(
                heroTag: "refresh",
                mini: true,
                onPressed: () {
                  _loadSchedule();
                },
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFDBE8F2),
                child: Icon(
                  Icons.refresh,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              // 음성 인식 버튼
              FloatingActionButton(
                heroTag: "speech",
                onPressed: () async {
                  // 음성 인식 모달 표시
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return const SpeechModal();
                    },
                  );

                  // 일정이 추가되었다면 새로고침
                  if (result == true) {
                    _loadSchedule();
                  }
                },
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFDBE8F2),
                child: Icon(
                  Icons.mic,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Coming Soon!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This feature is under development',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 오늘 날짜의 스케줄을 조회
      final today = DateTime.now();
      final dateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      print('📅 오늘 날짜로 스케줄 조회: $dateString');

      // 실제 API 호출
      final schedules = await _scheduleService.fetchSchedules(date: dateString);

      setState(() {
        _schedule = schedules;
        _isLoading = false;
      });

      print('📅 로드된 스케줄 개수: ${schedules.length}');
    } catch (e) {
      print('❌ 스케줄 로드 오류: $e');
      setState(() {
        _schedule = [];
        _isLoading = false;
      });

      // 에러 발생 시 사용자에게 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('스케줄을 불러오는데 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _selectedIndex == 0
          ? AppBar(
              centerTitle: true,
              title: const Text(
                'Study Planner',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            )
          : null,
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;
  DottedLinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    double dashHeight = 4, dashSpace = 4, startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
