import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'player_details_screen.dart';

class PlayersListView extends StatefulWidget {
  const PlayersListView({super.key});

  @override
  State<PlayersListView> createState() => _PlayersListViewState();
}

class _PlayersListViewState extends State<PlayersListView> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _players = [];
  bool _isLoading = false;
  int _page = 1;
  int _limit = 20;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _injuryDetailsController = TextEditingController();

  String _position = 'GK';
  DateTime? _contractEndDate;
  bool _isInjured = false;

  final List<String> _positions = [
    'GK',
    'CB',
    'LB',
    'RB',
    'CDM',
    'CM',
    'CAM',
    'LW',
    'RW',
    'ST',
  ];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _injuryDetailsController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
    });
    final result = await _apiService.getPlayers(page: _page, limit: _limit);
    setState(() {
      _isLoading = false;
    });

    if (result['success'] && mounted) {
      setState(() {
        _players = result['data']['data'] ?? [];
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to load players')),
      );
    }
  }

  Future<void> _openCreatePlayer() async {
    _firstNameController.clear();
    _lastNameController.clear();
    _ageController.clear();
    _injuryDetailsController.clear();
    _position = 'GK';
    _contractEndDate = null;
    _isInjured = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Player',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.odinDarkBlue,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final age = int.tryParse(value);
                    if (age == null) return 'Invalid number';
                    if (age < 14 || age > 60) return 'Age must be 14-60';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _position,
                  items: _positions
                      .map((pos) => DropdownMenuItem(value: pos, child: Text(pos)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _position = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Position'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _contractEndDate == null
                            ? 'Contract end date'
                            : 'Contract ends: ${_formatDate(_contractEndDate!)}',
                      ),
                    ),
                    TextButton(
                      onPressed: _pickContractDate,
                      child: Text('Pick date'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isInjured,
                  onChanged: (value) {
                    setState(() {
                      _isInjured = value;
                    });
                  },
                  title: Text('Injured'),
                ),
                if (_isInjured) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _injuryDetailsController,
                    decoration: const InputDecoration(labelText: 'Injury details'),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitCreate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.odinDarkBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Create Player'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickContractDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _contractEndDate ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        _contractEndDate = picked;
      });
    }
  }

  Future<void> _submitCreate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_contractEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contract end date is required')),
      );
      return;
    }

    final body = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'age': int.parse(_ageController.text.trim()),
      'position': _position,
      'contractEndDate': _contractEndDate!.toIso8601String(),
      'isInjured': _isInjured,
      'injuryDetails': _isInjured ? _injuryDetailsController.text.trim() : null,
    };

    final result = await _apiService.createPlayer(body);
    if (result['success'] && mounted) {
      Navigator.of(context).pop();
      _loadPlayers();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to create player')),
      );
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.gradientDecoration,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.sports_soccer, color: AppTheme.odinDarkBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Players',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.odinDarkBlue,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openCreatePlayer,
                  icon: Icon(Icons.add),
                  label: Text('Add Player'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.odinDarkBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadPlayers,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _players.length,
                      itemBuilder: (context, index) {
                        final player = _players[index];
                        final isInjured = player['isInjured'] == true;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${player['firstName']} ${player['lastName']}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.odinDarkBlue,
                                        ),
                                      ),
                                    ),
                                    if (isInjured)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Injured',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Age: ${player['age']}'),
                                Text('Position: ${player['position']}'),
                                Text(
                                  'Contract end: ${_formatDate(DateTime.parse(player['contractEndDate']))}',
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PlayerDetailsScreen(playerId: player['_id']),
                                        ),
                                      );
                                    },
                                    child: Text('See more'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
