import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'coach_details_screen.dart';

class CoachesListView extends StatefulWidget {
  const CoachesListView({super.key});

  @override
  State<CoachesListView> createState() => _CoachesListViewState();
}

class _CoachesListViewState extends State<CoachesListView> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _coaches = [];
  bool _isLoading = false;
  int _page = 1;
  int _limit = 20;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _salaryController = TextEditingController();

  String _role = 'HEAD_COACH';
  DateTime? _contractEndDate;

  final List<String> _roles = [
    'HEAD_COACH',
    'ASSISTANT',
    'FITNESS',
    'GOALKEEPER',
    'ANALYST',
  ];

  @override
  void initState() {
    super.initState();
    _loadCoaches();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _loadCoaches() async {
    setState(() {
      _isLoading = true;
    });
    final result = await _apiService.getCoaches(page: _page, limit: _limit);
    setState(() {
      _isLoading = false;
    });

    if (result['success'] && mounted) {
      setState(() {
        _coaches = result['data']['data'] ?? [];
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to load coaches')),
      );
    }
  }

  Future<void> _openCreateCoach() async {
    _firstNameController.clear();
    _lastNameController.clear();
    _salaryController.clear();
    _role = 'HEAD_COACH';
    _contractEndDate = null;

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
                  'Add Coach',
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
                DropdownButtonFormField<String>(
                  value: _role,
                  items: _roles
                      .map((pos) => DropdownMenuItem(value: pos, child: Text(pos)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _role = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Role'),
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
                TextFormField(
                  controller: _salaryController,
                  decoration: const InputDecoration(labelText: 'Salary (optional)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitCreate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.odinDarkBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Create Coach'),
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

    final salary = _salaryController.text.trim();
    final body = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'role': _role,
      'contractEndDate': _contractEndDate!.toIso8601String(),
      if (salary.isNotEmpty) 'salary': double.parse(salary),
    };

    final result = await _apiService.createCoach(body);
    if (result['success'] && mounted) {
      Navigator.of(context).pop();
      _loadCoaches();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to create coach')),
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
                Icon(Icons.sports, color: AppTheme.odinDarkBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Coaches',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.odinDarkBlue,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openCreateCoach,
                  icon: Icon(Icons.add),
                  label: Text('Add Coach'),
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
                    onRefresh: _loadCoaches,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _coaches.length,
                      itemBuilder: (context, index) {
                        final coach = _coaches[index];
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
                                Text(
                                  '${coach['firstName']} ${coach['lastName']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.odinDarkBlue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Role: ${coach['role']}'),
                                Text(
                                  'Contract end: ${_formatDate(DateTime.parse(coach['contractEndDate']))}',
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => CoachDetailsScreen(coachId: coach['_id']),
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
