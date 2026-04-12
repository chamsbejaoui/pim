# Finance UI Module (Mobile)

## What was added
- A dedicated `finance` module under `lib/finance`.
- One file per screen:
  - `dashboard_screen.dart`
  - `sponsors_screen.dart` (revenus)
  - `accounting_screen.dart`
  - `payroll_screen.dart`
  - `transfers_screen.dart`
  - `treasury_screen.dart`
  - `budget_screen.dart` (depenses + thresholds)
  - `audit_screen.dart`
- Shared mobile shell:
  - `finance_mobile_shell.dart` (tab chips + screen switching)
- Dynamic store and models:
  - `models/finance_models.dart`
  - `services/finance_store.dart`
- Shared theme:
  - `theme/finance_theme.dart`
- Shared widgets:
  - `widgets/finance_widgets.dart`
- Barrel export:
  - `finance.dart`

## Implemented finance services
- 1) Gestion Comptable Generale:
  - Plan comptable (CRUD)
  - Journal comptable (ecritures manuelles/auto, draft/posted)
  - Grand livre
  - Balance comptable
  - Bilan
  - Compte de resultat
  - Cloture mensuelle
  - Export PDF/Excel/FEC (UI actions)
- 2) Gestion des Salaires:
  - Salaire fixe
  - Primes (match/performance/signing)
  - Penalites/amendes
  - Avantages
  - Cotisations sociales
  - Impots
  - Net a payer
  - Historique paiements
  - Fiche de paie PDF (UI action)
  - Export virement bancaire (UI action)
- 3) Transferts & indemnites:
  - Montant entrant/sortant
  - Tranches
  - Pourcentage revente
  - Bonus conditionnels
  - Commissions agents
  - Amortissement joueur
  - Paiement tranche
- 4) Revenus:
  - Billetterie
  - Sponsoring
  - Droits TV
  - Merchandising
  - Subventions
  - Academy fees
  - Prize money
  - Lien saison + competition + forecast vs actual
- 5) Depenses:
  - Categories operationnelles
  - Justificatif (nom fichier PDF)
  - Workflow multi-level (submit / approve / reject)
- Audit:
  - Every action appends to the immutable-looking audit timeline in UI store.

## How to connect backend data
1. Replace in-memory store operations with API endpoints in `finance_store.dart`.
2. Keep the same UI contracts and map backend DTOs to models.
3. Preserve audit writes for each sensitive/financial action.

## Suggested next step
- Add pull-to-refresh and loading/error states per screen.
