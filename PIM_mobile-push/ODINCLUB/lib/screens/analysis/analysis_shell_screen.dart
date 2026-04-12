import 'package:flutter/material.dart';
import '../../analysis/mobile/match_analysis_mobile_shell.dart';
import '../../analysis/theme/analysis_theme.dart';
import '../../user_management/models/user_management_models.dart';

class AnalysisShellScreen extends StatelessWidget {
  const AnalysisShellScreen({super.key, required this.session});

  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    AnalysisPalette.setDarkMode(
      Theme.of(context).brightness == Brightness.dark,
    );
    return MatchAnalysisMobileShell(
      authToken: session.token,
      connectedClubName: session.clubName,
      embedded: true,
    );
  }
}
