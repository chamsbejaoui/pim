# Guide de Configuration - Variables d'Environnement

Ce guide vous explique comment configurer toutes les variables d'environnement nécessaires pour le backend ODIN Club.

## Étape 1: Créer le fichier .env

```bash
cp .env.example .env
```

## Étape 2: Configuration de la Base de Données MongoDB

### Option A: MongoDB Local (Sans mot de passe)

Si MongoDB est déjà démarré localement sans authentification:

1. **Vérifier que MongoDB est en cours d'exécution**:
   ```bash
   # macOS
   brew services list | grep mongodb
   
   # Linux
   sudo systemctl status mongod
   ```

2. **Configurer dans .env**:
   ```env
   MONGODB_URI=mongodb://localhost:27017/odin_club
   ```

### Option B: MongoDB avec Docker

```bash
docker run --name odin-mongodb \
  -p 27017:27017 \
  -d mongo:latest
```

Puis dans `.env`:
```env
MONGODB_URI=mongodb://localhost:27017/odin_club
```

### Option C: MongoDB avec Authentification

Si votre MongoDB nécessite une authentification:
```env
MONGODB_URI=mongodb://username:password@localhost:27017/odin_club?authSource=admin
```

### Option D: MongoDB Atlas (Cloud)

Si vous utilisez MongoDB Atlas:
```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/odin_club?retryWrites=true&w=majority
```

**Note:** La base de données `odin_club` sera créée automatiquement lors de la première utilisation.

## Étape 3: Configuration Email (SMTP)

### Option A: Gmail (Recommandé pour le développement)

1. **Activer la vérification en 2 étapes**:
   - Allez sur [myaccount.google.com](https://myaccount.google.com)
   - Sécurité → Vérification en deux étapes → Activer

2. **Générer un mot de passe d'application**:
   - Allez sur [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)
   - Sélectionnez "Mail" et "Autre (nom personnalisé)"
   - Entrez "ODIN Club Backend"
   - Copiez le mot de passe généré (16 caractères)

3. **Configurer dans .env**:
   ```env
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=votre-email@gmail.com
   SMTP_PASS=votre-mot-de-passe-application-16-caracteres
   ```

### Option B: Outlook/Hotmail

```env
SMTP_HOST=smtp-mail.outlook.com
SMTP_PORT=587
SMTP_USER=votre-email@outlook.com
SMTP_PASS=votre-mot-de-passe
```

### Option C: Mailtrap (Pour les tests - ne pas utiliser en production)

1. Créez un compte sur [mailtrap.io](https://mailtrap.io)
2. Créez une inbox de test
3. Utilisez les credentials fournis:
   ```env
   SMTP_HOST=smtp.mailtrap.io
   SMTP_PORT=2525
   SMTP_USER=votre-username-mailtrap
   SMTP_PASS=votre-password-mailtrap
   ```

### Option D: Autres services SMTP

- **SendGrid**: `smtp.sendgrid.net` (port 587)
- **Mailgun**: `smtp.mailgun.org` (port 587)
- **Amazon SES**: Vérifiez la documentation AWS

## Étape 4: Configuration Google OAuth

### 1. Créer un projet Google Cloud

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Cliquez sur "Sélectionner un projet" → "Nouveau projet"
3. Nommez le projet (ex: "ODIN Club")
4. Cliquez sur "Créer"

### 2. Activer l'API Google+

1. Dans le menu, allez dans "APIs & Services" → "Library"
2. Recherchez "Google+ API" ou "Google Identity"
3. Cliquez sur "Enable"

### 3. Créer les identifiants OAuth 2.0

1. Allez dans "APIs & Services" → "Credentials"
2. Cliquez sur "Create Credentials" → "OAuth client ID"
3. Si demandé, configurez l'écran de consentement OAuth:
   - Type d'application: Externe
   - Nom de l'application: ODIN Club
   - Email de support: votre email
   - Domaines autorisés: (laissez vide pour le développement)
   - Cliquez sur "Save and Continue" jusqu'à la fin

4. Créez l'OAuth client ID:
   - Type d'application: Application Web
   - Nom: ODIN Club Web Client
   - URI de redirection autorisés:
     - `http://localhost:3000/auth/google/callback` (développement)
     - `https://votre-domaine.com/auth/google/callback` (production)

5. Cliquez sur "Create"
6. **Copiez le Client ID et Client Secret**

### 4. Configurer dans .env

```env
GOOGLE_CLIENT_ID=votre-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=votre-client-secret
GOOGLE_CALLBACK_URL=http://localhost:3000/auth/google/callback
```

## Étape 5: Configuration JWT et Autres

### JWT Secret

Générez une clé secrète forte (pour la production, utilisez une clé aléatoire):

```bash
# Générer une clé aléatoire
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

Puis dans `.env`:
```env
JWT_SECRET=votre-clé-secrète-générée
```

### Frontend URL

```env
FRONTEND_URL=http://localhost:3000
# En production: https://votre-domaine.com
```

### Port du serveur

```env
PORT=3000
NODE_ENV=development
# En production: NODE_ENV=production
```

## Exemple de fichier .env complet

```env
# Database Configuration (MongoDB)
MONGODB_URI=mongodb://localhost:27017/odin_club

# JWT Configuration
JWT_SECRET=ma-super-clé-secrète-jwt-changez-moi-en-production-1234567890abcdef

# Email Configuration (Gmail)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=mon-email@gmail.com
SMTP_PASS=abcd efgh ijkl mnop

# Frontend URL
FRONTEND_URL=http://localhost:3000

# Google OAuth Configuration
GOOGLE_CLIENT_ID=123456789-abcdefghijklmnop.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-abcdefghijklmnopqrstuvwxyz
GOOGLE_CALLBACK_URL=http://localhost:3000/auth/google/callback

# Server Configuration
PORT=3000
NODE_ENV=development
```

## Vérification de la Configuration

### Tester la connexion à la base de données

```bash
# Se connecter à MongoDB
mongosh mongodb://localhost:27017/odin_club

# Ou avec l'ancienne commande
mongo mongodb://localhost:27017/odin_club
```

### Tester l'envoi d'email

Lancez l'application et essayez de vous inscrire. Vérifiez votre boîte mail (ou Mailtrap si vous l'utilisez).

### Tester Google OAuth

1. Lancez l'application: `npm run start:dev`
2. Visitez: `http://localhost:3000/auth/google`
3. Vous devriez être redirigé vers Google pour l'authentification

## Dépannage

### Erreur de connexion à la base de données
- Vérifiez que MongoDB est démarré (`mongod` ou `brew services list`)
- Vérifiez l'URI MongoDB dans `.env`
- Vérifiez que le port 27017 est accessible
- La base de données sera créée automatiquement au premier usage

### Erreur d'envoi d'email
- Pour Gmail: Vérifiez que vous utilisez un "App Password" et non votre mot de passe normal
- Vérifiez que la vérification en 2 étapes est activée
- Testez avec Mailtrap pour isoler le problème

### Erreur Google OAuth
- Vérifiez que l'API est activée dans Google Cloud Console
- Vérifiez que l'URI de redirection correspond exactement
- Vérifiez que le Client ID et Secret sont corrects

## Sécurité en Production

⚠️ **IMPORTANT pour la production:**

1. Changez `JWT_SECRET` pour une clé aléatoire forte
2. Utilisez `NODE_ENV=production`
3. Configurez HTTPS
4. Utilisez des variables d'environnement sécurisées (pas de fichier .env en production)
5. Configurez l'authentification MongoDB en production
6. Configurez un firewall pour la base de données
7. Utilisez un service email professionnel (SendGrid, Mailgun, etc.)
8. Utilisez MongoDB Atlas ou un service cloud avec sauvegarde automatique
