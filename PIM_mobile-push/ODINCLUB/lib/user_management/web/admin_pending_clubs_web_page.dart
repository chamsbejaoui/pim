import 'package:flutter/material.dart';

import '../api/user_management_api.dart';
import '../models/user_management_models.dart';

class AdminPendingClubsWebPage extends StatefulWidget {
  const AdminPendingClubsWebPage({
    super.key,
    required this.token,
    required this.onLogout,
    required this.api,
  });

  final String token;
  final VoidCallback onLogout;
  final UserManagementApi api;

  @override
  State<AdminPendingClubsWebPage> createState() =>
      _AdminPendingClubsWebPageState();
}

class _AdminPendingClubsWebPageState extends State<AdminPendingClubsWebPage> {
  bool _loading = true;
  String? _error;
  List<ClubModel> _clubs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await widget.api.getPendingClubs(widget.token);
      if (mounted) {
        setState(() {
          _clubs = list;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _approve(ClubModel club, bool approve) async {
    try {
      await widget.api.approveClub(widget.token, club.id, approve);
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Clubs en attente'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
          TextButton(onPressed: widget.onLogout, child: const Text('Logout')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : _clubs.isEmpty
            ? const Center(child: Text('Aucun club en attente'))
            : ListView.separated(
                itemBuilder: (_, index) {
                  final club = _clubs[index];
                  return Card(
                    child: ListTile(
                      title: Text(club.name),
                      subtitle: Text(
                        'Ligue: ${club.league} • Statut: ${club.status}',
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () => _approve(club, false),
                            child: const Text('Rejeter'),
                          ),
                          FilledButton(
                            onPressed: () => _approve(club, true),
                            child: const Text('Approuver'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemCount: _clubs.length,
              ),
      ),
    );
  }
}
