import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../ui/theme/medical_theme.dart';
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

    return MedicalThemeScope(
      child: Scaffold(
        backgroundColor: MedicalTheme.background,
      body: Column(
        children: [
          // ─── Vault Overview ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: MedicalTheme.surfaceAlt.withValues(alpha: 0.6),
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: MedicalTheme.cardBorder),
               ),
               child: Row(
                 children: [
                   Expanded(
                     child: _buildMetric(
                       label: 'Dossiers Actifs',
                       value: '${medicalCases.length}',
                       color: MedicalTheme.primaryBlue,
                     ),
                   ),
                   Expanded(
                     child: _buildMetric(
                       label: 'Blessés',
                       value: '${medicalCases.where((p) => p.status == 'injured').length}',
                       color: MedicalTheme.danger,
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
                    child: CircularProgressIndicator(color: MedicalTheme.primaryBlue))
                : medicalCases.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.health_and_safety_outlined,
                                size: 64, color: MedicalTheme.textMuted),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun dossier médical nécessitant attention',
                              style: TextStyle(color: MedicalTheme.textMuted),
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
          color: MedicalTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isInjured
                ? MedicalTheme.danger.withValues(alpha: 0.5)
                : MedicalTheme.cardBorder,
            width: isInjured ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (isInjured)
              BoxShadow(
                color: MedicalTheme.danger.withValues(alpha: 0.1),
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
                  backgroundColor: (isInjured
                          ? MedicalTheme.danger
                          : MedicalTheme.primaryBlue)
                      .withValues(alpha: 0.2),
                  child: Icon(
                    isInjured ? Icons.local_hospital_rounded : Icons.medical_information_rounded,
                    color: isInjured
                        ? MedicalTheme.danger
                        : MedicalTheme.primaryBlue,
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
                          color: MedicalTheme.textPrimary,
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
                              style: TextStyle(
                                color: MedicalTheme.warning,
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
                Icon(Icons.chevron_right_rounded, color: MedicalTheme.textMuted),
              ],
            ),
            if (player.medicalNotes != null && player.medicalNotes!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: MedicalTheme.cardBorder),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note_alt_rounded,
                    size: 16,
                    color: MedicalTheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      player.medicalNotes!,
                      style: const TextStyle(
                        color: MedicalTheme.textSecondary,
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
          style: TextStyle(
            color: MedicalTheme.textMuted,
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
