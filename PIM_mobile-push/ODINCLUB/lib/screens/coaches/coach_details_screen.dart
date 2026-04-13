import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class CoachDetailsScreen extends StatefulWidget {
  final String coachId;
  const CoachDetailsScreen({super.key, required this.coachId});

  @override
  State<CoachDetailsScreen> createState() => _CoachDetailsScreenState();
}

class _CoachDetailsScreenState extends State<CoachDetailsScreen> {
  final _apiService = ApiService();
  Map<String, dynamic>? _coach;
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
    final coachRes = await _apiService.getCoach(widget.coachId);

    if (coachRes['success'] && mounted) {
      setState(() {
        _coach = coachRes['data']['data'];
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(coachRes['message'] ?? 'Failed to load coach')),
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
        title: Text('Coach Details'),
        backgroundColor: AppTheme.odinDarkBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _coach == null
              ? const Center(child: Text('No coach found'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      '${_coach!['firstName']} ${_coach!['lastName']}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.odinDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _detailRow('Role', _coach!['role']),
                    _detailRow('Contract end', _formatDate(_coach!['contractEndDate'])),
                    _detailRow('Salary', _coach!['salary']?.toString() ?? 'N/A'),
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
