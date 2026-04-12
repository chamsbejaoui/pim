import 'dart:convert';

double _asDouble(Object? value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

int _asInt(Object? value, [int fallback = 0]) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

bool _asBool(Object? value, [bool fallback = false]) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    if (value.toLowerCase() == 'true') {
      return true;
    }
    if (value.toLowerCase() == 'false') {
      return false;
    }
  }
  return fallback;
}

String? _asStringOrNull(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, v) => MapEntry(key.toString(), v));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _asMapList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value.map(_asMap).toList();
}

enum AnalysisJobStatus { queued, running, completed, failed, canceled }

AnalysisJobStatus _parseStatus(String? raw) {
  switch (raw) {
    case 'queued':
      return AnalysisJobStatus.queued;
    case 'running':
      return AnalysisJobStatus.running;
    case 'completed':
      return AnalysisJobStatus.completed;
    case 'failed':
      return AnalysisJobStatus.failed;
    case 'canceled':
      return AnalysisJobStatus.canceled;
    default:
      return AnalysisJobStatus.queued;
  }
}

enum AnalysisPreset { balanced, best }

extension AnalysisPresetLabel on AnalysisPreset {
  String get apiValue => this == AnalysisPreset.best ? 'best' : 'balanced';

  String get label =>
      this == AnalysisPreset.best ? 'Best Accuracy' : 'Balanced';
}

class GoalDirectionOverride {
  const GoalDirectionOverride({
    required this.teamName,
    required this.direction,
  });

  final String teamName;
  final String direction; // left | right

  Map<String, dynamic> toJson() => {
    'teamName': teamName,
    'direction': direction,
  };
}

class UploadedBackendFileRef {
  const UploadedBackendFileRef({
    required this.url,
    required this.mimeType,
    required this.name,
    required this.size,
  });

  final String url;
  final String mimeType;
  final String name;
  final int size;

  factory UploadedBackendFileRef.fromJson(Map<String, dynamic> json) {
    return UploadedBackendFileRef(
      url: _asStringOrNull(json['url']) ?? '',
      mimeType: _asStringOrNull(json['mimeType']) ?? '',
      name: _asStringOrNull(json['name']) ?? '',
      size: _asInt(json['size']),
    );
  }
}

class AnalysisCreateJobRequest {
  const AnalysisCreateJobRequest({
    this.videoPath,
    this.videoUrl,
    required this.team1Name,
    required this.team1ShirtColor,
    required this.team2Name,
    required this.team2ShirtColor,
    this.enableOffside = false,
    this.analysisPreset = AnalysisPreset.best,
    this.trackerBackend,
    this.yoloWeights,
    this.frameStride,
    this.maxFrames,
    this.outputJsonPath,
    this.goalDirectionOverrides = const [],
  });

  final String? videoPath;
  final String? videoUrl;
  final String team1Name;
  final String team1ShirtColor;
  final String team2Name;
  final String team2ShirtColor;
  final bool enableOffside;
  final AnalysisPreset analysisPreset;
  final String? trackerBackend;
  final String? yoloWeights;
  final int? frameStride;
  final int? maxFrames;
  final String? outputJsonPath;
  final List<GoalDirectionOverride> goalDirectionOverrides;

  Map<String, dynamic> toJson() {
    final out = <String, dynamic>{
      'team1Name': team1Name,
      'team1ShirtColor': team1ShirtColor,
      'team2Name': team2Name,
      'team2ShirtColor': team2ShirtColor,
      'enableOffside': enableOffside,
      'analysisPreset': analysisPreset.apiValue,
    };
    if (videoPath != null && videoPath!.trim().isNotEmpty) {
      out['videoPath'] = videoPath;
    }
    if (videoUrl != null && videoUrl!.trim().isNotEmpty) {
      out['videoUrl'] = videoUrl;
    }
    if (trackerBackend != null && trackerBackend!.trim().isNotEmpty) {
      out['trackerBackend'] = trackerBackend;
    }
    if (yoloWeights != null && yoloWeights!.trim().isNotEmpty) {
      out['yoloWeights'] = yoloWeights;
    }
    if (frameStride != null) {
      out['frameStride'] = frameStride;
    }
    if (maxFrames != null) {
      out['maxFrames'] = maxFrames;
    }
    if (outputJsonPath != null && outputJsonPath!.trim().isNotEmpty) {
      out['outputJsonPath'] = outputJsonPath;
    }
    if (goalDirectionOverrides.isNotEmpty) {
      out['goalDirectionOverrides'] = goalDirectionOverrides
          .map((e) => e.toJson())
          .toList();
    }
    return out;
  }
}

class AnalysisJobProgress {
  const AnalysisJobProgress({
    required this.phase,
    required this.progress,
    required this.progressPercent,
    this.framesProcessed,
    this.currentFrameIndex,
    this.totalFrames,
    this.fpsEffective,
    this.playersDetected,
    this.ballDetected,
    this.trackerBackendEffective,
    this.trackerStatus,
    this.raw,
  });

  final String phase;
  final double progress;
  final double progressPercent;
  final int? framesProcessed;
  final int? currentFrameIndex;
  final int? totalFrames;
  final double? fpsEffective;
  final int? playersDetected;
  final bool? ballDetected;
  final String? trackerBackendEffective;
  final String? trackerStatus;
  final Map<String, dynamic>? raw;

  factory AnalysisJobProgress.fromJson(Map<String, dynamic> json) {
    return AnalysisJobProgress(
      phase: _asStringOrNull(json['phase']) ?? 'queued',
      progress: _asDouble(json['progress']),
      progressPercent: _asDouble(json['progressPercent']),
      framesProcessed: json['framesProcessed'] == null
          ? null
          : _asInt(json['framesProcessed']),
      currentFrameIndex: json['currentFrameIndex'] == null
          ? null
          : _asInt(json['currentFrameIndex']),
      totalFrames: json['totalFrames'] == null
          ? null
          : _asInt(json['totalFrames']),
      fpsEffective: json['fpsEffective'] == null
          ? null
          : _asDouble(json['fpsEffective']),
      playersDetected: json['playersDetected'] == null
          ? null
          : _asInt(json['playersDetected']),
      ballDetected: json['ballDetected'] == null
          ? null
          : _asBool(json['ballDetected']),
      trackerBackendEffective: _asStringOrNull(json['trackerBackendEffective']),
      trackerStatus: _asStringOrNull(json['trackerStatus']),
      raw: json['raw'] is Map ? _asMap(json['raw']) : null,
    );
  }
}

class AnalysisJobSummary {
  const AnalysisJobSummary({
    required this.jobId,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
    required this.outputJsonPath,
    required this.resultAvailable,
    required this.request,
    required this.progress,
    this.lastProgressAt,
    this.pid,
    this.cliSummary,
    this.error,
    this.stdoutTail = const [],
    this.stderrTail = const [],
  });

  final String jobId;
  final AnalysisJobStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String outputJsonPath;
  final bool resultAvailable;
  final AnalysisJobRequestSnapshot request;
  final AnalysisJobProgress progress;
  final DateTime? lastProgressAt;
  final int? pid;
  final Map<String, dynamic>? cliSummary;
  final AnalysisJobErrorSummary? error;
  final List<String> stdoutTail;
  final List<String> stderrTail;

  bool get isTerminal =>
      status == AnalysisJobStatus.completed ||
      status == AnalysisJobStatus.failed ||
      status == AnalysisJobStatus.canceled;

  factory AnalysisJobSummary.fromJson(Map<String, dynamic> json) {
    final logs = _asMap(json['logs']);
    return AnalysisJobSummary(
      jobId: (_asStringOrNull(json['jobId']) ?? ''),
      status: _parseStatus(_asStringOrNull(json['status'])),
      createdAt:
          DateTime.tryParse(_asStringOrNull(json['createdAt']) ?? '') ??
          DateTime.now(),
      startedAt: DateTime.tryParse(_asStringOrNull(json['startedAt']) ?? ''),
      finishedAt: DateTime.tryParse(_asStringOrNull(json['finishedAt']) ?? ''),
      outputJsonPath: (_asStringOrNull(json['outputJsonPath']) ?? ''),
      resultAvailable: _asBool(json['resultAvailable']),
      request: AnalysisJobRequestSnapshot.fromJson(_asMap(json['request'])),
      progress: AnalysisJobProgress.fromJson(_asMap(json['progress'])),
      lastProgressAt: DateTime.tryParse(
        _asStringOrNull(json['lastProgressAt']) ?? '',
      ),
      pid: json['pid'] == null ? null : _asInt(json['pid']),
      cliSummary: json['cliSummary'] is Map ? _asMap(json['cliSummary']) : null,
      error: json['error'] is Map
          ? AnalysisJobErrorSummary.fromJson(_asMap(json['error']))
          : null,
      stdoutTail: (logs['stdoutTail'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      stderrTail: (logs['stderrTail'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
    );
  }
}

class AnalysisJobRequestSnapshot {
  const AnalysisJobRequestSnapshot({
    required this.sourceType,
    required this.requestedVideoPath,
    required this.resolvedVideoPath,
    required this.team1Name,
    required this.team1ShirtColor,
    required this.team2Name,
    required this.team2ShirtColor,
    required this.enableOffside,
    required this.analysisPreset,
    this.trackerBackend,
    this.yoloWeights,
    this.frameStride,
    this.maxFrames,
    this.goalDirections = const {},
  });

  final String sourceType;
  final String requestedVideoPath;
  final String resolvedVideoPath;
  final String team1Name;
  final String team1ShirtColor;
  final String team2Name;
  final String team2ShirtColor;
  final bool enableOffside;
  final String analysisPreset;
  final String? trackerBackend;
  final String? yoloWeights;
  final int? frameStride;
  final int? maxFrames;
  final Map<String, String> goalDirections;

  factory AnalysisJobRequestSnapshot.fromJson(Map<String, dynamic> json) {
    final rawGoals = _asMap(json['goalDirections']);
    return AnalysisJobRequestSnapshot(
      sourceType: _asStringOrNull(json['sourceType']) ?? 'videoPath',
      requestedVideoPath: _asStringOrNull(json['requestedVideoPath']) ?? '',
      resolvedVideoPath: _asStringOrNull(json['resolvedVideoPath']) ?? '',
      team1Name: _asStringOrNull(json['team1Name']) ?? 'Team 1',
      team1ShirtColor: _asStringOrNull(json['team1ShirtColor']) ?? 'blue',
      team2Name: _asStringOrNull(json['team2Name']) ?? 'Team 2',
      team2ShirtColor: _asStringOrNull(json['team2ShirtColor']) ?? 'red',
      enableOffside: _asBool(json['enableOffside']),
      analysisPreset: _asStringOrNull(json['analysisPreset']) ?? 'best',
      trackerBackend: _asStringOrNull(json['trackerBackend']),
      yoloWeights: _asStringOrNull(json['yoloWeights']),
      frameStride: json['frameStride'] == null
          ? null
          : _asInt(json['frameStride']),
      maxFrames: json['maxFrames'] == null ? null : _asInt(json['maxFrames']),
      goalDirections: rawGoals.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }
}

class AnalysisJobErrorSummary {
  const AnalysisJobErrorSummary({required this.message, this.exitCode});

  final String message;
  final int? exitCode;

  factory AnalysisJobErrorSummary.fromJson(Map<String, dynamic> json) {
    return AnalysisJobErrorSummary(
      message: _asStringOrNull(json['message']) ?? 'Unknown error',
      exitCode: json['exitCode'] == null ? null : _asInt(json['exitCode']),
    );
  }
}

class AnalysisEvent {
  const AnalysisEvent({
    required this.eventType,
    required this.frameIndex,
    required this.timestampS,
    this.teamName,
    required this.confidence,
    this.actorTrackId,
    this.receiverTrackId,
    this.teamsInvolved = const [],
    this.details = const {},
  });

  final String eventType;
  final int frameIndex;
  final double timestampS;
  final String? teamName;
  final double confidence;
  final int? actorTrackId;
  final int? receiverTrackId;
  final List<String> teamsInvolved;
  final Map<String, dynamic> details;

  factory AnalysisEvent.fromJson(Map<String, dynamic> json) {
    return AnalysisEvent(
      eventType: _asStringOrNull(json['event_type']) ?? 'unknown',
      frameIndex: _asInt(json['frame_index']),
      timestampS: _asDouble(json['timestamp_s']),
      teamName: _asStringOrNull(json['team_name']),
      confidence: _asDouble(json['confidence']),
      actorTrackId: json['actor_track_id'] == null
          ? null
          : _asInt(json['actor_track_id']),
      receiverTrackId: json['receiver_track_id'] == null
          ? null
          : _asInt(json['receiver_track_id']),
      teamsInvolved: (json['teams_involved'] as List? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(growable: false),
      details: _asMap(json['details']),
    );
  }

  String get timelineLabel {
    switch (eventType) {
      case 'pass':
        return _asBool(details['completed']) ? 'PASS COMPLETED' : 'PASS';
      case 'shot':
        return 'SHOT';
      case 'contact_event':
        return 'CONTACT EVENT';
      case 'offside_likely':
        return 'OFFSIDE LIKELY';
      default:
        return eventType.toUpperCase();
    }
  }

  String get timeLabel {
    final total = timestampS.round();
    final min = total ~/ 60;
    final sec = total % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}

class TeamAnalysisStats {
  const TeamAnalysisStats({
    required this.teamName,
    required this.passesAttempted,
    required this.passesCompleted,
    required this.shots,
    required this.contactEvent,
    required this.offsideLikely,
    required this.possessionSeconds,
    required this.possessionPct,
    required this.passAccuracyPct,
  });

  final String teamName;
  final int passesAttempted;
  final int passesCompleted;
  final int shots;
  final int contactEvent;
  final int offsideLikely;
  final double possessionSeconds;
  final double possessionPct;
  final double passAccuracyPct;

  factory TeamAnalysisStats.fromJson(
    String teamName,
    Map<String, dynamic> json,
  ) {
    return TeamAnalysisStats(
      teamName: teamName,
      passesAttempted: _asInt(json['passes_attempted']),
      passesCompleted: _asInt(json['passes_completed']),
      shots: _asInt(json['shots']),
      contactEvent: _asInt(json['contact_event']),
      offsideLikely: _asInt(json['offside_likely']),
      possessionSeconds: _asDouble(json['possession_seconds']),
      possessionPct: _asDouble(json['possession_pct']),
      passAccuracyPct: _asDouble(json['pass_accuracy_pct']),
    );
  }
}

class MatchAnalysisResult {
  const MatchAnalysisResult({
    required this.metadata,
    required this.events,
    required this.teamStats,
  });

  final Map<String, dynamic> metadata;
  final List<AnalysisEvent> events;
  final Map<String, TeamAnalysisStats> teamStats;

  factory MatchAnalysisResult.fromJson(Map<String, dynamic> json) {
    final statsJson = _asMap(json['team_stats']);
    final parsedStats = <String, TeamAnalysisStats>{};
    for (final entry in statsJson.entries) {
      parsedStats[entry.key] = TeamAnalysisStats.fromJson(
        entry.key,
        _asMap(entry.value),
      );
    }
    return MatchAnalysisResult(
      metadata: _asMap(json['metadata']),
      events: _asMapList(json['events']).map(AnalysisEvent.fromJson).toList(),
      teamStats: parsedStats,
    );
  }

  List<String> get teamNames => teamStats.keys.toList(growable: false);

  List<String> get notes => (metadata['notes'] as List? ?? const [])
      .map((e) => e.toString())
      .toList();

  Map<String, dynamic> get flutterOverview =>
      _asMap(metadata['flutter_overview']);

  Map<String, dynamic> get processingSummary =>
      _asMap(metadata['processing_summary']);

  String get team1Name => teamNames.isNotEmpty ? teamNames.first : 'Team 1';

  String get team2Name => teamNames.length > 1 ? teamNames[1] : 'Team 2';

  TeamAnalysisStats? get team1Stats => teamStats[team1Name];

  TeamAnalysisStats? get team2Stats => teamStats[team2Name];
}

class AnalysisJobResultEnvelope {
  const AnalysisJobResultEnvelope({required this.job, required this.result});

  final AnalysisJobSummary job;
  final MatchAnalysisResult result;

  factory AnalysisJobResultEnvelope.fromJson(Map<String, dynamic> json) {
    return AnalysisJobResultEnvelope(
      job: AnalysisJobSummary.fromJson(_asMap(json['job'])),
      result: MatchAnalysisResult.fromJson(_asMap(json['result'])),
    );
  }
}

String prettyJson(Object? value) =>
    const JsonEncoder.withIndent('  ').convert(value);
