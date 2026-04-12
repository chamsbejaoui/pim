# Guide de Démarrage Rapide

## 🚀 Configuration Rapide en 5 Minutes

### 1. Installer les dépendances
```bash
npm install
```

### 2. Créer le fichier .env
```bash
cp .env.example .env
```

### 3. Générer une clé JWT secrète
```bash
npm run generate:jwt-secret
```
Copiez la clé générée dans votre fichier `.env` comme `JWT_SECRET=...`

### 4. Configurer MongoDB

**Si MongoDB est déjà démarré (sans mot de passe):**

Dans `.env`:
```env
MONGODB_URI=mongodb://localhost:27017/odin_club
```

**Option avec Docker:**
```bash
docker run --name odin-mongodb \
  -p 27017:27017 \
  -d mongo:latest
```

Puis dans `.env`:
```env
MONGODB_URI=mongodb://localhost:27017/odin_club
```

### 5. Configurer Email (Gmail - Option la plus simple)

1. Allez sur [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)
2. Créez un mot de passe d'application pour "Mail"
3. Dans `.env`:
```env
SMTP_USER=votre-email@gmail.com
SMTP_PASS=votre-mot-de-passe-application
```

### 6. Configurer Google OAuth (Optionnel pour commencer)

Si vous voulez tester Google login plus tard, suivez le guide dans [SETUP_GUIDE.md](./SETUP_GUIDE.md).

Pour l'instant, vous pouvez mettre des valeurs temporaires:
```env
GOOGLE_CLIENT_ID=temp
GOOGLE_CLIENT_SECRET=temp
```

### 7. Lancer l'application
```bash
npm run start:dev
```

✅ **C'est tout!** L'application devrait démarrer sur `http://localhost:3000`

## 📝 Test Rapide

### Tester l'inscription
```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "firstName": "Test",
    "lastName": "User",
    "role": "Joueur"
  }'
```

### Tester la connexion
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

## 📚 Pour plus de détails

Consultez [SETUP_GUIDE.md](./SETUP_GUIDE.md) pour:
- Configuration détaillée de chaque service
- Dépannage
- Options alternatives (Mailtrap, autres SMTP, etc.)
- Configuration pour la production
