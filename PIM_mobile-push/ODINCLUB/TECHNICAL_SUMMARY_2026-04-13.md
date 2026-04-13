# Resume technique

Date: 2026-04-13
Perimetre: Flux creation de compte et approbation admin depuis le front Flutter

## 1) Objectif livre

Rendre operationnel le parcours complet suivant depuis le front:
- inscription d un responsable de club
- inscription d un membre de club
- approbation ou rejet des comptes en attente par un admin
- conservation du flux d approbation cote responsable de club

## 2) Flux metier confirme

### A. Inscription Responsable
- Ecran front: formulaire d inscription responsable
- API: POST /auth/register/responsable
- Etat initial user: PENDING_ADMIN_APPROVAL
- Etat initial club: PENDING
- Action attendue: validation admin

### B. Inscription Membre
- Ecran front: formulaire d inscription membre
- API: POST /auth/register/member
- Etat initial user: PENDING_CLUB_APPROVAL
- Action attendue: validation responsable club

### C. Approbation Utilisateur par Admin
- Recuperation comptes en attente: GET /users/pending
- Action de validation: PATCH /users/:userId/approval/admin
- Payload action: status = ACTIVE ou REJECTED

### D. Approbation Utilisateur par Responsable Club
- Recuperation comptes en attente: GET /users/pending
- Action de validation: PATCH /users/:userId/approval
- Payload action: status = ACTIVE ou REJECTED

## 3) Integrations front implementees

### 3.1 Ecran admin utilisateurs (avant: placeholder)
- L ecran admin users affiche maintenant les comptes en attente
- Actions disponibles: Approve et Reject
- Gestion des etats UI: loading, erreur, empty state, refresh
- Protection simple: vue reservee au role ADMIN

### 3.2 Client API user management
- Methode approveUser rendue role-aware
- Choix automatique de la route selon le contexte:
  - mode admin => /users/:id/approval/admin
  - mode responsable => /users/:id/approval

### 3.3 Compatibilite du service API legacy
- Normalisation de la lecture des reponses pour:
  - GET /users/pending
  - GET /users
- Le code accepte maintenant les 2 formes de reponse:
  - liste directe
  - objet contenant users
- Objectif: eviter les erreurs runtime sur les ecrans admin legacy

## 4) Fichiers modifies

- lib/ui/screens/admin_users_screen.dart
  - Remplacement du placeholder par un ecran fonctionnel de validation admin

- lib/user_management/api/user_management_api.dart
  - Extension de approveUser avec parametre asAdmin
  - Routage vers endpoint admin ou responsable

- lib/services/api_service.dart
  - Normalisation des retours getPendingUsers et getAllUsers

## 5) Verification technique

- Verification diagnostics IDE sur les fichiers modifies: aucune erreur detectee
- Aucune execution e2e complete lancee dans cette passe

## 6) Recette manuelle recommandee

1. Inscrire un responsable via formulaire front
2. Se connecter en admin
3. Ouvrir User management
4. Verifier presence du compte en pending
5. Approver le compte et verifier disparition de la liste pending
6. Refaire le test avec Reject
7. Inscrire un membre et verifier qu il apparait dans le flux de validation responsable club

## 7) Points de vigilance

- Les permissions backend doivent rester coherentes avec les roles ADMIN et CLUB_RESPONSABLE
- Si plusieurs front legacy coexistent, verifier que tous consomment le meme format de reponse users
