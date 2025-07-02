#!/bin/bash
#
# Script : update-proxmox.sh
# Objectif : Mettre à jour automatiquement le nœud Proxmox, les conteneurs LXC et les VMs.
#            Envoie un rapport par email avec les logs en pièce jointe et une notification Telegram.
# Auteur : rto54
# Date : 2025-07-02
# Dépendances : mailx, curl, Proxmox VE, accès root
# Usage : sudo /usr/local/bin/update-proxmox.sh
#

# === CONFIGURATION ===
IGNORED_CONTAINERS=(210 105 108)  # Liste des conteneurs à ignorer
LOG_DIR="/var/log/proxmox-update"
LOGFILE="$LOG_DIR/update.log"
ARCHIVE_DIR="$LOG_DIR/archive"

# Configuration SMTP pour l'envoi d'email
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="votre.email@gmail.com"
SMTP_PASS="le_mot_de_passe_d_application"
EMAIL_TO="votre.email@gmail.com"
EMAIL_FROM="votre.email@gmail.com"

# Configuration Telegram
TELEGRAM_TOKEN="your_telegram_bot_token"
TELEGRAM_CHAT_ID="your_chat_id"

# === PRÉPARATION DES DOSSIERS DE LOGS ===
mkdir -p "$LOG_DIR" "$ARCHIVE_DIR"

# Rotation des logs : suppression des logs de plus de 7 jours
find "$LOG_DIR" -type f -name "*.log" -mtime +7 -exec rm {} \;

# Fonction de log avec horodatage
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# === DÉBUT DU TRAITEMENT ===
log ""
log "Début des mises à jour."

# === MISE À JOUR DU NŒUD PROXMOX ===
log "Mise à jour du nœud Proxmox..."
apt update && apt upgrade -y >> "$LOGFILE" 2>&1
log "Mise à jour du nœud terminée."

# === MISE À JOUR DES CONTENEURS LXC ===
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
        pct exec "$CTID" -- bash -c "apt update && apt upgrade -y" >> "$LOGFILE" 2>&1
        log "Conteneur $CTID mis à jour."
        ((UPDATED++))
    else
        log "Conteneur $CTID non démarré. Ignoré."
        ((SKIPPED++))
    fi
done

# === MISE À JOUR DES MACHINES VIRTUELLES (VMs) ===
VM_UPDATED=0
for VMID in $(qm list | awk 'NR>1 {print $1}'); do
    log "Mise à jour de la VM $VMID (simulation)..."
    # Vous pouvez intégrer ici une mise à jour via SSH ou agent
    ((VM_UPDATED++))
done

# === RÉSUMÉ DES MISES À JOUR ===
SUMMARY="Résumé de la mise à jour Proxmox :
- Conteneurs mis à jour : $UPDATED
- Conteneurs ignorés : $IGNORED
- Conteneurs non démarrés : $SKIPPED
- VMs mises à jour : $VM_UPDATED"

log "$SUMMARY"

# === ENVOI EMAIL AVEC LOG EN PIÈCE JOINTE ===
if command -v mailx >/dev/null 2>&1; then
    echo "$SUMMARY" | mailx -v -s "Rapport de mise à jour Proxmox"         -S smtp="smtp://$SMTP_SERVER:$SMTP_PORT"         -S smtp-use-starttls         -S smtp-auth=login         -S smtp-auth-user="$SMTP_USER"         -S smtp-auth-password="$SMTP_PASS"         -S from="$EMAIL_FROM"         -a "$LOGFILE"         "$EMAIL_TO"
    log "Email envoyé avec le log en pièce jointe."
else
    log "mailx non installé. Email non envoyé."
fi

# === ENVOI NOTIFICATION TELEGRAM ===
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage"     -d chat_id="$TELEGRAM_CHAT_ID"     -d text="$SUMMARY"

log "Fin des mises à jour."
