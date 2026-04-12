import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/ai_colors.dart';
import '../../services/report_parser.dart';
import '../../services/ai_api_service.dart';
import '../../models/ai_player.dart';
import 'package:provider/provider.dart';
import '../../providers/campaign_provider.dart';

/// Paste scouting report text, extract via ReportParser, or import file.
class AiReportImportScreen extends StatefulWidget {
  const AiReportImportScreen({super.key});

  @override
  State<AiReportImportScreen> createState() =>
      _AiReportImportScreenState();
}

class _AiReportImportScreenState extends State<AiReportImportScreen> {
  final _textCtrl = TextEditingController();
  bool _parsing = false;
  bool _importing = false;
  List<AiPlayer> _extracted = [];

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _parseText() {
    if (_textCtrl.text.trim().isEmpty) return;
    setState(() => _parsing = true);

    try {
      final results = ReportParser.extractMultiple(_textCtrl.text);
      setState(() {
        _extracted = results;
        _parsing = false;
      });

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No player data detected in the text.'),
          backgroundColor: AiColors.warning,
        ));
      }
    } catch (e) {
      setState(() => _parsing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Parse error: $e'),
        backgroundColor: AiColors.error,
      ));
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.single.bytes;
      if (bytes == null) return;

      final text = String.fromCharCodes(bytes);
      setState(() => _textCtrl.text = text);
      _parseText();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('File error: $e'),
        backgroundColor: AiColors.error,
      ));
    }
  }

  Future<void> _importAll() async {
    if (_extracted.isEmpty) return;
    setState(() => _importing = true);

    int success = 0;
    int failed = 0;

    for (final player in _extracted) {
      try {
        await AiApiService.createPlayer(player);
        success++;
      } catch (_) {
        failed++;
      }
    }

    if (mounted) {
      await context.read<CampaignProvider>().loadPlayers();
      setState(() {
        _importing = false;
        _extracted.clear();
        _textCtrl.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '$success players imported${failed > 0 ? ', $failed failed' : ''}'),
        backgroundColor:
            failed > 0 ? AiColors.warning : AiColors.success,
      ));

      if (success > 0) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AiColors.backgroundDark,
        title: const Text('Import Report',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _pickFile,
            tooltip: 'Import file',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildInputCard(),
          const SizedBox(height: 16),
          if (_extracted.isNotEmpty) ...[
            _buildExtractedList(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _importing ? null : _importAll,
                icon: _importing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_upload),
                label: Text(_importing
                    ? 'Importing...'
                    : 'Import ${_extracted.length} Player(s)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AiColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildInputCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.description,
                color: AiColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Scouting Report',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AiColors.primary)),
          ]),
          const SizedBox(height: 6),
          Text(
            'Paste report text, or import a .txt / .csv file.',
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _textCtrl,
            maxLines: 10,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, height: 1.5),
            decoration: InputDecoration(
              hintText:
                  'Player: Lionel Messi\nAge: 36\nSpeed: 28 km/h\nEndurance: 82\nDistance: 10.3 km\nDribbles: 15\nShots on target: 8\nInjuries: 1\nHeart rate: 68 bpm',
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.15),
                  fontSize: 12),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AiColors.borderDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AiColors.borderDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AiColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file, size: 16),
                label: const Text('Pick File'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AiColors.info,
                  side: const BorderSide(color: AiColors.borderDark),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _parsing ? null : _parseText,
                icon: _parsing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search, size: 16),
                label:
                    Text(_parsing ? 'Parsing...' : 'Extract Stats'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AiColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildExtractedList() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.people,
                color: AiColors.success, size: 20),
            const SizedBox(width: 8),
            Text(
              '${_extracted.length} Player(s) Detected',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AiColors.success),
            ),
          ]),
          const SizedBox(height: 12),
          ..._extracted
              .asMap()
              .entries
              .map((e) => _extractedCard(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _extractedCard(int index, AiPlayer player) {
    final name = player.name;
    final stats = {
      'speed': player.speed,
      'endurance': player.endurance,
      'distance': player.distance,
      'dribbles': player.dribbles,
      'shots': player.shots,
      'injuries': player.injuries,
      'heart_rate': player.heartRate,
    }.entries.toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AiColors.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AiColors.success.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AiColors.success.withOpacity(0.2),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AiColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AiColors.error, size: 18),
              onPressed: () {
                setState(() => _extracted.removeAt(index));
              },
            ),
          ]),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: stats.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${e.key.replaceAll('_', ' ')}: ${e.value}',
                  style: const TextStyle(
                      color: AiColors.textSecondary,
                      fontSize: 10),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AiColors.glassBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AiColors.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}
