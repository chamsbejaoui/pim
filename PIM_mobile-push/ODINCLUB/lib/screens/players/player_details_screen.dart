import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class PlayerDetailsScreen extends StatefulWidget {
  final String playerId;
  const PlayerDetailsScreen({super.key, required this.playerId});

  @override
  State<PlayerDetailsScreen> createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen> {
  final _apiService = ApiService();
  Map<String, dynamic>? _player;
  List<dynamic> _analyses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
    });
    final playerRes = await _apiService.getPlayer(widget.playerId);
    final analysesRes = await _apiService.getPlayerAnalyses(widget.playerId);

    if (playerRes['success'] && mounted) {
      setState(() {
        _player = playerRes['data']['data'];
        _analyses = analysesRes['success'] ? analysesRes['data']['data'] ?? [] : [];
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(playerRes['message'] ?? 'Failed to load player')),
      );
    }
  }

  String _formatDate(String value) {
    final date = DateTime.parse(value);
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Player Details'),
        backgroundColor: AppTheme.odinDarkBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _player == null
              ? const Center(child: Text('No player found'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      '${_player!['firstName']} ${_player!['lastName']}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.odinDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _detailRow('Age', _player!['age'].toString()),
                    _detailRow('Position', _player!['position']),
                    _detailRow('Contract end', _formatDate(_player!['contractEndDate'])),
                    _detailRow('Injured', _player!['isInjured'] == true ? 'Yes' : 'No'),
                    if ((_player!['injuryDetails'] ?? '').toString().isNotEmpty)
                      _detailRow('Injury details', _player!['injuryDetails']),
                    const SizedBox(height: 24),
                    Text(
                      'Analyses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.odinDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_analyses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.odinSkyBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('No analyses available yet.'),
                      )
                    else
                      ..._analyses.map((item) => ListTile(title: Text(item.toString()))),
                  ],
                ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
