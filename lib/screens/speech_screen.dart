import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../language_provider.dart';

class SpeechModal extends StatefulWidget {
  const SpeechModal({super.key});

  @override
  State<SpeechModal> createState() => _SpeechModalState();
}

class _SpeechModalState extends State<SpeechModal> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _isListening = false;

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20.0),
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
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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
              height: 200,
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
                        _lastWords.isEmpty ? '음성을 인식하면 여기에 표시됩니다.' : _lastWords,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                  onPressed: _lastWords.isNotEmpty
                      ? () {
                          setState(() {
                            _lastWords = '';
                          });
                        }
                      : null,
                  icon: const Icon(Icons.clear),
                  label: const Text('텍스트 지우기'),
                ),
              ],
            ),
          ],
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
