import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'app_http_client.dart';

// 스케줄 데이터 모델
class ScheduleData {
  final String title;
  final String date;
  final String time;
  final String category;
  final String description;

  ScheduleData({
    required this.title,
    required this.date,
    required this.time,
    required this.category,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'time': time,
      'category': category,
      'description': description,
    };
  }

  factory ScheduleData.fromJson(Map<String, dynamic> json) {
    return ScheduleData(
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class ScheduleApiService {
  // 기존 Supabase Function URL 사용
  final String baseUrl = dotenv.env['SUPABASE_FUNCTION_URL'] ?? '';
  final String token = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  final AppHttpClient _http = AppHttpClient();

  // 스케줄 API 엔드포인트
  String get scheduleUrl => '$baseUrl/test-schedule';

  /// 스케줄 추가
  Future<Map<String, dynamic>> addSchedule(ScheduleData scheduleData) async {
    try {
      final url = Uri.parse(scheduleUrl);
      
      print('📅 스케줄 추가 요청: $url');
      print('📄 데이터: ${json.encode(scheduleData.toJson())}');
      
      final response = await _http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(scheduleData.toJson()),
      );

      print('📡 응답 상태: ${response.statusCode}');
      print('📡 응답 본문: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': '스케줄이 성공적으로 추가되었습니다.',
          'data': responseData,
        };
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 스케줄 추가 오류: $e');
      return {
        'success': false,
        'message': '스케줄 추가에 실패했습니다: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// 스케줄 목록 조회 (향후 확장용)
  Future<List<ScheduleData>> fetchSchedules({String? date}) async {
    try {
      // TODO: 스케줄 조회 API가 준비되면 구현
      print('📅 스케줄 조회 기능은 아직 구현되지 않았습니다.');
      return [];
    } catch (e) {
      print('❌ 스케줄 조회 오류: $e');
      throw Exception('스케줄 조회에 실패했습니다: ${e.toString()}');
    }
  }

  /// 스케줄 수정 (향후 확장용)
  Future<Map<String, dynamic>> updateSchedule(String id, ScheduleData scheduleData) async {
    try {
      // TODO: 스케줄 수정 API가 준비되면 구현
      print('📅 스케줄 수정 기능은 아직 구현되지 않았습니다.');
      return {
        'success': false,
        'message': '스케줄 수정 기능은 아직 구현되지 않았습니다.',
      };
    } catch (e) {
      print('❌ 스케줄 수정 오류: $e');
      return {
        'success': false,
        'message': '스케줄 수정에 실패했습니다: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// 스케줄 삭제 (향후 확장용)
  Future<Map<String, dynamic>> deleteSchedule(String id) async {
    try {
      // TODO: 스케줄 삭제 API가 준비되면 구현
      print('📅 스케줄 삭제 기능은 아직 구현되지 않았습니다.');
      return {
        'success': false,
        'message': '스케줄 삭제 기능은 아직 구현되지 않았습니다.',
      };
    } catch (e) {
      print('❌ 스케줄 삭제 오류: $e');
      return {
        'success': false,
        'message': '스케줄 삭제에 실패했습니다: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }
}