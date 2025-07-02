# 🛠️ Script Automatisé de Mise à Jour Proxmox : `update-proxmox.sh`

## 🎯 Objectif

Ce script Bash permet de :
- Mettre à jour le **nœud Proxmox VE**
- Mettre à jour tous les **conteneurs LXC actifs** (avec gestion des exclus)
- Simuler la mise à jour des **VMs** (à compléter avec SSH)
- Envoyer un **rapport par email (s-nail)** et une **notification Telegram**
- Journaliser toutes les actions dans un log dédié

---

## ⚙️ Fonctionnalités

- Mise à jour silencieuse avec `apt` (sans interaction)
- Rotation automatique des logs (conservation 7 jours)
- Détection automatique de la version de l’OS
- Mise à jour conditionnelle des conteneurs
- Simulation de traitement des VMs
- Notification :
  - 📧 par email (`s-nail` via SMTP)
  - 📲 via Telegram (bot)

---

## ✅ Prérequis

### Paquets nécessaires :
```bash
sudo apt install s-nail curl jq sshpass netcat
```

### Accès :
- Script à lancer en root (`sudo`)
- Accès root ou autorisations suffisantes pour Proxmox (`pct`, `qm`, etc.)

---

## 🔐 Paramètres à configurer dans le script

```bash
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="votre.email@gmail.com"
SMTP_PASS="le_mot_de_passe_d_application"
EMAIL_TO="destinataire@email.com"
EMAIL_FROM="votre.email@gmail.com"

TELEGRAM_TOKEN="123456789:ABC...XYZ"
TELEGRAM_CHAT_ID="12345678"
IGNORED_CONTAINERS=(210 105 108)
```

---

## 🕒 Automatisation (cron)

Exécution chaque dimanche à 4h :

```cron
0 4 * * 0 /usr/local/bin/update-proxmox.sh >> /var/log/proxmox-update/cron.log 2>&1
```

---

## 🧪 Simulation VM

La mise à jour des VMs est **actuellement simulée**. Tu peux étendre le script pour :
- Se connecter via SSH avec `sshpass`
- Lancer `apt update && upgrade` à distance

---

## 🪪 Exemple de sortie

```text
Résumé de la mise à jour Proxmox :
- Version OS : Debian GNU/Linux 12 (bookworm)
- Conteneurs mis à jour : 4
- Conteneurs ignorés : 2
- Conteneurs non démarrés : 1
- VMs mises à jour (simulation) : 3
```

---

## 📁 Emplacement recommandé

```bash
sudo cp update-proxmox.sh /usr/local/bin/update-proxmox.sh
sudo chmod +x /usr/local/bin/update-proxmox.sh
```

---

## 👤 Auteur

- Auteur : rto54
- Date : Juillet 2025
- Licence : usage privé / libre
