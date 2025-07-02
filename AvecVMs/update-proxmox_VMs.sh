#!/bin/bash
#
# Script : update-proxmox.sh
# Objectif : Mettre à jour automatiquement le nœud Proxmox, les conteneurs LXC et les VMs.
#            Envoie un rapport par email avec les logs en pièce jointe et une notification Telegram.
# Auteur : Votre Nom
# Date : 2025-07-02
# Dépendances : mailx, curl, Proxmox VE, jq, sshpass
# Usage : sudo /usr/local/bin/update-proxmox.sh
#

# === CONFIGURATION ===
ROOT_USER="root"
ROOT_PASS="XXXX"
SSH_PORT=22

IGNORED_CONTAINERS=(210 105 108)
LOG_DIR="/var/log/proxmox-update"
LOGFILE="$LOG_DIR/update.log"
ARCHIVE_DIR="$LOG_DIR/archive"

# SMTP
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="votre.email@gmail.com"
SMTP_PASS="le_mot_de_passe_d_application"
EMAIL_TO="votre.email@gmail.com"
EMAIL_FROM="votre.email@gmail.com"

# Telegram
TELEGRAM_TOKEN="your_telegram_bot_token"
TELEGRAM_CHAT_ID="your_chat_id"

# === PRÉPARATION LOGS ===
mkdir -p "$LOG_DIR" "$ARCHIVE_DIR"
find "$LOG_DIR" -type f -name "*.log" -mtime +7 -exec rm {} \;

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

log ""
log "Début des mises à jour."

# === INFOS SYSTÈME ===
OS_VERSION=$(lsb_release -d 2>/dev/null | cut -f2- | xargs)
if [ -z "$OS_VERSION" ]; then
    OS_VERSION=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2- | tr -d '"')
fi
log "Version du système : $OS_VERSION"

# === MISE À JOUR DU NŒUD PROXMOX ===
log "Mise à jour du nœud Proxmox..."
DEBIAN_FRONTEND=noninteractive apt update -o=Dpkg::Use-Pty=0 && DEBIAN_FRONTEND=noninteractive apt upgrade -y -o=Dpkg::Use-Pty=0 -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" >> "$LOGFILE" 2>&1
log "Mise à jour du nœud terminée."

# === CONTENEURS LXC ===
UPDATED=0
IGNORED=0
SKIPPED=0

for CTID in $(pct list | awk 'NR>1 {print $1}'); do
    if [[ " ${IGNORED_CONTAINERS[@]} " =~ " ${CTID} " ]]; then
        log "Conteneur $CTID ignoré."
        ((IGNORED++))
        continue
    fi

    if pct status "$CTID" | grep -q "running"; then
        log "Mise à jour du conteneur $CTID..."
        pct exec "$CTID" -- bash -c "DEBIAN_FRONTEND=noninteractive apt update -o=Dpkg::Use-Pty=0 && DEBIAN_FRONTEND=noninteractive apt upgrade -y -o=Dpkg::Use-Pty=0 -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"" >> "$LOGFILE" 2>&1
        log "Conteneur $CTID mis à jour."
        IP=$(pct exec "$CTID" -- hostname -I | awk '{print $1}')
        log "IP du conteneur $CTID : $IP"
        ((UPDATED++))
    else
        log "Conteneur $CTID non démarré. Ignoré."
        ((SKIPPED++))
    fi
done

# === MACHINES VIRTUELLES (VMs) ===
VM_UPDATED=0
command -v jq >/dev/null 2>&1 || { log "Installation de jq..."; apt install -y jq >> "$LOGFILE" 2>&1; }
command -v sshpass >/dev/null 2>&1 || { log "Installation de sshpass..."; apt install -y sshpass >> "$LOGFILE" 2>&1; }

for VMID in $(qm list | awk 'NR>1 {print $1}'); do
  log "Tentative de mise à jour de la VM $VMID..."
  IP=$(qm guest cmd $VMID network-get-interfaces 2>/dev/null |     jq -r '.[] | select(.["ip-addresses"] != null) | .["ip-addresses"][] | select(.["ip-address"] != null) | ."ip-address"' |     grep -v ":" | grep -vE '^127|^169|^fe80' | head -n 1)

  if [ -z "$IP" ]; then
    log "Impossible de récupérer l'IP de la VM $VMID. Ignorée."
    continue
  fi

  log "IP de la VM $VMID : $IP"
  if nc -z -w3 $IP $SSH_PORT; then
    log "Connexion SSH possible à $IP. Mise à jour en cours..."
    sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no -p $SSH_PORT $ROOT_USER@$IP       "DEBIAN_FRONTEND=noninteractive apt update -o=Dpkg::Use-Pty=0 && DEBIAN_FRONTEND=noninteractive apt upgrade -y -o=Dpkg::Use-Pty=0 -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"" >> "$LOGFILE" 2>&1
    log "VM $VMID mise à jour via SSH."
    ((VM_UPDATED++))
  else
    log "SSH non disponible sur $IP. VM $VMID ignorée."
  fi
done

# === RÉSUMÉ ===
SUMMARY="Résumé de la mise à jour Proxmox :
- Conteneurs mis à jour : $UPDATED
- Conteneurs ignorés : $IGNORED
- Conteneurs non démarrés : $SKIPPED
- VMs mises à jour : $VM_UPDATED"

log "$SUMMARY"

# === ENVOI EMAIL ===
if command -v mailx >/dev/null 2>&1; then
    MAILX_COMMAND=$(command -v s-nail)
echo "$SUMMARY" | $MAILX_COMMAND -v -s "Rapport de mise à jour Proxmox"         -S smtp="smtp://$SMTP_SERVER:$SMTP_PORT"         -S smtp-use-starttls         -S smtp-auth=login         -S smtp-auth-user="$SMTP_USER"         -S smtp-auth-password="$SMTP_PASS"         -S from="$EMAIL_FROM"         -a "$LOGFILE"         "$EMAIL_TO"
    log "Email envoyé avec le log en pièce jointe."
else
    log "mailx non installé. Email non envoyé."
fi

# === TELEGRAM ===
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage"     -d chat_id="$TELEGRAM_CHAT_ID"     -d text="$(echo "$SUMMARY" | sed 's/\\n/\n/g')"

log "Fin des mises à jour."
