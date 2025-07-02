# 🔄 update-proxmox.sh

Script Bash pour automatiser la mise à jour de votre nœud **Proxmox VE**, des **conteneurs LXC** et des **machines virtuelles (VMs)**. Il envoie également un **rapport par email** avec les logs en pièce jointe et une **notification Telegram**.

## ✨ Fonctionnalités

- Mise à jour du nœud Proxmox via `apt`
- Mise à jour des conteneurs LXC (sauf ceux ignorés)
- Support basique pour les VMs (simulation ou extension possible via SSH/agent)
- Envoi d'un rapport par email avec les logs en pièce jointe
- Notification Telegram avec résumé des mises à jour
- Rotation automatique des logs (> 7 jours supprimés)

## 📁 Emplacement recommandé

Placez le script dans :

```bash
/usr/local/bin/update-proxmox.sh
```

Rendez-le exécutable :

```bash
chmod +x /usr/local/bin/update-proxmox.sh
```
Programmez le lancement auto avec contrab :

crontab -e
0 3 * * * /usr/local/bin/update-proxmox.sh

## ⚙️ Configuration

Le script est à configurer dans la section suivante :

```bash
# Conteneurs à ignorer
IGNORED_CONTAINERS=(210 105 108)

# Répertoires des logs
LOG_DIR="/var/log/proxmox-update"

# SMTP pour envoi du mail
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="votre.email@gmail.com"
SMTP_PASS="le_mot_de_passe_d_application"
EMAIL_TO="votre.email@gmail.com"
EMAIL_FROM="votre.email@gmail.com"

# Telegram
TELEGRAM_TOKEN="your_telegram_bot_token"
TELEGRAM_CHAT_ID="your_chat_id"
```

## 📬 Dépendances

- `mailx`
- `curl`
- Accès `root`
- Proxmox VE (avec commandes `pct` et `qm` disponibles)

## 📬 Configuration gmail

Créer un mot de passe d’application (Gmail)
Connectez-vous à https://myaccount.google.com
Activez la validation en deux étapes
Allez dans Sécurité > Mots de passe d’application
Créez un mot de passe pour “Mail” et “Autre (nommez-le Proxmox)”
Copiez le mot de passe généré (16 caractères)

## ✅ Utilisation

Lancez simplement le script avec les privilèges root :

```bash
sudo /usr/local/bin/update-proxmox.sh
```

## 📌 Remarques

- Les VMs ne sont pas mises à jour automatiquement (simulé uniquement).
- Pour ajouter une vraie mise à jour des VMs, vous pouvez intégrer un accès SSH à l’intérieur de la boucle `qm`.

## 🧑‍💻 Auteur

- rto54

