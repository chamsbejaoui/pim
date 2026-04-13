import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/players_provider.dart';
import '../../widgets/status_badge.dart';
import '../players/player_detail_screen.dart';

class MedicalVaultScreen extends StatefulWidget {
  const MedicalVaultScreen({super.key});

  @override
  State<MedicalVaultScreen> createState() => _MedicalVaultScreenState();
}

class _MedicalVaultScreenState extends State<MedicalVaultScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch all players to filter locally for now, 
    // or we could add an API filter for medical specific.
    Provider.of<PlayersProvider>(context, listen: false).fetchPlayers();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlayersProvider>(context);
    // Medical Vault shows players who are injured OR have medical notes
    final medicalCases = provider.players.where((p) => 
        p.status == 'injured' || (p.medicalNotes != null && p.medicalNotes!.isNotEmpty)
    ).toList();

    return Scaffold(
      backgroundColor: OdinTheme.background,
      body: Column(
        children: [
          // ─── Vault Overview ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: OdinTheme.surfaceLight.withValues(alpha: 0.5),
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: OdinTheme.cardBorder),
               ),
               child: Row(
                 children: [
                   Expanded(
                     child: _buildMetric(
                       label: 'Dossiers Actifs',
                       value: '${medicalCases.length}',
                       color: OdinTheme.primaryBlue,
                     ),
                   ),
                   Expanded(
                     child: _buildMetric(
                       label: 'Blessés',
                       value: '${medicalCases.where((p) => p.status == 'injured').length}',
                       color: OdinTheme.accentRed,
                     ),
                   ),
                 ],
               ),
            ),
          ),

          // ─── Case List ─────────────────────────────
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: OdinTheme.primaryBlue))
                : medicalCases.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.health_and_safety_outlined,
                                size: 64, color: OdinTheme.textTertiary),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun dossier médical nécessitant attention',
                              style: TextStyle(color: OdinTheme.textTertiary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: medicalCases.length,
                        itemBuilder: (context, i) => _buildMedicalCard(medicalCases[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalCard(dynamic player) {
    final isInjured = player.status == 'injured';
    final df = DateFormat('dd/MM/yyyy');

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlayerDetailScreen(playerId: player.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: OdinTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isInjured ? OdinTheme.accentRed.withValues(alpha: 0.5) : OdinTheme.cardBorder,
            width: isInjured ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (isInjured)
              BoxShadow(
                color: OdinTheme.accentRed.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: (isInjured ? OdinTheme.accentRed : OdinTheme.primaryBlue).withValues(alpha: 0.2),
                  child: Icon(
                    isInjured ? Icons.local_hospital_rounded : Icons.medical_information_rounded,
                    color: isInjured ? OdinTheme.accentRed : OdinTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.fullName,
                        style: const TextStyle(
                          color: OdinTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          StatusBadge(status: player.status, fontSize: 10),
                          if (player.returnDate != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Retour: ${df.format(player.returnDate!)}',
                              style: const TextStyle(
                                color: OdinTheme.accentOrange,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: OdinTheme.textTertiary),
              ],
            ),
            if (player.medicalNotes != null && player.medicalNotes!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: OdinTheme.cardBorder),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note_alt_rounded, size: 16, color: OdinTheme.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      player.medicalNotes!,
                      style: const TextStyle(
                        color: OdinTheme.textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: OdinTheme.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
