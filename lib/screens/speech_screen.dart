import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../language_provider.dart';
import '../db/schedule_api_service.dart';

class SpeechModal extends StatefulWidget {
  const SpeechModal({super.key});

  @override
  State<SpeechModal> createState() => _SpeechModalState();
}

class _SpeechModalState extends State<SpeechModal> {
  final SpeechToText _speechToText = SpeechToText();
  final ScheduleApiService _scheduleApiService = ScheduleApiService();
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _isListening = false;
  ScheduleData? _detectedSchedule;
  bool _isAddingSchedule = false;
  String? _apiResult;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// 음성 인식 초기화
  Future<void> _initSpeech() async {
    // 마이크 권한 확인
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }

    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// 음성 인식 시작
  Future<void> _startListening() async {
    if (!_speechEnabled) {
      await _initSpeech();
    }

    if (_speechEnabled) {
      setState(() {
        _isListening = true;
      });

      // 현재 설정된 언어 가져오기
      if (!mounted) return;
      final languageProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );
      final localeId = languageProvider.speechLocaleId;

      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30), // 30초 동안 듣기
        pauseFor: const Duration(seconds: 3), // 3초 무음시 정지
        localeId: localeId, // 설정된 언어 사용
        listenOptions: SpeechListenOptions(
          partialResults: true, // 실시간 결과 표시
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
      );
    }
  }

  /// 음성 인식 정지
  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  /// 음성 인식 결과 처리
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      // 스케줄 관련 텍스트인지 분석
      _detectedSchedule = _analyzeScheduleFromText(_lastWords);
    });
  }

  /// 텍스트에서 스케줄 정보 추출
  ScheduleData? _analyzeScheduleFromText(String text) {
    if (text.isEmpty) return null;

    // 스케줄 관련 키워드가 있는지 확인
    final scheduleKeywords = ['일정', '약속', '미팅', '과외', '수업', '회의', '만남'];
    bool hasScheduleKeyword = scheduleKeywords.any(
      (keyword) => text.contains(keyword),
    );

    // 시간 관련 키워드가 있는지 확인
    final timeKeywords = ['시', '분', '오전', '오후', '아침', '점심', '저녁', '밤'];
    bool hasTimeKeyword = timeKeywords.any((keyword) => text.contains(keyword));

    // 날짜 관련 키워드가 있는지 확인
    final dateKeywords = [
      '오늘',
      '내일',
      '모레',
      '이번',
      '다음',
      '월',
      '화',
      '수',
      '목',
      '금',
      '토',
      '일',
    ];
    bool hasDateKeyword = dateKeywords.any((keyword) => text.contains(keyword));

    if (!hasScheduleKeyword && !hasTimeKeyword && !hasDateKeyword) {
      return null; // 스케줄과 관련없는 텍스트
    }

    // 날짜 정보 추출
    String date = _extractDate(text);

    // 시간 정보 추출
    String time = _extractTime(text);

    // 제목 정보 추출 (간단한 키워드 기반)
    String title = _extractTitle(text);

    // 카테고리 추출
    String category = _extractCategory(text);

    return ScheduleData(
      title: title,
      date: date,
      time: time,
      category: category,
      description: text,
    );
  }

  /// 날짜 정보 추출
  String _extractDate(String text) {
    if (text.contains('오늘')) {
      return DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD 형식
    } else if (text.contains('내일')) {
      return DateTime.now()
          .add(const Duration(days: 1))
          .toString()
          .split(' ')[0];
    } else if (text.contains('모레')) {
      return DateTime.now()
          .add(const Duration(days: 2))
          .toString()
          .split(' ')[0];
    }

    // 기본값은 오늘
    return DateTime.now().toString().split(' ')[0];
  }

  /// 시간 정보 추출
  String _extractTime(String text) {
    // 시간 패턴 매칭 (예: "4시", "오후 2시", "14시 30분")
    RegExp timePattern = RegExp(r'(\d{1,2})시(\s*(\d{1,2})분)?');
    Match? match = timePattern.firstMatch(text);

    if (match != null) {
      int hour = int.parse(match.group(1) ?? '0');
      int minute = int.parse(match.group(3) ?? '0');

      // 오후인지 확인
      if (text.contains('오후') && hour < 12) {
        hour += 12;
      }

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    return '09:00'; // 기본값
  }

  /// 제목 추출
  String _extractTitle(String text) {
    if (text.contains('과외')) return '과외';
    if (text.contains('수업')) return '수업';
    if (text.contains('미팅') || text.contains('회의')) return '회의';
    if (text.contains('약속')) return '약속';
    if (text.contains('만남')) return '만남';

    return '일정'; // 기본값
  }

  /// 카테고리 추출
  String _extractCategory(String text) {
    if (text.contains('과외') || text.contains('수업')) return '교육';
    if (text.contains('미팅') || text.contains('회의')) return '업무';
    if (text.contains('약속') || text.contains('만남')) return '개인';

    return '기타'; // 기본값
  }

  /// 스케줄 추가 API 호출
  Future<void> _addScheduleToServer() async {
    if (_detectedSchedule == null) return;

    setState(() {
      _isAddingSchedule = true;
      _apiResult = null;
    });

    try {
      final result = await _scheduleApiService.addSchedule(_detectedSchedule!);

      setState(() {
        _apiResult = result['success']
            ? '✅ ${result['message']}'
            : '❌ ${result['message']}';
      });

      if (result['success']) {
        // 성공 시 스낵바 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _apiResult = '❌ 스케줄 추가 중 오류가 발생했습니다: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isAddingSchedule = false;
      });
    }
  }

  /// 스케줄 정보 행 위젯 생성
  Widget _buildScheduleInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '음성 인식',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '언어: ${languageProvider.displayName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 음성 인식 상태 표시
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _speechEnabled
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _speechEnabled ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _speechEnabled ? Icons.mic : Icons.mic_off,
                      color: _speechEnabled ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _speechEnabled ? '음성 인식 사용 가능' : '음성 인식 사용 불가',
                      style: TextStyle(
                        color: _speechEnabled ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 인식된 텍스트 표시
              Container(
                width: double.infinity,
                height: 150,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '인식된 텍스트:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          _lastWords.isEmpty
                              ? '음성을 인식하면 여기에 표시됩니다.'
                              : _lastWords,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: _lastWords.isEmpty
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 스케줄 분석 결과 표시
              if (_detectedSchedule != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Text(
                            '스케줄 인식됨',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 분석된 스케줄 정보
                      _buildScheduleInfoRow('제목', _detectedSchedule!.title),
                      _buildScheduleInfoRow('날짜', _detectedSchedule!.date),
                      _buildScheduleInfoRow('시간', _detectedSchedule!.time),
                      _buildScheduleInfoRow(
                        '카테고리',
                        _detectedSchedule!.category,
                      ),

                      const SizedBox(height: 16),

                      // add-schedule 함수 호출 예시
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'add-schedule 함수 호출 예시:',
                              style: TextStyle(
                                color: Colors.green[300],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'addSchedule({\n'
                              '  "title": "${_detectedSchedule!.title}",\n'
                              '  "date": "${_detectedSchedule!.date}",\n'
                              '  "time": "${_detectedSchedule!.time}",\n'
                              '  "category": "${_detectedSchedule!.category}",\n'
                              '  "description": "${_detectedSchedule!.description}"\n'
                              '})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 스케줄 추가 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isAddingSchedule
                              ? null
                              : _addScheduleToServer,
                          icon: _isAddingSchedule
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.add_circle_outline),
                          label: Text(
                            _isAddingSchedule ? '추가 중...' : '스케줄 추가하기',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                      // API 결과 표시
                      if (_apiResult != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _apiResult!.startsWith('✅')
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _apiResult!.startsWith('✅')
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          child: Text(
                            _apiResult!,
                            style: TextStyle(
                              color: _apiResult!.startsWith('✅')
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 30),

              // 음성 인식 버튼
              Column(
                children: [
                  if (_isListening)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hearing, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            '듣고 있습니다...',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 시작 버튼
                      ElevatedButton.icon(
                        onPressed: _speechEnabled && !_isListening
                            ? _startListening
                            : null,
                        icon: const Icon(Icons.mic),
                        label: const Text('음성 인식 시작'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),

                      // 정지 버튼
                      ElevatedButton.icon(
                        onPressed: _isListening ? _stopListening : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('정지'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 텍스트 초기화 버튼
                  TextButton.icon(
                    onPressed:
                        _lastWords.isNotEmpty || _detectedSchedule != null || _apiResult != null
                        ? () {
                            setState(() {
                              _lastWords = '';
                              _detectedSchedule = null;
                              _apiResult = null;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.clear),
                    label: const Text('전체 지우기'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }
}
