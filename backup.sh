#!/usr/bin/env bash
# Empacota o ESTADO das apps (config/ + .env) num tarball, excluindo lixo
# regenerável (cache/metadados do Jellyfin, logs, clone do trash-guides, WAL do SQLite).
# NÃO inclui a mídia nem os torrents (data/media, data/torrents).
#
# Uso:        ./backup.sh
# Destino:    $BACKUP_DIR (padrão: ./backups). Ex.: BACKUP_DIR=/run/media/voce/HD ./backup.sh
set -euo pipefail
cd "$(dirname "$0")"

BACKUP_DIR="${BACKUP_DIR:-./backups}"
mkdir -p "$BACKUP_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="${BACKUP_DIR%/}/media-server-config-${STAMP}.tar.gz"

echo "==> Gerando backup em: $OUT"
tar \
  --exclude='config/jellyfin/cache' \
  --exclude='config/jellyfin/transcodes' \
  --exclude='config/jellyfin/log' \
  --exclude='config/jellyfin/data/data/subtitles' \
  --exclude='config/jellyfin/data/data/attachments' \
  --exclude='config/jellyfin/data/metadata' \
  --exclude='config/recyclarr/resources' \
  --exclude='config/recyclarr/logs' \
  --exclude='*/logs' \
  --exclude='*.db-wal' \
  --exclude='*.db-shm' \
  --exclude='*/.cache' \
  --exclude='*/ipc-socket' \
  --exclude='*/lockfile' \
  -czf "$OUT" \
  config .env

SIZE="$(du -h "$OUT" | cut -f1)"
echo "==> OK ($SIZE)."

# Mantém apenas os 5 backups locais mais recentes
ls -1t "${BACKUP_DIR%/}"/media-server-config-*.tar.gz 2>/dev/null | tail -n +6 | xargs -r rm -f

# Envio opcional pra nuvem (ex.: Google Drive via rclone).
# Defina RCLONE_REMOTE, ex.:  RCLONE_REMOTE="gdrive:media-server-backups"
if [[ -n "${RCLONE_REMOTE:-}" ]]; then
  if command -v rclone >/dev/null 2>&1; then
    echo "==> Enviando para ${RCLONE_REMOTE} via rclone..."
    rclone copy "$OUT" "$RCLONE_REMOTE" --progress
    # Mantém só os 5 backups mais recentes também no remoto
    mapfile -t REMOTE_OLD < <(rclone lsf "$RCLONE_REMOTE" --include 'media-server-config-*.tar.gz' 2>/dev/null | sort -r | tail -n +6)
    for f in "${REMOTE_OLD[@]:-}"; do
      [[ -n "$f" ]] && rclone deletefile "${RCLONE_REMOTE%/}/$f" 2>/dev/null || true
    done
    echo "==> Upload concluído."
  else
    echo "AVISO: RCLONE_REMOTE definido mas rclone não está instalado; pulei o upload." >&2
  fi
fi

echo "==> Backups locais disponíveis:"
ls -1t "${BACKUP_DIR%/}"/media-server-config-*.tar.gz 2>/dev/null
