import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/match_analysis_api.dart';
import '../models/match_analysis_models.dart';
import '../theme/analysis_theme.dart';

class MatchAnalysisMobileShell extends StatefulWidget {
  const MatchAnalysisMobileShell({
    super.key,
    this.onLogout,
    this.onOpenMessages,
    this.api,
    this.authToken,
    this.connectedClubName,
    this.embedded = false,
    this.onFabVisibilityChanged,
  });

  final VoidCallback? onLogout;
  final VoidCallback? onOpenMessages;
  final MatchAnalysisApi? api;
  final String? authToken;
  final String? connectedClubName;
  final bool embedded;
  final ValueChanged<bool>? onFabVisibilityChanged;

  @override
  State<MatchAnalysisMobileShell> createState() =>
      _MatchAnalysisMobileShellState();
}

enum _AnalysisStage { setup, processing, overview }

class _MatchAnalysisMobileShellState extends State<MatchAnalysisMobileShell> {
  late final MatchAnalysisApi _api = widget.api ?? MatchAnalysisApi();
  final _imagePicker = ImagePicker();

  final _team1NameCtrl = TextEditingController(text: 'London FC');
  final _team2NameCtrl = TextEditingController(text: 'Opponent');
  final _videoPathCtrl = TextEditingController();

  List<String> _colorPresets = const [
    'blue',
    'red',
    'white',
    'black',
    'green',
    'yellow',
  ];
  String _team1Color = 'blue';
  String _team2Color = 'red';

  bool _enableOffside = true;
  bool _tacticalHeatmaps = true;
  bool _individualTracking = false;
  bool _shotPowerAnalysis = true;
  AnalysisPreset _analysisPreset = AnalysisPreset.best;

  bool _isLoadingPresets = false;
  bool _isSubmitting = false;
  bool _isUploadingVideo = false;
  bool _pollInFlight = false;
  bool _isLoadingHistory = false;
  bool _historyShowAll = false;

  _AnalysisStage _stage = _AnalysisStage.setup;
  int _bottomIndex = 0;

  AnalysisJobSummary? _job;
  MatchAnalysisResult? _result;
  List<AnalysisJobSummary> _historyJobs = const [];
  final Map<String, MatchAnalysisResult> _historyResultCache = {};
  final Set<String> _historyDeletingJobIds = <String>{};
  XFile? _selectedVideoFile;
  UploadedBackendFileRef? _uploadedVideo;
  String? _uploadedVideoSourcePath;
  String? _errorText;
  String? _historyErrorText;
  Timer? _pollTimer;
  bool? _lastFabVisible;

  bool get _showHeaderActions => !widget.embedded;

  @override
  void initState() {
    super.initState();
    final clubName = widget.connectedClubName?.trim();
    if (clubName != null && clubName.isNotEmpty) {
      _team1NameCtrl.text = clubName;
    }
    _loadColorPresets();
    _loadHistory();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _team1NameCtrl.dispose();
    _team2NameCtrl.dispose();
    _videoPathCtrl.dispose();
    if (widget.api == null) {
      _api.dispose();
    }
    super.dispose();
  }

  Future<void> _loadColorPresets() async {
    setState(() => _isLoadingPresets = true);
    try {
      final presets = await _api.getColorPresets(token: widget.authToken);
      if (!mounted) {
        return;
      }
      setState(() {
        _colorPresets = presets.isEmpty ? _colorPresets : presets;
        if (!_colorPresets.contains(_team1Color)) {
          _team1Color = _colorPresets.first;
        }
        if (!_colorPresets.contains(_team2Color)) {
          _team2Color = _colorPresets.length > 1
              ? _colorPresets[1]
              : _colorPresets.first;
        }
      });
    } catch (_) {
      // Keep local presets fallback silently; UI still usable.
    } finally {
      if (mounted) {
        setState(() => _isLoadingPresets = false);
      }
    }
  }

  Future<void> _loadHistory() async {
    if (mounted) {
      setState(() {
        _isLoadingHistory = true;
        _historyErrorText = null;
      });
    } else {
      _isLoadingHistory = true;
      _historyErrorText = null;
    }

    try {
      final jobs = await _api.listJobs(token: widget.authToken);
      if (mounted) {
        setState(() {
          _historyJobs = jobs;
          _historyErrorText = null;
        });
      } else {
        _historyJobs = jobs;
        _historyErrorText = null;
      }
      await _prefetchHistoryResults(jobs.take(6).toList(growable: false));
    } catch (error) {
      if (mounted) {
        setState(() => _historyErrorText = error.toString());
      } else {
        _historyErrorText = error.toString();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      } else {
        _isLoadingHistory = false;
      }
    }
  }

  Future<void> _prefetchHistoryResults(List<AnalysisJobSummary> jobs) async {
    for (final job in jobs) {
      if (!job.resultAvailable || job.status != AnalysisJobStatus.completed) {
        continue;
      }
      if (_historyResultCache.containsKey(job.jobId)) {
        continue;
      }
      try {
        final envelope = await _api.getJobResult(
          job.jobId,
          token: widget.authToken,
        );
        _historyResultCache[job.jobId] = envelope.result;
        if (mounted) {
          setState(() {});
        }
      } catch (_) {
        // Keep card visible even if result JSON fetch fails.
      }
    }
  }

  Future<void> _openHistoryJob(AnalysisJobSummary job) async {
    if (job.status == AnalysisJobStatus.running ||
        job.status == AnalysisJobStatus.queued) {
      setState(() {
        _job = job;
        _result = null;
        _errorText = null;
        _stage = _AnalysisStage.processing;
        _bottomIndex = 1;
      });
      _beginPolling(job.jobId);
      return;
    }

    if (!job.resultAvailable || job.status != AnalysisJobStatus.completed) {
      _showSnack(
        job.error?.message ??
            'Detailed result is not available for this analysis.',
      );
      return;
    }

    try {
      setState(() {
        _errorText = null;
      });
      final cached = _historyResultCache[job.jobId];
      if (cached != null) {
        setState(() {
          _job = job;
          _result = cached;
          _stage = _AnalysisStage.overview;
          _bottomIndex = 1;
        });
        return;
      }

      final envelope = await _api.getJobResult(
        job.jobId,
        token: widget.authToken,
      );
      if (!mounted) {
        return;
      }
      _historyResultCache[job.jobId] = envelope.result;
      setState(() {
        _job = envelope.job;
        _result = envelope.result;
        _stage = _AnalysisStage.overview;
        _bottomIndex = 1;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorText = 'Failed to open analysis details: $error');
      _showSnack('Failed to open analysis details.');
    }
  }

  Future<void> _confirmDeleteHistoryJob(AnalysisJobSummary job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AnalysisPalette.panel2,
        title: Text(
          'Delete analysis',
          style: TextStyle(color: AnalysisPalette.text),
        ),
        content: Text(
          'Delete this analysis from history and remove its saved result?',
          style: TextStyle(color: AnalysisPalette.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: AnalysisPalette.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteHistoryJob(job);
    }
  }

  Future<void> _deleteHistoryJob(AnalysisJobSummary job) async {
    if (_historyDeletingJobIds.contains(job.jobId)) {
      return;
    }
    setState(() {
      _historyDeletingJobIds.add(job.jobId);
      _historyErrorText = null;
    });
    try {
      await _api.deleteJob(job.jobId, token: widget.authToken);
      if (!mounted) {
        return;
      }
      setState(() {
        _historyJobs = _historyJobs
            .where((e) => e.jobId != job.jobId)
            .toList(growable: false);
        _historyResultCache.remove(job.jobId);
        if (_job?.jobId == job.jobId) {
          _job = null;
          _result = null;
          _stage = _AnalysisStage.setup;
        }
      });
      _showSnack('Analysis deleted.');
    } catch (error) {
      if (mounted) {
        setState(() => _historyErrorText = error.toString());
      }
      _showSnack('Delete failed: $error');
    } finally {
      if (mounted) {
        setState(() => _historyDeletingJobIds.remove(job.jobId));
      } else {
        _historyDeletingJobIds.remove(job.jobId);
      }
    }
  }

  void _openAnalysisSetup() {
    _pollTimer?.cancel();
    setState(() {
      _stage = _AnalysisStage.setup;
      _bottomIndex = 1;
      _errorText = null;
    });
  }

  void _openMessages() {
    final callback = widget.onOpenMessages;
    if (callback != null) {
      callback();
      return;
    }
    _showSnack('Messaging can be connected next.');
  }

  Future<void> _pickVideo() async {
    try {
      final file = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (file == null || !mounted) {
        return;
      }
      setState(() {
        _selectedVideoFile = file;
        _uploadedVideo = null;
        _uploadedVideoSourcePath = null;
        _errorText = null;
        _videoPathCtrl.text = file.path;
      });
    } catch (error) {
      _showSnack('Video picker unavailable: $error');
    }
  }

  Future<void> _startAnalysis() async {
    final team1 = _team1NameCtrl.text.trim();
    final team2 = _team2NameCtrl.text.trim();
    final videoPath = _videoPathCtrl.text.trim();

    if (videoPath.isEmpty) {
      _showSnack('Select or paste a video path first.');
      return;
    }
    if (team1.isEmpty || team2.isEmpty) {
      _showSnack('Enter both team names.');
      return;
    }
    if (team1.toLowerCase() == team2.toLowerCase()) {
      _showSnack('Team names must be different.');
      return;
    }
    if (_team1Color == _team2Color) {
      _showSnack('Choose different shirt color presets.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
      _result = null;
      _job = null;
    });

    try {
      final requiresBackendUpload =
          _looksLikeDeviceLocalVideoPath(videoPath) &&
          !videoPath.startsWith('/uploads/');
      final token = widget.authToken?.trim();
      if (requiresBackendUpload && (token == null || token.isEmpty)) {
        throw Exception(
          'Upload to backend is required for this device video path. Please log out and log in again, then retry.',
        );
      }

      final manualBackendUploadUrl = videoPath.startsWith('/uploads/')
          ? videoPath
          : null;
      final uploadedVideo = manualBackendUploadUrl == null
          ? await _ensureUploadedVideo(videoPath)
          : null;
      final request = AnalysisCreateJobRequest(
        videoPath: uploadedVideo == null && manualBackendUploadUrl == null
            ? videoPath
            : null,
        videoUrl: uploadedVideo?.url ?? manualBackendUploadUrl,
        team1Name: team1,
        team1ShirtColor: _team1Color,
        team2Name: team2,
        team2ShirtColor: _team2Color,
        enableOffside: _enableOffside,
        analysisPreset: _analysisPreset,
        goalDirectionOverrides: const [],
      );

      final job = await _api.createJob(request, token: widget.authToken);
      if (!mounted) {
        return;
      }
      setState(() {
        _job = job;
        _historyJobs = [
          job,
          ..._historyJobs.where((existing) => existing.jobId != job.jobId),
        ];
        _stage = _AnalysisStage.processing;
        _bottomIndex = 1;
      });
      _beginPolling(job.jobId);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorText = error.toString());
      _showSnack('Failed to start analysis: $error');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  bool _looksLikeDeviceLocalVideoPath(String path) {
    final lower = path.toLowerCase();
    if (lower.startsWith('/data/user/')) return true;
    if (lower.startsWith('/storage/emulated/')) return true;
    if (lower.startsWith('/sdcard/')) return true;
    if (lower.startsWith('/var/mobile/')) return true;
    if (lower.startsWith('content://')) return true;
    if (lower.startsWith('file:///data/user/')) return true;
    if (lower.startsWith('file:///storage/')) return true;
    if (lower.startsWith('file:///var/mobile/')) return true;

    // Desktop local paths are valid for direct backend access in local dev.
    if (kIsWeb) return false;
    if (lower.startsWith('/users/')) return false;
    if (lower.startsWith('/home/')) return false;
    if (lower.startsWith('/tmp/')) return false;
    return false;
  }

  Future<UploadedBackendFileRef?> _ensureUploadedVideo(String videoPath) async {
    if (_uploadedVideo != null && _uploadedVideoSourcePath == videoPath) {
      return _uploadedVideo;
    }

    final token = widget.authToken;
    if (token == null || token.trim().isEmpty) {
      // Desktop/dev mode can use absolute local paths directly.
      return null;
    }

    if (mounted) {
      setState(() {
        _isUploadingVideo = true;
        _errorText = null;
      });
    }

    try {
      final uploaded = await _api.uploadFile(
        filePath: videoPath,
        filename: _displayVideoName,
        token: token,
      );
      if (mounted) {
        setState(() {
          _uploadedVideo = uploaded;
          _uploadedVideoSourcePath = videoPath;
        });
      } else {
        _uploadedVideo = uploaded;
        _uploadedVideoSourcePath = videoPath;
      }
      return uploaded;
    } catch (error) {
      throw Exception('Video upload failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isUploadingVideo = false);
      } else {
        _isUploadingVideo = false;
      }
    }
  }

  void _beginPolling(String jobId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshJob(jobId);
    });
    _refreshJob(jobId);
  }

  Future<void> _refreshJob(String jobId) async {
    if (_pollInFlight) {
      return;
    }
    _pollInFlight = true;
    try {
      final job = await _api.getJob(jobId, token: widget.authToken);
      if (!mounted) {
        return;
      }
      setState(() => _job = job);

      if (job.status == AnalysisJobStatus.completed && job.resultAvailable) {
        _pollTimer?.cancel();
        final envelope = await _api.getJobResult(
          job.jobId,
          token: widget.authToken,
        );
        if (!mounted) {
          return;
        }
        _historyResultCache[job.jobId] = envelope.result;
        setState(() {
          _job = envelope.job;
          _result = envelope.result;
          _stage = _AnalysisStage.overview;
          _bottomIndex = 1;
        });
      } else if (job.status == AnalysisJobStatus.failed ||
          job.status == AnalysisJobStatus.canceled) {
        _pollTimer?.cancel();
        if (!mounted) {
          return;
        }
        setState(() {
          _errorText = _jobFailureText(job);
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorText = error.toString());
      }
    } finally {
      _pollInFlight = false;
    }
  }

  Future<void> _cancelAnalysis() async {
    final job = _job;
    if (job == null) {
      setState(() => _stage = _AnalysisStage.setup);
      return;
    }
    _pollTimer?.cancel();
    try {
      final updated = await _api.cancelJob(job.jobId, token: widget.authToken);
      if (!mounted) {
        return;
      }
      setState(() {
        _job = updated;
        _errorText = updated.error?.message ?? 'Analysis canceled';
        _stage = _AnalysisStage.setup;
        _bottomIndex = 0;
      });
      _showSnack('Analysis canceled.');
    } catch (error) {
      _showSnack('Cancel failed: $error');
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AnalysisPalette.panel2,
        content: Text(message, style: TextStyle(color: AnalysisPalette.text)),
      ),
    );
  }

  String _jobFailureText(AnalysisJobSummary job) {
    final base = job.error?.message ?? 'Analysis stopped';
    final stderr = job.stderrTail
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (stderr.isEmpty) {
      return base;
    }

    final lastLines = stderr.length <= 3
        ? stderr
        : stderr.sublist(stderr.length - 3);
    final details = lastLines.join('\n');
    if (base.contains(details)) {
      return base;
    }
    return '$base\n$details';
  }

  void _resetToSetup() {
    _pollTimer?.cancel();
    setState(() {
      _stage = _AnalysisStage.setup;
      _bottomIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    _notifyFabVisibility();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: analysisShellDecoration(),
        child: SafeArea(
          top: !widget.embedded,
          child: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _stage == _AnalysisStage.processing
                      ? _buildProcessingScreen()
                      : switch (_bottomIndex) {
                          0 => _buildHistoryDashboardScreen(),
                          1 =>
                            _stage == _AnalysisStage.overview
                                ? _buildOverviewScreen()
                                : _buildSetupScreen(),
                          2 => _buildTabPlaceholder(
                            key: 'analysis-tab-teams',
                            title: 'Teams',
                            subtitle:
                                'Team roster insights and saved lineups can be added here next.',
                            icon: Icons.groups_rounded,
                          ),
                          _ => _buildTabPlaceholder(
                            key: 'analysis-tab-settings',
                            title: 'Settings',
                            subtitle:
                                'Analysis preferences and export defaults can be configured here next.',
                            icon: Icons.settings_rounded,
                          ),
                        },
                ),
              ),
              if (_stage != _AnalysisStage.processing)
                _AnalysisBottomBar(
                  index: _bottomIndex,
                  onChanged: (index) {
                    if (index == 0) {
                      _pollTimer?.cancel();
                      setState(() {
                        _bottomIndex = 0;
                        _errorText = null;
                      });
                      _loadHistory();
                      return;
                    }
                    if (index == 1) {
                      setState(() => _bottomIndex = 1);
                      return;
                    }
                    setState(() => _bottomIndex = index);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryDashboardScreen() {
    final visibleJobs = _historyShowAll
        ? _historyJobs
        : _historyJobs.take(3).toList(growable: false);
    final totalAnalyses = _historyJobs.length;
    var wins = 0;
    var winDenominator = 0;
    for (final job in _historyJobs) {
      final result = _historyResultCache[job.jobId];
      if (result == null) {
        continue;
      }
      final a = result.team1Stats;
      final b = result.team2Stats;
      if (a == null || b == null) {
        continue;
      }
      winDenominator++;
      final goalsA = (a.shots / 4).floor();
      final goalsB = (b.shots / 4).floor();
      if (goalsA > goalsB) {
        wins++;
      }
    }
    final winRatioPct = winDenominator == 0
        ? null
        : ((wins / winDenominator) * 100).round();

    return SingleChildScrollView(
      key: const ValueKey('analysis-history'),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: widget.embedded ? 0 : 50),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AnalysisPalette.neonBlue, width: 2),
                  color: AnalysisPalette.panel2,
                ),
                child: Icon(
                  Icons.psychology_alt_rounded,
                  color: AnalysisPalette.neonBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Match Analysis',
                      style: TextStyle(
                        color: AnalysisPalette.neonBlue,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hello, ${widget.connectedClubName?.trim().isNotEmpty == true ? 'Analyst' : 'Analyst'}',
                      style: TextStyle(
                        color: AnalysisPalette.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showHeaderActions) ...[
                const SizedBox(width: 6),
                _CircleIconButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: _openMessages,
                ),
                const SizedBox(width: 6),
                _CircleIconButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: () =>
                      _showSnack('Notifications panel can be connected next.'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent Analyses',
                  style: TextStyle(
                    color: AnalysisPalette.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _historyJobs.isEmpty
                    ? null
                    : () => setState(() => _historyShowAll = !_historyShowAll),
                icon: Icon(
                  _historyShowAll
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.chevron_right_rounded,
                  size: 18,
                ),
                label: Text(_historyShowAll ? 'Show Less' : 'View All'),
                style: TextButton.styleFrom(
                  foregroundColor: AnalysisPalette.neonBlue,
                ),
              ),
            ],
          ),
          if (_historyErrorText != null) ...[
            _ErrorBanner(
              text: _historyErrorText!,
              icon: Icons.warning_amber_rounded,
              accent: AnalysisPalette.danger,
            ),
            const SizedBox(height: 12),
          ],
          if (_isLoadingHistory && _historyJobs.isEmpty)
            Container(
              decoration: glowPanelDecoration(radius: 18),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AnalysisPalette.neonBlue,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Loading analysis history...',
                    style: TextStyle(color: AnalysisPalette.text),
                  ),
                ],
              ),
            )
          else if (_historyJobs.isEmpty)
            Container(
              decoration: glowPanelDecoration(radius: 22),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No analyses yet',
                    style: TextStyle(
                      color: AnalysisPalette.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start your first AI video analysis to populate this dashboard.',
                    style: TextStyle(color: AnalysisPalette.muted, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _openAnalysisSetup,
                    icon: Icon(Icons.add_rounded),
                    label: Text('New Analysis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AnalysisPalette.electric,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ...visibleJobs.map(
              (job) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HistoryAnalysisCard(
                  job: job,
                  result: _historyResultCache[job.jobId],
                  deleting: _historyDeletingJobIds.contains(job.jobId),
                  onTap: () => _openHistoryJob(job),
                  onDelete: () => _confirmDeleteHistoryJob(job),
                ),
              ),
            ),
            if (_isLoadingHistory) ...[
              const SizedBox(height: 4),
              LinearProgressIndicator(
                minHeight: 2,
                color: AnalysisPalette.neonBlue,
                backgroundColor: AnalysisPalette.softTrack,
              ),
            ],
          ],
          const SizedBox(height: 22),
          Text('QUICK STATS', style: neonSectionStyle()),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HistoryQuickStatCard(
                  label: 'Total Analyses',
                  value: '$totalAnalyses',
                  valueColor: AnalysisPalette.text,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HistoryQuickStatCard(
                  label: 'Win Ratio',
                  value: winRatioPct == null ? '--' : '$winRatioPct%',
                  valueColor: winRatioPct == null
                      ? AnalysisPalette.text
                      : AnalysisPalette.mint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: FloatingActionButton(
              heroTag: 'analysis-history-new',
              onPressed: _openAnalysisSetup,
              backgroundColor: AnalysisPalette.electric,
              foregroundColor: Colors.white,
              child: Icon(Icons.add_rounded, size: 34),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPlaceholder({
    required String key,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      key: ValueKey(key),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: glowPanelDecoration(radius: 22),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AnalysisPalette.neonBlue, size: 34),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: AnalysisPalette.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: AnalysisPalette.muted, height: 1.4),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: title == 'Teams' ? null : _openAnalysisSetup,
                icon: Icon(Icons.auto_awesome_rounded),
                label: Text('Open Analysis'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupScreen() {
    final canStart = !_isSubmitting && !_isUploadingVideo;
    return SingleChildScrollView(
      key: const ValueKey('analysis-setup'),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(
            title: 'Match Setup',
            onBack: () => setState(() => _bottomIndex = 0),
            useLeadingSpacer: _showHeaderActions,
            trailing: _showHeaderActions
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CircleIconButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        onTap: _openMessages,
                      ),
                      const SizedBox(width: 6),
                      _CircleIconButton(
                        icon: Icons.question_mark_rounded,
                        onTap: () => _showHelpSheet(context),
                      ),
                    ],
                  )
                : _CircleIconButton(
                    icon: Icons.question_mark_rounded,
                    onTap: () => _showHelpSheet(context),
                  ),
          ),
          const SizedBox(height: 18),
          Text('FOOTAGE ANALYSIS', style: neonSectionStyle()),
          const SizedBox(height: 14),
          Container(
            decoration: glowPanelDecoration(radius: 28, withGlow: true),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 190,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AnalysisPalette.panel2, AnalysisPalette.panel],
                    ),
                    border: Border.all(color: AnalysisPalette.elevatedStroke),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _PitchPreviewPainter()),
                      ),
                      Center(
                        child: InkWell(
                          onTap: _pickVideo,
                          borderRadius: BorderRadius.circular(40),
                          child: Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AnalysisPalette.electric,
                              boxShadow: [
                                BoxShadow(
                                  color: AnalysisPalette.elevatedGlow,
                                  blurRadius: 24,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _displayVideoName,
                        style: TextStyle(
                          color: AnalysisPalette.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _pickVideo,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AnalysisPalette.neonBlue,
                        side: BorderSide(color: AnalysisPalette.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text('REPLACE'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _uploadedVideo != null
                      ? 'Uploaded to backend: ${_uploadedVideo!.url}'
                      : _selectedVideoFile != null
                      ? 'Selected video will be uploaded to backend /uploads before analysis starts'
                      : 'Local video ready for offline analysis on macOS CPU',
                  style: TextStyle(
                    color: _uploadedVideo != null
                        ? AnalysisPalette.mint
                        : AnalysisPalette.muted,
                    fontSize: 12.5,
                    fontWeight: _uploadedVideo != null
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _videoPathCtrl,
                  style: TextStyle(color: AnalysisPalette.text),
                  decoration: _darkInputDecoration(
                    label: 'Video path',
                    hint: '/absolute/path/match_footage_001.mp4',
                    icon: Icons.video_file_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('TEAM CONFIGURATION', style: neonSectionStyle()),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth <= 520;

              final leftCard = _TeamCard(
                title: 'YOUR CLUB',
                icon: Icons.shield_rounded,
                compact: compact,
                nameField: TextField(
                  controller: _team1NameCtrl,
                  style: TextStyle(color: AnalysisPalette.text),
                  decoration: _darkInputDecoration(
                    label: compact ? 'Name' : 'Team name',
                    icon: compact ? null : Icons.groups_rounded,
                    compact: true,
                  ),
                ),
                colorField: _ColorPresetDropdown(
                  value: _team1Color,
                  values: _colorPresets,
                  onChanged: (value) => setState(() => _team1Color = value),
                  loading: _isLoadingPresets,
                  compact: compact,
                ),
              );

              final rightCard = _TeamCard(
                title: 'OPPONENT',
                icon: Icons.add_circle_outline_rounded,
                compact: compact,
                nameField: TextField(
                  controller: _team2NameCtrl,
                  style: TextStyle(color: AnalysisPalette.text),
                  decoration: _darkInputDecoration(
                    label: compact ? 'Name' : 'Team name',
                    icon: compact ? null : Icons.groups_rounded,
                    compact: true,
                  ),
                ),
                colorField: _ColorPresetDropdown(
                  value: _team2Color,
                  values: _colorPresets,
                  onChanged: (value) => setState(() => _team2Color = value),
                  loading: _isLoadingPresets,
                  compact: compact,
                ),
              );

              final vsBadge = Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AnalysisPalette.neonBlue,
                    width: 1.2,
                  ),
                  color: AnalysisPalette.overlayCard,
                  boxShadow: [
                    BoxShadow(
                      color: AnalysisPalette.elevatedGlow,
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'VS',
                    style: TextStyle(
                      color: AnalysisPalette.neonBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );

              if (compact) {
                return Column(
                  children: [
                    leftCard,
                    const SizedBox(height: 10),
                    Center(child: vsBadge),
                    const SizedBox(height: 10),
                    rightCard,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: leftCard),
                  const SizedBox(width: 14),
                  vsBadge,
                  const SizedBox(width: 14),
                  Expanded(child: rightCard),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text('ANALYSIS SETTINGS', style: neonSectionStyle()),
          const SizedBox(height: 14),
          Container(
            decoration: glowPanelDecoration(radius: 22),
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.grid_on_rounded,
                  title: 'Tactical Heatmaps',
                  subtitle: 'UI overlay only (frontend setting)',
                  value: _tacticalHeatmaps,
                  accent: AnalysisPalette.neonBlue,
                  onChanged: (v) => setState(() => _tacticalHeatmaps = v),
                ),
                _dividerLine(),
                _SettingTile(
                  icon: Icons.person_search_rounded,
                  title: 'Individual Player Tracking',
                  subtitle: 'Uses stable track_id in result timeline',
                  value: _individualTracking,
                  accent: AnalysisPalette.cyan,
                  onChanged: (v) => setState(() => _individualTracking = v),
                ),
                _dividerLine(),
                _SettingTile(
                  icon: Icons.offline_bolt_rounded,
                  title: 'Offside Likely',
                  subtitle:
                      'Requires pitch calibration; auto-disabled on failure',
                  value: _enableOffside,
                  accent: AnalysisPalette.violet,
                  onChanged: (v) => setState(() => _enableOffside = v),
                ),
                _dividerLine(),
                _SettingTile(
                  icon: Icons.speed_rounded,
                  title: 'Shot Power Heuristics',
                  subtitle:
                      'Shot events from ball speed spike + goal direction',
                  value: _shotPowerAnalysis,
                  accent: AnalysisPalette.mint,
                  onChanged: (v) => setState(() => _shotPowerAnalysis = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: glowPanelDecoration(radius: 18),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Engine Quality',
                  style: TextStyle(
                    color: AnalysisPalette.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<AnalysisPreset>(
                  segments: const [
                    ButtonSegment<AnalysisPreset>(
                      value: AnalysisPreset.balanced,
                      label: Text('Balanced'),
                      icon: Icon(Icons.tune_rounded),
                    ),
                    ButtonSegment<AnalysisPreset>(
                      value: AnalysisPreset.best,
                      label: Text('Best'),
                      icon: Icon(Icons.auto_awesome_rounded),
                    ),
                  ],
                  selected: {_analysisPreset},
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AnalysisPalette.chipFill;
                      }
                      return AnalysisPalette.panel;
                    }),
                    foregroundColor: WidgetStateProperty.all(
                      AnalysisPalette.text,
                    ),
                    side: WidgetStateProperty.all(
                      BorderSide(color: AnalysisPalette.softLine),
                    ),
                  ),
                  onSelectionChanged: (value) {
                    if (value.isEmpty) {
                      return;
                    }
                    setState(() => _analysisPreset = value.first);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _analysisPreset == AnalysisPreset.best
                      ? 'Best mode enables ByteTrack + stronger calibration sampling (slower on CPU).'
                      : 'Balanced mode favors speed with the simple tracker backend.',
                  style: TextStyle(color: AnalysisPalette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 14),
            _ErrorBanner(text: _errorText!),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canStart ? _startAnalysis : null,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : _isUploadingVideo
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.auto_awesome_rounded),
              label: Text(
                _isUploadingVideo
                    ? 'Uploading Video...'
                    : _isSubmitting
                    ? 'Starting...'
                    : 'Start AI Analysis',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AnalysisPalette.electric,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingScreen() {
    final job = _job;
    final progress = job?.progress;
    final ratio = (progress?.progress ?? 0).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();
    final frames =
        progress?.framesProcessed ?? progress?.currentFrameIndex ?? 0;
    final players = progress?.playersDetected ?? 0;
    final ballDetected = progress?.ballDetected ?? false;
    final fps = progress?.fpsEffective ?? 0;
    final latencyMs = fps <= 0 ? null : (1000 / fps);

    return SingleChildScrollView(
      key: const ValueKey('analysis-processing'),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      child: Column(
        children: [
          _TopBar(
            title: 'AI Analysis',
            onBack: _cancelAnalysis,
            useLeadingSpacer: _showHeaderActions,
            trailing: _showHeaderActions
                ? _CircleIconButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: _openMessages,
                  )
                : const SizedBox(width: 1, height: 1),
          ),
          const SizedBox(height: 20),
          _RadialProgressCard(
            progress: ratio,
            centerIcon: Icons.query_stats_rounded,
            label: (progress?.phase ?? 'processing').toUpperCase(),
            percentText: '$percent%',
            footerLabel: job?.request.analysisPreset.toUpperCase() ?? 'BEST',
          ),
          const SizedBox(height: 22),
          Text(
            'Analyzing Match...',
            style: TextStyle(
              color: AnalysisPalette.text,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _processingSubtitle(progress?.phase),
            textAlign: TextAlign.center,
            style: TextStyle(color: AnalysisPalette.muted, fontSize: 14),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.14,
            children: [
              _MetricTile(
                icon: Icons.movie_creation_outlined,
                label: 'FRAMES',
                value: _formatInt(frames),
                caption: progress?.totalFrames != null
                    ? '/ ${_formatInt(progress!.totalFrames!)}'
                    : null,
                delta: fps > 0 ? '+${fps.toStringAsFixed(0)} fps' : null,
              ),
              _MetricTile(
                icon: Icons.groups_rounded,
                label: 'PLAYERS',
                value: players > 0 ? '$players tracked' : '--',
                caption: progress?.trackerBackendEffective ?? 'tracking',
                status: progress?.trackerStatus,
              ),
              _MetricTile(
                icon: Icons.sports_soccer_rounded,
                label: 'BALL DETECTION',
                value: ballDetected ? 'Detected' : 'Searching',
                caption: ballDetected ? 'lock active' : 'awaiting lock',
                delta: ballDetected ? '+ stable' : null,
              ),
              _MetricTile(
                icon: Icons.speed_rounded,
                label: 'LATENCY',
                value: latencyMs == null ? '--' : '${latencyMs.round()}ms',
                caption: job?.request.analysisPreset == 'best'
                    ? 'High Accuracy'
                    : 'Balanced',
                status: progress?.trackerBackendEffective,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _result != null
                  ? () => setState(() => _stage = _AnalysisStage.overview)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AnalysisPalette.electric,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              child: Text('Live View Dashboard'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _cancelAnalysis,
            child: Text(
              'Cancel Analysis',
              style: TextStyle(color: AnalysisPalette.muted, fontSize: 16),
            ),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            _ErrorBanner(text: _errorText!),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewScreen() {
    final result = _result;
    final job = _job;
    if (result == null) {
      return Center(
        key: const ValueKey('analysis-overview-empty'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AnalysisPalette.muted,
                size: 42,
              ),
              const SizedBox(height: 10),
              Text(
                'No analysis result loaded',
                style: TextStyle(
                  color: AnalysisPalette.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: _resetToSetup,
                child: Text('Go back to setup'),
              ),
            ],
          ),
        ),
      );
    }

    final teams = result.teamNames;
    final teamA = teams.isNotEmpty ? teams[0] : 'Team A';
    final teamB = teams.length > 1 ? teams[1] : 'Team B';
    final statsA = result.teamStats[teamA];
    final statsB = result.teamStats[teamB];
    final timeline = _buildTimeline(result.events);
    final topTracks = _buildTopTracks(result.events);
    final latestMinute = result.events.isEmpty
        ? 0
        : (result.events
                      .map((e) => e.timestampS)
                      .reduce((a, b) => a > b ? a : b) /
                  60)
              .floor();

    return SingleChildScrollView(
      key: const ValueKey('analysis-overview'),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: widget.embedded ? 0 : 50),
              _CircleIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: _resetToSetup,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'LIVE MATCH',
                      style: TextStyle(
                        color: AnalysisPalette.neonBlue,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$latestMinute' | ${_scorelineFromResult(result)}",
                      style: TextStyle(
                        color: AnalysisPalette.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (_showHeaderActions) ...[
                _CircleIconButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: _openMessages,
                ),
                const SizedBox(width: 6),
              ],
              _CircleIconButton(
                icon: Icons.share_outlined,
                onTap: () =>
                    _showSnack('Share action can export result JSON next.'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Match Overview',
                  style: TextStyle(
                    color: AnalysisPalette.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AnalysisPalette.chipFill,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AnalysisPalette.chipBorder),
                ),
                child: Text(
                  'Real-time AI',
                  style: TextStyle(
                    color: AnalysisPalette.neonBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: glowPanelDecoration(radius: 20),
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _VersusStatBar(
                  label: 'Possession',
                  leftTeam: teamA,
                  rightTeam: teamB,
                  leftValue: statsA?.possessionPct ?? 0,
                  rightValue: statsB?.possessionPct ?? 0,
                  valueSuffix: '%',
                ),
                const SizedBox(height: 14),
                _VersusStatBar(
                  label: 'Pass Accuracy',
                  leftTeam: teamA,
                  rightTeam: teamB,
                  leftValue: statsA?.passAccuracyPct ?? 0,
                  rightValue: statsB?.passAccuracyPct ?? 0,
                  valueSuffix: '%',
                ),
                const SizedBox(height: 14),
                _VersusStatBar(
                  label: 'Total Shots',
                  leftTeam: teamA,
                  rightTeam: teamB,
                  leftValue: (statsA?.shots ?? 0).toDouble(),
                  rightValue: (statsB?.shots ?? 0).toDouble(),
                  valueSuffix: '',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: glowPanelDecoration(radius: 20),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      color: AnalysisPalette.neonBlue,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'AI Match Insight',
                      style: TextStyle(
                        color: AnalysisPalette.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _buildInsight(result),
                  style: TextStyle(
                    color: AnalysisPalette.text,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: AnalysisPalette.softLine, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AnalysisPalette.chipFill,
                      ),
                      child: Center(
                        child: Text(
                          '${_confidenceScore(result)}%',
                          style: TextStyle(
                            color: AnalysisPalette.neonBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Confidence Score',
                      style: TextStyle(color: AnalysisPalette.muted),
                    ),
                    const Spacer(),
                    if (job != null)
                      Text(
                        job.request.analysisPreset.toUpperCase(),
                        style: TextStyle(color: AnalysisPalette.muted),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (result.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ErrorBanner(
              text: result.notes.join('\n'),
              icon: Icons.info_outline_rounded,
              accent: AnalysisPalette.cyan,
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'Match Timeline',
            style: TextStyle(
              color: AnalysisPalette.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...timeline.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TimelineCard(entry: entry),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Top Players',
            style: TextStyle(
              color: AnalysisPalette.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 214,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: topTracks.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _TopTrackCard(
                track: topTracks[index],
                accent: index.isEven
                    ? AnalysisPalette.neonBlue
                    : AnalysisPalette.violet,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _displayVideoName {
    final path = _videoPathCtrl.text.trim();
    if (path.isEmpty) {
      return 'match_footage_001.mp4';
    }
    final normalized = path.replaceAll('\\', '/');
    final idx = normalized.lastIndexOf('/');
    return idx >= 0 ? normalized.substring(idx + 1) : normalized;
  }

  String _processingSubtitle(String? phase) {
    switch (phase) {
      case 'init':
        return 'Preparing YOLO detector, tracking, and color models';
      case 'detect_track':
        return 'Real-time tactical frame decomposition';
      case 'done':
        return 'Result JSON ready';
      default:
        return 'Computing possession, events, and team statistics';
    }
  }

  String _scorelineFromResult(MatchAnalysisResult result) {
    final teams = result.teamNames;
    final a = teams.isNotEmpty ? teams[0] : 'A';
    final b = teams.length > 1 ? teams[1] : 'B';
    final shotsA = result.teamStats[a]?.shots ?? 0;
    final shotsB = result.teamStats[b]?.shots ?? 0;
    final goalsA = (shotsA / 4).floor();
    final goalsB = (shotsB / 4).floor();
    final shortA = _shortTeam(a);
    final shortB = _shortTeam(b);
    return '$shortA $goalsA - $goalsB $shortB';
  }

  String _shortTeam(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((e) => e.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isEmpty
        ? 'TM'
        : parts.first
              .substring(0, parts.first.length < 3 ? parts.first.length : 3)
              .toUpperCase();
  }

  int _confidenceScore(MatchAnalysisResult result) {
    if (result.events.isEmpty) {
      return 70;
    }
    final avg =
        result.events
            .map((e) => e.confidence)
            .fold<double>(0, (sum, c) => sum + c) /
        result.events.length;
    return (avg * 100).round().clamp(1, 99);
  }

  String _buildInsight(MatchAnalysisResult result) {
    final teams = result.teamNames;
    if (teams.length < 2) {
      return 'Analysis complete. Event and possession data are available for review.';
    }
    final a = result.teamStats[teams[0]];
    final b = result.teamStats[teams[1]];
    if (a == null || b == null) {
      return 'Analysis complete. Team statistics are partially available.';
    }

    final possessionLeader = a.possessionPct >= b.possessionPct ? a : b;
    final shotLeader = a.shots >= b.shots ? a : b;
    final passLeader = a.passAccuracyPct >= b.passAccuracyPct ? a : b;
    final contactCount = a.contactEvent + b.contactEvent;
    final offsideCount = a.offsideLikely + b.offsideLikely;

    final notes = <String>[
      '${possessionLeader.teamName} controls possession (${possessionLeader.possessionPct.toStringAsFixed(0)}%).',
      '${shotLeader.teamName} generates more attempts (${shotLeader.shots} shots) while ${passLeader.teamName} leads pass efficiency (${passLeader.passAccuracyPct.toStringAsFixed(0)}%).',
    ];
    if (contactCount > 0) {
      notes.add(
        'Physical duels increased with $contactCount contact events detected.',
      );
    }
    if (offsideCount > 0) {
      notes.add(
        '$offsideCount offside-likely situations were flagged for review.',
      );
    }
    return notes.join(' ');
  }

  List<_TimelineEntry> _buildTimeline(List<AnalysisEvent> events) {
    final sorted = [...events]
      ..sort((a, b) => b.timestampS.compareTo(a.timestampS));
    return sorted
        .take(8)
        .map((event) {
          final subtitle = switch (event.eventType) {
            'pass' =>
              _asBoolFromDetails(event.details, 'completed')
                  ? 'Completed pass'
                  : 'Pass attempt',
            'shot' => 'Ball speed spike toward goal zone',
            'contact_event' => 'Player contact + possession loss heuristic',
            'offside_likely' =>
              'Receiver ahead of second-last defender (likely)',
            _ => 'Detected event',
          };
          return _TimelineEntry(
            title: event.timelineLabel,
            subtitle: subtitle,
            teamName:
                event.teamName ??
                (event.teamsInvolved.isNotEmpty
                    ? event.teamsInvolved.first
                    : 'N/A'),
            timeLabel: event.timeLabel,
            confidence: event.confidence,
            eventType: event.eventType,
          );
        })
        .toList(growable: false);
  }

  bool _asBoolFromDetails(Map<String, dynamic> details, String key) {
    final value = details[key];
    if (value is bool) {
      return value;
    }
    return value?.toString().toLowerCase() == 'true';
  }

  List<_TopTrackSummary> _buildTopTracks(List<AnalysisEvent> events) {
    final scores = <int, _TopTrackAccumulator>{};
    for (final event in events) {
      final ids = <int?>[
        event.actorTrackId,
        event.receiverTrackId,
      ].whereType<int>().toSet().toList();
      for (final id in ids) {
        final acc = scores.putIfAbsent(
          id,
          () => _TopTrackAccumulator(trackId: id),
        );
        acc.events += 1;
        acc.totalConfidence += event.confidence;
        if (event.teamName != null) {
          acc.teamName = event.teamName;
        } else if (event.teamsInvolved.isNotEmpty) {
          acc.teamName ??= event.teamsInvolved.first;
        }
        if (event.eventType == 'pass') {
          acc.passes += 1;
        }
        if (event.eventType == 'shot') {
          acc.shots += 1;
        }
      }
    }
    final list = scores.values.toList()
      ..sort((a, b) => b.events.compareTo(a.events));
    if (list.isEmpty) {
      return const [
        _TopTrackSummary(
          trackId: 17,
          teamName: 'MCI',
          events: 6,
          passes: 4,
          shots: 1,
          rating: 8.9,
        ),
        _TopTrackSummary(
          trackId: 8,
          teamName: 'ARS',
          events: 5,
          passes: 3,
          shots: 1,
          rating: 8.4,
        ),
      ];
    }
    return list
        .take(6)
        .map((acc) {
          final rating =
              (7.0 +
                      (acc.events * 0.25) +
                      (acc.totalConfidence /
                          (acc.events == 0 ? 1 : acc.events)))
                  .clamp(6.5, 9.8);
          return _TopTrackSummary(
            trackId: acc.trackId,
            teamName: _shortTeam(acc.teamName ?? 'Team'),
            events: acc.events,
            passes: acc.passes,
            shots: acc.shots,
            rating: rating,
          );
        })
        .toList(growable: false);
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AnalysisPalette.panel,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.fromBorderSide(
              BorderSide(color: AnalysisPalette.softLine),
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analysis Setup Help',
                style: TextStyle(
                  color: AnalysisPalette.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Choose a local match video path and assign shirt color presets for each team. Best mode improves tracking accuracy (ByteTrack) but is slower on CPU.',
                style: TextStyle(color: AnalysisPalette.muted, height: 1.5),
              ),
              SizedBox(height: 8),
              Text(
                'Offside uses a pitch calibration heuristic and may auto-disable if field lines are not visible.',
                style: TextStyle(color: AnalysisPalette.muted, height: 1.5),
              ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _darkInputDecoration({
    required String label,
    String? hint,
    IconData? icon,
    bool compact = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: compact,
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: AnalysisPalette.muted),
      prefixIconConstraints: compact
          ? const BoxConstraints(minWidth: 34, minHeight: 34)
          : null,
      filled: true,
      fillColor: AnalysisPalette.panel2,
      labelStyle: TextStyle(color: AnalysisPalette.muted),
      hintStyle: TextStyle(
        color: AnalysisPalette.muted.withValues(alpha: 0.55),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AnalysisPalette.softLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AnalysisPalette.neonBlue, width: 1.2),
      ),
      contentPadding: compact
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _dividerLine() =>
      Divider(height: 1, color: AnalysisPalette.softLine, thickness: 1);

  void _notifyFabVisibility() {
    final visible = _stage != _AnalysisStage.processing;
    if (visible == _lastFabVisible) {
      return;
    }
    _lastFabVisible = visible;
    widget.onFabVisibilityChanged?.call(visible);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
    required this.trailing,
    this.useLeadingSpacer = true,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget trailing;
  final bool useLeadingSpacer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: useLeadingSpacer ? 50 : 0),
        _CircleIconButton(icon: Icons.chevron_left_rounded, onTap: onBack),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AnalysisPalette.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44),
          child: Center(child: trailing),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AnalysisPalette.panel2,
          shape: BoxShape.circle,
          border: Border.all(color: AnalysisPalette.softLine),
        ),
        child: Icon(icon, color: AnalysisPalette.text, size: 24),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.title,
    required this.icon,
    required this.nameField,
    required this.colorField,
    this.compact = false,
  });

  final String title;
  final IconData icon;
  final Widget nameField;
  final Widget colorField;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: glowPanelDecoration(radius: 20),
      padding: EdgeInsets.all(compact ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 40 : 46,
            height: compact ? 40 : 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AnalysisPalette.overlayCard,
              border: Border.all(color: AnalysisPalette.border),
            ),
            child: Icon(
              icon,
              color: AnalysisPalette.neonBlue,
              size: compact ? 20 : 24,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            title,
            style: TextStyle(
              color: AnalysisPalette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          nameField,
          SizedBox(height: compact ? 8 : 10),
          colorField,
        ],
      ),
    );
  }
}

class _ColorPresetDropdown extends StatelessWidget {
  const _ColorPresetDropdown({
    required this.value,
    required this.values,
    required this.onChanged,
    required this.loading,
    this.compact = false,
  });

  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  final bool loading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = values.isEmpty ? [value] : values;
    final selected = items.contains(value) ? value : items.first;
    return DropdownButtonFormField<String>(
      key: ValueKey(selected),
      initialValue: selected,
      isExpanded: true,
      dropdownColor: AnalysisPalette.panel2,
      iconEnabledColor: AnalysisPalette.muted,
      style: TextStyle(color: AnalysisPalette.text),
      decoration: InputDecoration(
        labelText: loading
            ? (compact ? 'Color...' : 'Shirt color (syncing...)')
            : (compact ? 'Color' : 'Shirt color'),
        isDense: compact,
        labelStyle: TextStyle(color: AnalysisPalette.muted),
        filled: true,
        fillColor: AnalysisPalette.panel2,
        contentPadding: compact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AnalysisPalette.softLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AnalysisPalette.neonBlue, width: 1.2),
        ),
      ),
      items: items
          .map(
            (preset) => DropdownMenuItem<String>(
              value: preset,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _presetColorChip(preset),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      preset.replaceAll('_', ' ').toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      selectedItemBuilder: (context) => items
          .map(
            (preset) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                preset.replaceAll('_', ' ').toUpperCase(),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(color: AnalysisPalette.text),
              ),
            ),
          )
          .toList(),
      onChanged: (next) {
        if (next != null) {
          onChanged(next);
        }
      },
    );
  }

  static Color _presetColorChip(String preset) {
    switch (preset) {
      case 'blue':
      case 'navy':
      case 'sky_blue':
      case 'cyan':
        return AnalysisPalette.neonBlue;
      case 'red':
      case 'orange':
      case 'pink':
        return AnalysisPalette.danger;
      case 'green':
        return AnalysisPalette.mint;
      case 'yellow':
        return AnalysisPalette.warning;
      case 'white':
      case 'gray':
        return AnalysisPalette.text.withValues(alpha: 0.95);
      case 'black':
        return AnalysisPalette.blackChip;
      case 'purple':
        return AnalysisPalette.violet;
      default:
        return AnalysisPalette.cyan;
    }
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AnalysisPalette.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: AnalysisPalette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: accent,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AnalysisPalette.softTrack,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.delta,
    this.status,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final String? delta;
  final String? status;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: glowPanelDecoration(radius: 20),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AnalysisPalette.neonBlue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AnalysisPalette.muted,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: AnalysisPalette.text,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: TextStyle(color: AnalysisPalette.muted, fontSize: 12),
            ),
          ],
          if (delta != null) ...[
            const SizedBox(height: 4),
            Text(
              delta!,
              style: TextStyle(
                color: AnalysisPalette.mint,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ] else if (status != null) ...[
            const SizedBox(height: 4),
            Text(
              status!,
              style: TextStyle(
                color: AnalysisPalette.neonBlue,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RadialProgressCard extends StatelessWidget {
  const _RadialProgressCard({
    required this.progress,
    required this.centerIcon,
    required this.label,
    required this.percentText,
    required this.footerLabel,
  });

  final double progress;
  final IconData centerIcon;
  final String label;
  final String percentText;
  final String footerLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      height: 290,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AnalysisPalette.elevatedStroke),
              boxShadow: [
                BoxShadow(
                  color: AnalysisPalette.elevatedGlow,
                  blurRadius: 28,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 260,
            height: 260,
            child: CustomPaint(painter: _RingPainter(progress: progress)),
          ),
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AnalysisPalette.overlayCard.withValues(alpha: 0.7),
              border: Border.all(color: AnalysisPalette.softLine),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(centerIcon, color: AnalysisPalette.neonBlue, size: 44),
                const SizedBox(height: 10),
                Text(
                  percentText,
                  style: TextStyle(
                    color: AnalysisPalette.neonBlue,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: AnalysisPalette.muted,
                    letterSpacing: 2.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 116,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AnalysisPalette.softTrack,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AnalysisPalette.electric,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  footerLabel,
                  style: TextStyle(
                    color: AnalysisPalette.neonBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VersusStatBar extends StatelessWidget {
  const _VersusStatBar({
    required this.label,
    required this.leftTeam,
    required this.rightTeam,
    required this.leftValue,
    required this.rightValue,
    required this.valueSuffix,
  });

  final String label;
  final String leftTeam;
  final String rightTeam;
  final double leftValue;
  final double rightValue;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    final total = (leftValue + rightValue);
    final leftRatio = total <= 0 ? 0.5 : (leftValue / total).clamp(0.0, 1.0);
    final leftFlex = ((leftRatio * 1000).round()).clamp(1, 999);
    final rightFlex = ((1000 - leftFlex)).clamp(1, 999);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AnalysisPalette.neonBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${_fmtValue(leftValue, valueSuffix)} vs ${_fmtValue(rightValue, valueSuffix)}',
              style: TextStyle(
                color: AnalysisPalette.violet,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                Expanded(
                  flex: leftFlex,
                  child: Container(color: AnalysisPalette.electric),
                ),
                Expanded(
                  flex: rightFlex,
                  child: Container(color: AnalysisPalette.violet),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmtValue(double value, String suffix) {
    final text = value % 1 == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$text$suffix';
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.entry});

  final _TimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    final accent = switch (entry.eventType) {
      'shot' => AnalysisPalette.violet,
      'contact_event' => AnalysisPalette.cyan,
      'offside_likely' => AnalysisPalette.danger,
      _ => AnalysisPalette.neonBlue,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(width: 2, height: 10, color: accent),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                ),
              ),
              Container(
                width: 2,
                height: 70,
                color: accent.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: glowPanelDecoration(radius: 18),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_eventIcon(entry.eventType), color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: TextStyle(
                          color: AnalysisPalette.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${entry.subtitle} • ${entry.timeLabel}',
                        style: TextStyle(
                          color: AnalysisPalette.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      entry.teamName,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(entry.confidence * 100).round()}%',
                      style: TextStyle(
                        color: AnalysisPalette.muted,
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
    );
  }

  static IconData _eventIcon(String type) {
    switch (type) {
      case 'shot':
        return Icons.north_east_rounded;
      case 'contact_event':
        return Icons.compare_arrows_rounded;
      case 'offside_likely':
        return Icons.report_gmailerrorred_rounded;
      default:
        return Icons.sports_soccer_rounded;
    }
  }
}

class _TopTrackCard extends StatelessWidget {
  const _TopTrackCard({required this.track, required this.accent});

  final _TopTrackSummary track;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      decoration: glowPanelDecoration(radius: 18),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 2),
              color: AnalysisPalette.overlayCard,
            ),
            child: Center(
              child: Text(
                '#${track.trackId}',
                style: TextStyle(
                  color: AnalysisPalette.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Track ${track.trackId}',
            style: TextStyle(
              color: AnalysisPalette.text,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            track.teamName,
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          const SizedBox(height: 6),
          Divider(color: AnalysisPalette.softLine, height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SmallStat(
                  label: 'Rating',
                  value: track.rating.toStringAsFixed(1),
                ),
              ),
              Expanded(
                child: _SmallStat(label: 'Passes', value: '${track.passes}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(color: AnalysisPalette.muted, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AnalysisPalette.text,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _HistoryAnalysisCard extends StatelessWidget {
  const _HistoryAnalysisCard({
    required this.job,
    required this.result,
    required this.deleting,
    required this.onTap,
    required this.onDelete,
  });

  final AnalysisJobSummary job;
  final MatchAnalysisResult? result;
  final bool deleting;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = '${job.request.team1Name} vs ${job.request.team2Name}';
    final subtitle = '${_statusLabel(job)} • ${_formatDate(job.createdAt)}';

    String scoreLabel = '--';
    String possessionLabel = '-- / --';
    if (result != null) {
      final a = result!.team1Stats;
      final b = result!.team2Stats;
      if (a != null && b != null) {
        scoreLabel = '${(a.shots / 4).floor()} - ${(b.shots / 4).floor()}';
        possessionLabel =
            '${a.possessionPct.toStringAsFixed(0)}% / ${b.possessionPct.toStringAsFixed(0)}%';
      }
    } else if (job.status == AnalysisJobStatus.running ||
        job.status == AnalysisJobStatus.queued) {
      scoreLabel = '${job.progress.progressPercent.toStringAsFixed(0)}%';
      possessionLabel =
          (job.progress.phase.isNotEmpty ? job.progress.phase : 'processing')
              .replaceAll('_', ' ');
    } else if (job.status == AnalysisJobStatus.failed) {
      scoreLabel = 'FAILED';
      possessionLabel = 'Tap to inspect logs';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: glowPanelDecoration(radius: 22, withGlow: false),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AnalysisPalette.overlayCard,
                  border: Border.all(color: AnalysisPalette.elevatedStroke),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: CustomPaint(painter: _PitchPreviewPainter()),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AnalysisPalette.text.withValues(alpha: 0.92),
                        ),
                        child: Icon(
                          job.status == AnalysisJobStatus.completed
                              ? Icons.play_arrow_rounded
                              : job.status == AnalysisJobStatus.running
                              ? Icons.hourglass_top_rounded
                              : Icons.analytics_rounded,
                          color: AnalysisPalette.panel,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AnalysisPalette.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        deleting
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AnalysisPalette.neonBlue,
                                ),
                              )
                            : IconButton(
                                onPressed: onDelete,
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: AnalysisPalette.muted,
                                  size: 22,
                                ),
                                splashRadius: 20,
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                                padding: EdgeInsets.zero,
                                tooltip: 'Delete analysis',
                              ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AnalysisPalette.muted,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _HistoryMiniStat(
                            label: 'SCORE',
                            value: scoreLabel,
                            valueColor: job.status == AnalysisJobStatus.failed
                                ? AnalysisPalette.danger
                                : AnalysisPalette.neonBlue,
                          ),
                        ),
                        Expanded(
                          child: _HistoryMiniStat(
                            label: 'POSSESSION',
                            value: possessionLabel,
                            valueColor: AnalysisPalette.text,
                          ),
                        ),
                      ],
                    ),
                    if (result == null &&
                        job.resultAvailable &&
                        job.status == AnalysisJobStatus.completed) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tap to load full match details',
                        style: TextStyle(
                          color: AnalysisPalette.muted,
                          fontSize: 11.5,
                        ),
                      ),
                    ] else if (job.status == AnalysisJobStatus.completed)
                      const SizedBox(height: 2),
                    if (job.status == AnalysisJobStatus.running ||
                        job.status == AnalysisJobStatus.queued) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          value: (job.progress.progress).clamp(0.0, 1.0),
                          color: AnalysisPalette.neonBlue,
                          backgroundColor: AnalysisPalette.softTrack,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _statusLabel(AnalysisJobSummary job) {
    switch (job.status) {
      case AnalysisJobStatus.completed:
        return job.request.analysisPreset.toUpperCase();
      case AnalysisJobStatus.running:
        return 'RUNNING';
      case AnalysisJobStatus.queued:
        return 'QUEUED';
      case AnalysisJobStatus.failed:
        return 'FAILED';
      case AnalysisJobStatus.canceled:
        return 'CANCELED';
    }
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = (date.month >= 1 && date.month <= 12)
        ? months[date.month - 1]
        : '---';
    final day = date.day.toString().padLeft(2, '0');
    return '$month $day, ${date.year}';
  }
}

class _HistoryMiniStat extends StatelessWidget {
  const _HistoryMiniStat({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AnalysisPalette.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _HistoryQuickStatCard extends StatelessWidget {
  const _HistoryQuickStatCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: glowPanelDecoration(radius: 18),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AnalysisPalette.muted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisBottomBar extends StatelessWidget {
  const _AnalysisBottomBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('HISTORY', Icons.grid_view_rounded),
      ('ANALYSIS', Icons.analytics_rounded),
      ('TEAMS', Icons.groups_rounded),
      ('SETTINGS', Icons.settings_rounded),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AnalysisPalette.panel,
        border: Border(top: BorderSide(color: AnalysisPalette.softLine)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: List.generate(items.length, (i) {
          final selected = i == index;
          final item = items[i];
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          item.$2,
                          color: selected
                              ? AnalysisPalette.neonBlue
                              : AnalysisPalette.muted,
                        ),
                        if (selected)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AnalysisPalette.neonBlue,
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox(width: 8, height: 8),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$1,
                      style: TextStyle(
                        color: selected
                            ? AnalysisPalette.neonBlue
                            : AnalysisPalette.muted,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.text,
    this.icon = Icons.warning_amber_rounded,
    this.accent,
  });

  final String text;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final accentColor = accent ?? AnalysisPalette.danger;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AnalysisPalette.errorBannerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.55)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AnalysisPalette.text, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _PitchPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final grass = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AnalysisPalette.pitchGrassTop,
          AnalysisPalette.pitchGrassBottom,
        ],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      grass,
    );

    final linePaint = Paint()
      ..color = AnalysisPalette.pitchLine
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height * 0.64);
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.38),
      Offset(size.width / 2, size.height),
      linePaint,
    );
    canvas.drawCircle(center, size.width * 0.11, linePaint);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.39,
        size.height * 0.12,
        size.width * 0.22,
        size.height * 0.16,
      ),
      linePaint,
    );

    final lightPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [Colors.white.withValues(alpha: 0.32), Colors.transparent],
          ).createShader(
            Rect.fromCircle(center: Offset(size.width * 0.15, 24), radius: 70),
          );
    canvas.drawCircle(Offset(size.width * 0.15, 24), 70, lightPaint);
    canvas.drawCircle(Offset(size.width * 0.85, 24), 70, lightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 10.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AnalysisPalette.ringTrackBase;
    canvas.drawArc(rect, 0, 6.283185, false, base);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -1.5708,
        endAngle: 4.7124,
        colors: [
          AnalysisPalette.neonBlue,
          AnalysisPalette.cyan,
          AnalysisPalette.violet,
          AnalysisPalette.neonBlue,
        ],
      ).createShader(rect);
    canvas.drawArc(
      rect,
      -1.5708,
      6.283185 * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _TimelineEntry {
  const _TimelineEntry({
    required this.title,
    required this.subtitle,
    required this.teamName,
    required this.timeLabel,
    required this.confidence,
    required this.eventType,
  });

  final String title;
  final String subtitle;
  final String teamName;
  final String timeLabel;
  final double confidence;
  final String eventType;
}

class _TopTrackAccumulator {
  _TopTrackAccumulator({required this.trackId});

  final int trackId;
  String? teamName;
  int events = 0;
  int passes = 0;
  int shots = 0;
  double totalConfidence = 0;
}

class _TopTrackSummary {
  const _TopTrackSummary({
    required this.trackId,
    required this.teamName,
    required this.events,
    required this.passes,
    required this.shots,
    required this.rating,
  });

  final int trackId;
  final String teamName;
  final int events;
  final int passes;
  final int shots;
  final double rating;
}

String _formatInt(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final fromEnd = text.length - i;
    buffer.write(text[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
