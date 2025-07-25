import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../widgets/custom_bottom_nav.dart';
import 'pomodoro_screen.dart';
import 'todo_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<dynamic> _schedule = [];
  bool _isLoading = true;

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
        return const TodoScreen();
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
              color: const Color(0xFFF8DCC6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Image.asset(
                  'assets/mainScreenImg.jpg',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 0, 8),
              child: Text(
                'Daily Schedule',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
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
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 24,
                                  color: Colors.black87,
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 32,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: CustomPaint(
                                      painter: DottedLinePainter(),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                '${item['start']} - ${item['end']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          bottom: 24.0,
          right: 24.0,
          child: FloatingActionButton(
            onPressed: () {
              // TODO: 채팅 기능 연결
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('채팅 기능 준비 중!')));
            },
            backgroundColor: const Color(0xFFDBE8F2),
            child: const Icon(Icons.chat),
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
          Icon(
            Icons.construction,
            size: 64,
            color: Colors.grey,
          ),
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
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSchedule() async {
    final String jsonString = await rootBundle.loadString(
      'dumy/daily_schedule.json',
    );
    final List<dynamic> jsonData = json.decode(jsonString);
    setState(() {
      _schedule = jsonData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0 ? AppBar(
        centerTitle: true,
        title: const Text(
          'Study Planner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ) : null,
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      backgroundColor: Colors.white,
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 2.0;
    const dashSpace = 4.0;
    double startY = 0;
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
