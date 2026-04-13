import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../models/match_analysis_models.dart';

class MatchAnalysisApi {
  MatchAnalysisApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl {
    return AppConfig.apiBaseUrl;
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, String> _headers({String? token}) => {
    'Content-Type': 'application/json',
    if (token != null && token.trim().isNotEmpty)
      'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _decodeMap(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
      return <String, dynamic>{};
    }
    throw MatchAnalysisApiException(
      _extractError(response),
      response.statusCode,
    );
  }

  List<dynamic> _decodeList(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded;
      }
      return const [];
    }
    throw MatchAnalysisApiException(
      _extractError(response),
      response.statusCode,
    );
  }

  String _extractError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        final message = decoded['message'];
        if (message is List) {
          return message.join(', ');
        }
        return message.toString();
      }
    } catch (_) {
      // ignore parse errors
    }
    return 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}';
  }

  Future<List<String>> getColorPresets({String? token}) async {
    final response = await _client.get(
      _uri('/analysis/color-presets'),
      headers: _headers(token: token),
    );
    final data = _decodeMap(response);
    final presets = (data['presets'] as List? ?? const [])
        .map((e) => e.toString())
        .toList(growable: false);
    presets.sort();
    return presets;
  }

  Future<List<AnalysisJobSummary>> listJobs({String? token}) async {
    final response = await _client.get(
      _uri('/analysis/jobs'),
      headers: _headers(token: token),
    );
    final list = _decodeList(response);
    return list
        .whereType<Map>()
        .map(
          (e) => AnalysisJobSummary.fromJson(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<UploadedBackendFileRef> uploadFile({
    required String filePath,
    String? filename,
    String? token,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/uploads'));
    if (token != null && token.trim().isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final effectiveFilename = (filename != null && filename.trim().isNotEmpty)
        ? filename.trim()
        : _basename(filePath);
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: effectiveFilename,
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return UploadedBackendFileRef.fromJson(_decodeMap(response));
  }

  Future<AnalysisJobSummary> createJob(
    AnalysisCreateJobRequest request, {
    String? token,
  }) async {
    final response = await _client.post(
      _uri('/analysis/jobs'),
      headers: _headers(token: token),
      body: jsonEncode(request.toJson()),
    );
    return AnalysisJobSummary.fromJson(_decodeMap(response));
  }

  Future<AnalysisJobSummary> getJob(String jobId, {String? token}) async {
    final response = await _client.get(
      _uri('/analysis/jobs/$jobId'),
      headers: _headers(token: token),
    );
    return AnalysisJobSummary.fromJson(_decodeMap(response));
  }

  Future<AnalysisJobSummary> cancelJob(String jobId, {String? token}) async {
    final response = await _client.post(
      _uri('/analysis/jobs/$jobId/cancel'),
      headers: _headers(token: token),
      body: jsonEncode(const <String, dynamic>{}),
    );
    return AnalysisJobSummary.fromJson(_decodeMap(response));
  }

  Future<void> deleteJob(String jobId, {String? token}) async {
    final response = await _client.delete(
      _uri('/analysis/jobs/$jobId'),
      headers: _headers(token: token),
    );
    _decodeMap(response);
  }

  Future<AnalysisJobResultEnvelope> getJobResult(
    String jobId, {
    String? token,
  }) async {
    final response = await _client.get(
      _uri('/analysis/jobs/$jobId/result'),
      headers: _headers(token: token),
    );
    return AnalysisJobResultEnvelope.fromJson(_decodeMap(response));
  }

  void dispose() {
    _client.close();
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    return index >= 0 ? normalized.substring(index + 1) : normalized;
  }
}

class MatchAnalysisApiException implements Exception {
  const MatchAnalysisApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => 'MatchAnalysisApiException($statusCode): $message';
}
